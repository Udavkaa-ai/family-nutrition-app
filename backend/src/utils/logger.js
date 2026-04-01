const LOG_LEVEL = process.env.LOG_LEVEL || 'info';

const levels = { error: 0, warn: 1, info: 2, debug: 3 };
const current = levels[LOG_LEVEL] ?? levels.info;

const timestamp = () => new Date().toISOString();

const logger = {
  error: (msg, ...args) => {
    if (current >= levels.error) console.error(`[${timestamp()}] ERROR: ${msg}`, ...args);
  },
  warn: (msg, ...args) => {
    if (current >= levels.warn) console.warn(`[${timestamp()}] WARN:  ${msg}`, ...args);
  },
  info: (msg, ...args) => {
    if (current >= levels.info) console.log(`[${timestamp()}] INFO:  ${msg}`, ...args);
  },
  debug: (msg, ...args) => {
    if (current >= levels.debug) console.log(`[${timestamp()}] DEBUG: ${msg}`, ...args);
  },
};

module.exports = logger;
