const { Router } = require('express');
const axios = require('axios');
const { auth } = require('../config/firebase');
const logger = require('../utils/logger');

const router = Router();

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

// ── GET /api/spoonacular/search?query=pasta&number=10 ─────────────────────────
router.get('/search', authenticate, async (req, res, next) => {
  try {
    const { query = '', number = 10 } = req.query;
    const apiKey = process.env.SPOONACULAR_API_KEY;

    if (!apiKey) {
      return res.status(503).json({ error: 'Spoonacular API not configured' });
    }

    const response = await axios.get('https://api.spoonacular.com/recipes/complexSearch', {
      params: {
        query: query || 'healthy dinner',
        number: Math.min(parseInt(number) || 10, 20),
        apiKey,
        addRecipeInformation: true,
        instructionsRequired: true,
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

    res.json({ recipes, total: response.data.totalResults || 0 });
  } catch (err) {
    logger.error('Spoonacular error:', err.message);
    if (err.response?.status === 402) {
      return res.status(402).json({ error: 'Spoonacular API quota exceeded' });
    }
    next(err);
  }
});

module.exports = router;
