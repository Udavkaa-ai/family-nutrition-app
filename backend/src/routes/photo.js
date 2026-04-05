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

// Translate Cyrillic to English using OpenRouter (reuse existing model)
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

// ── GET /api/photo/search?query=DISH_NAME ─────────────────────────────────────
// Returns { url: "https://..." } or { url: null }
// Pexels: free, 20 000 req/month, no watermarks
// Register at https://www.pexels.com/api/ → get your key → add PEXELS_API_KEY to Railway
router.get('/search', authenticate, async (req, res, next) => {
  try {
    const rawQuery = (req.query.query || '').trim();
    if (!rawQuery) return res.status(400).json({ error: 'query is required' });

    const apiKey = process.env.PEXELS_API_KEY;
    if (!apiKey) return res.status(503).json({ error: 'Photo search not configured (add PEXELS_API_KEY)' });

    // Translate if Cyrillic
    let query = rawQuery;
    if (hasCyrillic(query)) {
      query = await translateToEnglish(rawQuery);
      logger.debug(`Photo search: "${rawQuery}" → "${query}"`);
    }

    const cacheKey = `photo:${query.toLowerCase()}`;
    const cached = getCached(cacheKey);
    if (cached) return res.json(cached);

    const response = await axios.get('https://api.pexels.com/v1/search', {
      params: { query, per_page: 3, orientation: 'landscape' },
      headers: { Authorization: apiKey },
      timeout: 8000,
    });

    const photos = response.data.photos || [];
    const result = photos.length > 0
      ? { url: photos[0].src.large, photographer: photos[0].photographer }
      : { url: null };

    setCached(cacheKey, result);
    logger.info(`Photo search: "${query}" → ${result.url ? 'found' : 'not found'}`);
    res.json(result);
  } catch (err) {
    logger.error('Photo search error:', err.message);
    next(err);
  }
});

module.exports = router;
