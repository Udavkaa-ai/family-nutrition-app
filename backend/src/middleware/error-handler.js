const logger = require('../utils/logger');

// 404 handler — must be registered after all routes
const notFound = (req, res, next) => {
  res.status(404).json({ error: `Not Found: ${req.method} ${req.originalUrl}` });
};

// Global error handler — must be registered last (4 args)
// eslint-disable-next-line no-unused-vars
const errorHandler = (err, req, res, next) => {
  logger.error(err.message, err.stack);

  const status = err.status || err.statusCode || 500;
  const message = process.env.NODE_ENV === 'production' ? 'Internal Server Error' : err.message;

  res.status(status).json({ error: message });
};

module.exports = { notFound, errorHandler };
