const request = require('supertest');

jest.mock('../src/config/firebase', () => require('./__mocks__/firebase'));

const { app, server } = require('../src/index');

afterAll(() => server.close());

describe('Families API — auth guard', () => {
  test('POST /api/families without token returns 401', async () => {
    const res = await request(app).post('/api/families').send({ name: 'My Family' });
    expect(res.status).toBe(401);
  });

  test('POST /api/families/join without token returns 401', async () => {
    const res = await request(app).post('/api/families/join').send({ inviteCode: 'ABC123' });
    expect(res.status).toBe(401);
  });

  test('GET /api/families/:id without token returns 401', async () => {
    const res = await request(app).get('/api/families/some-id');
    expect(res.status).toBe(401);
  });

  test('POST /api/families/:id/members without token returns 401', async () => {
    const res = await request(app).post('/api/families/some-id/members').send({ name: 'Bob' });
    expect(res.status).toBe(401);
  });
});

describe('Families API — input validation', () => {
  const { auth } = require('./__mocks__/firebase');

  beforeEach(() => {
    auth.verifyIdToken.mockResolvedValue({ uid: 'user-1' });
  });

  test('POST /api/families with empty name returns 400', async () => {
    const res = await request(app)
      .post('/api/families')
      .set('Authorization', 'Bearer fake-token')
      .send({ name: '' });
    expect(res.status).toBe(400);
    expect(res.body.error).toBeDefined();
  });

  test('POST /api/families/join with empty code returns 400', async () => {
    const res = await request(app)
      .post('/api/families/join')
      .set('Authorization', 'Bearer fake-token')
      .send({ inviteCode: '' });
    expect(res.status).toBe(400);
  });
});
