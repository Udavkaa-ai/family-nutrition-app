const { Router } = require('express');
const axios = require('axios');
const { auth } = require('../config/firebase');
const logger = require('../utils/logger');

const router = Router();

// Simple 1-hour cache
const cache = new Map();
const CACHE_TTL_MS = 60 * 60 * 1000;
const getCached = (k) => {
  const e = cache.get(k);
  if (!e || Date.now() - e.t > CACHE_TTL_MS) { cache.delete(k); return null; }
  return e.v;
};
const setCached = (k, v) => cache.set(k, { v, t: Date.now() });

const authenticate = async (req, res, next) => {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) return res.status(401).json({ error: 'Unauthorized' });
  try {
    const decoded = await auth.verifyIdToken(header.split(' ')[1]);
    req.uid = decoded.uid;
    next();
  } catch {
    res.status(401).json({ error: 'Invalid token' });
  }
};

// Translate Russian → English using existing OpenRouter/Gemini
const hasCyrillic = (str) => /[\u0400-\u04FF]/.test(str);
const translateToEnglish = async (text) => {
  const apiKey = process.env.OPENROUTER_API_KEY;
  if (!apiKey) return text;
  try {
    const r = await axios.post(
      'https://openrouter.ai/api/v1/chat/completions',
      {
        model: process.env.OPENROUTER_MODEL || 'google/gemini-3.1-flash-lite-preview',
        messages: [{ role: 'user', content: `Translate to English for image search (just the translation, nothing else): ${text}` }],
        max_tokens: 60,
        temperature: 0,
      },
      {
        headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
        timeout: 6000,
      }
    );
    return r.data.choices?.[0]?.message?.content?.trim() || text;
  } catch {
    return text;
  }
};

// Source 1: TheMealDB — free, no API key, 300+ international meals with photos
const searchTheMealDB = async (query) => {
  try {
    const r = await axios.get('https://www.themealdb.com/api/json/v1/1/search.php', {
      params: { s: query },
      timeout: 6000,
    });
    return r.data.meals?.[0]?.strMealThumb || null;
  } catch {
    return null;
  }
};

// Source 2: Wikipedia REST API — free, no key, returns article thumbnail
// Works for any well-known dish that has a Wikipedia article
const searchWikipedia = async (query) => {
  try {
    const title = query.trim().replace(/\s+/g, '_');
    const r = await axios.get(
      `https://en.wikipedia.org/api/rest_v1/page/summary/${encodeURIComponent(title)}`,
      { timeout: 6000 }
    );
    // Prefer the article thumbnail, fall back to original image
    return r.data.thumbnail?.source || r.data.originalimage?.source || null;
  } catch {
    return null;
  }
};

// ── GET /api/photo/search?query=DISH_NAME ─────────────────────────────────────
// No external API key required. Completely free.
// Flow: translate (if Russian) → TheMealDB → Wikipedia → null
router.get('/search', authenticate, async (req, res, next) => {
  try {
    const rawQuery = (req.query.query || '').trim();
    if (!rawQuery) return res.status(400).json({ error: 'query is required' });

    const cacheKey = `photo:${rawQuery.toLowerCase()}`;
    const cached = getCached(cacheKey);
    if (cached) return res.json(cached);

    // Translate Russian → English
    let query = rawQuery;
    if (hasCyrillic(query)) {
      query = await translateToEnglish(rawQuery);
      logger.debug(`Photo search: "${rawQuery}" → "${query}"`);
    }

    // 1) TheMealDB — best for well-known dishes
    let url = await searchTheMealDB(query);

    // 2) TheMealDB with just the first keyword (e.g. "chicken" from "chicken with mushrooms")
    if (!url && query.includes(' ')) {
      url = await searchTheMealDB(query.split(' ')[0]);
    }

    // 3) Wikipedia thumbnail — broader coverage
    if (!url) {
      url = await searchWikipedia(query);
    }

    const result = { url: url || null };
    setCached(cacheKey, result);

    logger.info(`Photo search "${rawQuery}": ${url ? 'found' : 'not found'}`);
    res.json(result);
  } catch (err) {
    logger.error('Photo search error:', err.message);
    next(err);
  }
});

module.exports = router;
