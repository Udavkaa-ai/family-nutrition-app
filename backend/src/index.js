require('dotenv').config();

// Firebase must be initialized before any route that uses db/auth
require('./config/firebase');

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const familyRoutes = require('./routes/families');
const pantryRoutes = require('./routes/pantry');
const recipeRoutes = require('./routes/recipes');
const shoppingListRoutes = require('./routes/shopping-lists');
const spoonacularRoutes = require('./routes/spoonacular');
const { notFound, errorHandler } = require('./middleware/error-handler');
const logger = require('./utils/logger');

const app = express();

// ── Security & utility middleware ─────────────────────────────────────────────
app.use(helmet());
app.use(cors({ origin: process.env.FRONTEND_URL || '*' }));
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));

// ── System endpoints ──────────────────────────────────────────────────────────
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

app.get('/api/status', (req, res) => {
  const { auth } = require('./config/firebase');
  res.json({
    status: 'OK',
    version: process.env.npm_package_version || '0.1.0',
    env: process.env.NODE_ENV || 'development',
    firebase: auth ? 'ready' : 'not initialized',
  });
});

// ── API routes ────────────────────────────────────────────────────────────────
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/families', familyRoutes);
app.use('/api/pantry', pantryRoutes);
app.use('/api/recipes', recipeRoutes);
app.use('/api/shopping-lists', shoppingListRoutes);
app.use('/api/spoonacular', spoonacularRoutes);

// ── Error handling (must be last) ─────────────────────────────────────────────
app.use(notFound);
app.use(errorHandler);

// ── Start server ──────────────────────────────────────────────────────────────
const PORT = parseInt(process.env.PORT || '3000', 10);

const server = app.listen(PORT, () => {
  logger.info(`Server running on http://localhost:${PORT} (${process.env.NODE_ENV || 'development'})`);
});

module.exports = { app, server };
