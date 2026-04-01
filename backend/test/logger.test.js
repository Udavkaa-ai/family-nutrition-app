describe('Logger utility', () => {
  const originalEnv = process.env.LOG_LEVEL;

  afterEach(() => {
    process.env.LOG_LEVEL = originalEnv;
    jest.resetModules();
  });

  test('exports error, warn, info, debug functions', () => {
    const logger = require('../src/utils/logger');
    expect(typeof logger.error).toBe('function');
    expect(typeof logger.warn).toBe('function');
    expect(typeof logger.info).toBe('function');
    expect(typeof logger.debug).toBe('function');
  });

  test('does not throw when called', () => {
    const logger = require('../src/utils/logger');
    expect(() => logger.info('test message')).not.toThrow();
    expect(() => logger.error('error message', new Error('test'))).not.toThrow();
    expect(() => logger.warn('warn message')).not.toThrow();
    expect(() => logger.debug('debug message')).not.toThrow();
  });

  test('respects LOG_LEVEL=error — suppresses info', () => {
    process.env.LOG_LEVEL = 'error';
    jest.resetModules();
    const logger = require('../src/utils/logger');
    const spy = jest.spyOn(console, 'log').mockImplementation(() => {});
    logger.info('should not print');
    expect(spy).not.toHaveBeenCalled();
    spy.mockRestore();
  });
});
