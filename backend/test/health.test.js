const request = require('supertest');

// Mock firebase before importing app
jest.mock('../src/config/firebase', () => ({
  admin: {},
  db: null,
  auth: null,
}));

const { app, server } = require('../src/index');

afterAll(() => server.close());

describe('System endpoints', () => {
  test('GET /health returns 200 with status OK', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('OK');
    expect(res.body.timestamp).toBeDefined();
  });

  test('GET /api/status returns version and env', async () => {
    const res = await request(app).get('/api/status');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('OK');
    expect(res.body.env).toBeDefined();
  });

  test('GET /nonexistent returns 404', async () => {
    const res = await request(app).get('/nonexistent');
    expect(res.status).toBe(404);
    expect(res.body.error).toBeDefined();
  });
});
