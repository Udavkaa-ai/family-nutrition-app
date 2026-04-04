const { Router } = require('express');
const axios = require('axios');
const { auth } = require('../config/firebase');
const logger = require('../utils/logger');

const router = Router();

// ── In-memory cache to avoid burning free-tier points on repeated queries ─────
// Key: "query:number" → { recipes, total, cachedAt }
const cache = new Map();
const CACHE_TTL_MS = 60 * 60 * 1000; // 1 hour

const getCached = (key) => {
  const entry = cache.get(key);
  if (!entry) return null;
  if (Date.now() - entry.cachedAt > CACHE_TTL_MS) {
    cache.delete(key);
    return null;
  }
  return entry;
};

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

// ── GET /api/spoonacular/search?query=pasta&number=5 ──────────────────────────
// Free tier: 50 points/day. complexSearch + addRecipeInformation costs 1+N points
// (1 for the search + 1 per recipe). Defaulting to 5 results = 6 points/search
// → ~8 unique searches/day, cached results are free.
router.get('/search', authenticate, async (req, res, next) => {
  try {
    const rawQuery = (req.query.query || '').trim();
    // Cap at 5 to stay within free-tier budget (6 points/call)
    const number = Math.min(Math.max(parseInt(req.query.number) || 5, 1), 5);
    const query = rawQuery || 'healthy dinner';

    const apiKey = process.env.SPOONACULAR_API_KEY;
    if (!apiKey) {
      return res.status(503).json({ error: 'Spoonacular API not configured' });
    }

    // Return cached result if available
    const cacheKey = `${query.toLowerCase()}:${number}`;
    const cached = getCached(cacheKey);
    if (cached) {
      logger.debug(`Spoonacular cache hit: "${query}"`);
      return res.json({ recipes: cached.recipes, total: cached.total, cached: true });
    }

    const response = await axios.get('https://api.spoonacular.com/recipes/complexSearch', {
      params: {
        query,
        number,
        apiKey,
        addRecipeInformation: true,
        instructionsRequired: false, // saves a tiny bit of processing
        addRecipeNutrition: false,
      },
      timeout: 10000,
    });

    const recipes = (response.data.results || []).map((r) => ({
      id: r.id,
      title: r.title,
      image: r.image || '',
      readyInMinutes: r.readyInMinutes || 0,
      servings: r.servings || 0,
      summary: r.summary ? r.summary.replace(/<[^>]*>/g, '').slice(0, 400) : '',
      sourceUrl: r.sourceUrl || '',
    }));

    const total = response.data.totalResults || 0;

    // Store in cache
    cache.set(cacheKey, { recipes, total, cachedAt: Date.now() });

    logger.info(`Spoonacular search: "${query}" → ${recipes.length} results`);
    res.json({ recipes, total, cached: false });
  } catch (err) {
    logger.error('Spoonacular error:', err.message);
    if (err.response?.status === 402) {
      return res.status(402).json({ error: 'Дневной лимит Spoonacular исчерпан. Попробуйте завтра.' });
    }
    next(err);
  }
});

module.exports = router;
