const request = require('supertest');

jest.mock('../src/config/firebase', () => require('./__mocks__/firebase'));
jest.mock('../src/services/openrouter', () => ({
  generateRecipes: jest.fn().mockResolvedValue([
    {
      name: 'Mock Recipe 1', time_minutes: 30, difficulty: 'easy',
      description: 'Desc', ingredients: [], instructions: [],
    },
    {
      name: 'Mock Recipe 2', time_minutes: 20, difficulty: 'easy',
      description: '', ingredients: [], instructions: [],
    },
    {
      name: 'Mock Recipe 3', time_minutes: 45, difficulty: 'medium',
      description: '', ingredients: [], instructions: [],
    },
    {
      name: 'Mock Recipe 4', time_minutes: 60, difficulty: 'hard',
      description: '', ingredients: [], instructions: [],
    },
  ]),
}));

const { app, server } = require('../src/index');

afterAll(() => server.close());

describe('Recipes API — auth guard', () => {
  test('POST /api/recipes/generate without token returns 401', async () => {
    const res = await request(app).post('/api/recipes/generate').send({ familyId: 'fam-1' });
    expect(res.status).toBe(401);
  });

  test('GET /api/recipes/:familyId without token returns 401', async () => {
    const res = await request(app).get('/api/recipes/fam-1');
    expect(res.status).toBe(401);
  });

  test('DELETE /api/recipes/:familyId/:recipeId without token returns 401', async () => {
    const res = await request(app).delete('/api/recipes/fam-1/recipe-1');
    expect(res.status).toBe(401);
  });
});

describe('Recipes API — input validation', () => {
  const { auth } = require('./__mocks__/firebase');

  beforeEach(() => {
    auth.verifyIdToken.mockResolvedValue({ uid: 'user-1' });
  });

  test('POST /api/recipes/generate without familyId returns 400', async () => {
    const res = await request(app)
      .post('/api/recipes/generate')
      .set('Authorization', 'Bearer fake-token')
      .send({});
    expect(res.status).toBe(400);
    expect(res.body.error).toMatch(/familyId/);
  });
});
