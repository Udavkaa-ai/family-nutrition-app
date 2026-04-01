const request = require('supertest');

jest.mock('../src/config/firebase', () => require('./__mocks__/firebase'));

const { app, server } = require('../src/index');

afterAll(() => server.close());

describe('Pantry API — auth guard', () => {
  test('GET /api/pantry/:familyId without token returns 401', async () => {
    const res = await request(app).get('/api/pantry/family-1');
    expect(res.status).toBe(401);
  });

  test('POST /api/pantry/:familyId/items without token returns 401', async () => {
    const res = await request(app)
      .post('/api/pantry/family-1/items')
      .send({ name: 'Milk', quantity: 1, unit: 'л' });
    expect(res.status).toBe(401);
  });

  test('DELETE /api/pantry/:familyId/items/:itemId without token returns 401', async () => {
    const res = await request(app).delete('/api/pantry/family-1/items/item-1');
    expect(res.status).toBe(401);
  });
});

describe('Pantry API — input validation', () => {
  const { auth } = require('./__mocks__/firebase');

  beforeEach(() => {
    auth.verifyIdToken.mockResolvedValue({ uid: 'user-1' });
  });

  test('POST /api/pantry/:familyId/items with empty name returns 400', async () => {
    const res = await request(app)
      .post('/api/pantry/family-1/items')
      .set('Authorization', 'Bearer fake-token')
      .send({ name: '', quantity: 1 });
    expect(res.status).toBe(400);
    expect(res.body.error).toBeDefined();
  });
});
