const request = require('supertest');

jest.mock('../src/config/firebase', () => require('./__mocks__/firebase'));

const { app, server } = require('../src/index');

afterAll(() => server.close());

describe('Shopping Lists API — auth guard', () => {
  test('POST /api/shopping-lists without token returns 401', async () => {
    const res = await request(app).post('/api/shopping-lists').send({ familyId: 'fam-1' });
    expect(res.status).toBe(401);
  });

  test('GET /api/shopping-lists/:familyId without token returns 401', async () => {
    const res = await request(app).get('/api/shopping-lists/fam-1');
    expect(res.status).toBe(401);
  });

  test('DELETE /api/shopping-lists/:listId without token returns 401', async () => {
    const res = await request(app).delete('/api/shopping-lists/list-1');
    expect(res.status).toBe(401);
  });
});

describe('Shopping Lists API — input validation', () => {
  const { auth } = require('./__mocks__/firebase');

  beforeEach(() => {
    auth.verifyIdToken.mockResolvedValue({ uid: 'user-1' });
  });

  test('POST /api/shopping-lists without familyId returns 400', async () => {
    const res = await request(app)
      .post('/api/shopping-lists')
      .set('Authorization', 'Bearer fake-token')
      .send({});
    expect(res.status).toBe(400);
    expect(res.body.error).toBeDefined();
  });
});
