const { Router } = require('express');
const axios = require('axios');
const { auth } = require('../config/firebase');
const logger = require('../utils/logger');

// Translate Cyrillic recipe name to English for Spoonacular search
const hasCyrillic = (str) => /[\u0400-\u04FF]/.test(str);

const translateToEnglish = async (text) => {
  const apiKey = process.env.OPENROUTER_API_KEY;
  if (!apiKey) return text;
  try {
    const r = await axios.post(
      'https://openrouter.ai/api/v1/chat/completions',
      {
        model: process.env.OPENROUTER_MODEL || 'google/gemini-3.1-flash-lite-preview',
        messages: [{
          role: 'user',
          content: `Translate to English for recipe search. Reply with just the translation, nothing else: ${text}`,
        }],
        max_tokens: 60,
        temperature: 0,
      },
      {
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        timeout: 6000,
      }
    );
    return r.data.choices?.[0]?.message?.content?.trim() || text;
  } catch {
    return text; // fall back to original on any error
  }
};

const router = Router();

// ── In-memory cache (1 hour TTL) to avoid burning free-tier points ─────────────
const cache = new Map();
const CACHE_TTL_MS = 60 * 60 * 1000;

const getCached = (key) => {
  const entry = cache.get(key);
  if (!entry) return null;
  if (Date.now() - entry.cachedAt > CACHE_TTL_MS) {
    cache.delete(key);
    return null;
  }
  return entry.data;
};

const setCached = (key, data) => cache.set(key, { data, cachedAt: Date.now() });

const authenticate = async (req, res, next) => {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing authorization header' });
  }
  try {
    const decoded = await auth.verifyIdToken(header.split(' ')[1]);
    req.uid = decoded.uid;
    next();
  } catch {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
};

const spoonacularHeaders = (apiKey) => ({
  params: { apiKey },
  timeout: 10000,
});

// ── GET /api/spoonacular/search?query=pasta ───────────────────────────────────
// Cost: 1 point per search (no addRecipeInformation).
// Returns only id + title — no photos, no extra fields.
// Photos are fetched separately when user selects a recipe.
router.get('/search', authenticate, async (req, res, next) => {
  try {
    const rawQuery = (req.query.query || '').trim();
    const number = Math.min(Math.max(parseInt(req.query.number, 10) || 8, 1), 10);

    // Translate Cyrillic queries to English for Spoonacular (English-only database)
    let query = rawQuery || 'healthy dinner';
    if (hasCyrillic(query)) {
      const translated = await translateToEnglish(query);
      logger.debug(`Spoonacular: translated "${query}" → "${translated}"`);
      query = translated || query;
    }

    const apiKey = process.env.SPOONACULAR_API_KEY;
    if (!apiKey) {
      return res.status(503).json({ error: 'Spoonacular API not configured' });
    }

    const cacheKey = `search:${query.toLowerCase()}:${number}`;
    const cached = getCached(cacheKey);
    if (cached) {
      logger.debug(`Spoonacular cache hit (search): "${query}"`);
      return res.json({ ...cached, cached: true });
    }

    const response = await axios.get(
      'https://api.spoonacular.com/recipes/complexSearch',
      {
        params: {
          query,
          number,
          apiKey,
          // No addRecipeInformation → costs only 1 point for the whole search
        },
        timeout: 10000,
      }
    );

    const recipes = (response.data.results || []).map((r) => ({
      id: r.id,
      title: r.title,
      // image URL is included in basic search for free — but we won't show it
      // in the list; it will be used only when user opens the detail sheet.
      image: r.image || '',
    }));

    const payload = { recipes, total: response.data.totalResults || 0 };
    setCached(cacheKey, payload);

    logger.info(`Spoonacular search: "${query}" → ${recipes.length} results (1 point)`);
    res.json({ ...payload, cached: false });
  } catch (err) {
    logger.error('Spoonacular search error:', err.message);
    if (err.response?.status === 402) {
      return res.status(402).json({ error: 'Дневной лимит Spoonacular исчерпан. Попробуйте завтра.' });
    }
    next(err);
  }
});

// ── GET /api/spoonacular/recipe/:id ──────────────────────────────────────────
// Cost: 1 point per call (only charged when user taps a recipe).
// Returns full details: photo, readyInMinutes, servings, summary.
router.get('/recipe/:id', authenticate, async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!id || isNaN(parseInt(id, 10))) {
      return res.status(400).json({ error: 'Invalid recipe id' });
    }

    const apiKey = process.env.SPOONACULAR_API_KEY;
    if (!apiKey) {
      return res.status(503).json({ error: 'Spoonacular API not configured' });
    }

    const cacheKey = `recipe:${id}`;
    const cached = getCached(cacheKey);
    if (cached) {
      logger.debug(`Spoonacular cache hit (recipe): ${id}`);
      return res.json({ ...cached, cached: true });
    }

    const response = await axios.get(
      `https://api.spoonacular.com/recipes/${id}/information`,
      {
        params: { apiKey, includeNutrition: false },
        timeout: 10000,
      }
    );

    const r = response.data;
    const detail = {
      id: r.id,
      title: r.title,
      image: r.image || '',
      readyInMinutes: r.readyInMinutes || 0,
      servings: r.servings || 0,
      summary: r.summary ? r.summary.replace(/<[^>]*>/g, '').slice(0, 500) : '',
      sourceUrl: r.sourceUrl || '',
    };

    setCached(cacheKey, detail);

    logger.info(`Spoonacular recipe detail: ${id} "${r.title}" (1 point)`);
    res.json({ ...detail, cached: false });
  } catch (err) {
    logger.error('Spoonacular detail error:', err.message);
    if (err.response?.status === 402) {
      return res.status(402).json({ error: 'Дневной лимит Spoonacular исчерпан. Попробуйте завтра.' });
    }
    if (err.response?.status === 404) {
      return res.status(404).json({ error: 'Рецепт не найден' });
    }
    next(err);
  }
});

module.exports = router;
