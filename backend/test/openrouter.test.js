const { generateRecipes } = require('../src/services/openrouter');
const axios = require('axios');

jest.mock('axios');

describe('OpenRouter service', () => {
  const mockRecipes = [
    {
      name: 'Test Recipe',
      time_minutes: 30,
      difficulty: 'easy',
      description: 'A test recipe',
      ingredients: [{ name: 'flour', quantity: 200, unit: 'g' }],
      instructions: ['Step 1', 'Step 2'],
    },
    {
      name: 'Recipe 2', time_minutes: 20, difficulty: 'easy',
      description: '', ingredients: [], instructions: [],
    },
    {
      name: 'Recipe 3', time_minutes: 45, difficulty: 'medium',
      description: '', ingredients: [], instructions: [],
    },
    {
      name: 'Recipe 4', time_minutes: 60, difficulty: 'hard',
      description: '', ingredients: [], instructions: [],
    },
  ];

  beforeEach(() => {
    process.env.OPENROUTER_API_KEY = 'test-key';
    process.env.OPENROUTER_MODEL = 'test-model';
  });

  test('parses valid JSON response from OpenRouter', async () => {
    axios.post.mockResolvedValueOnce({
      data: {
        choices: [{ message: { content: JSON.stringify(mockRecipes) } }],
      },
    });

    const result = await generateRecipes({
      familyMembers: [{ name: 'Alice', dietaryPreferences: ['Вегетарианец'] }],
      cookTime: 30,
      mealType: 'dinner',
      pantryItems: [],
    });

    expect(Array.isArray(result)).toBe(true);
    expect(result).toHaveLength(4);
    expect(result[0].name).toBe('Test Recipe');
  });

  test('extracts JSON embedded in surrounding text', async () => {
    const content = `Here are the recipes:\n${JSON.stringify(mockRecipes)}\nEnjoy!`;
    axios.post.mockResolvedValueOnce({
      data: { choices: [{ message: { content } }] },
    });

    const result = await generateRecipes({
      familyMembers: [],
      cookTime: 30,
      mealType: 'lunch',
      pantryItems: [],
    });

    expect(result).toHaveLength(4);
  });

  test('throws when response has no JSON array', async () => {
    axios.post.mockResolvedValueOnce({
      data: { choices: [{ message: { content: 'Sorry, I cannot help.' } }] },
    });

    await expect(
      generateRecipes({ familyMembers: [], cookTime: 30, mealType: 'dinner', pantryItems: [] })
    ).rejects.toThrow('No JSON array found');
  });

  test('throws when axios call fails', async () => {
    axios.post.mockRejectedValueOnce(new Error('Network error'));

    await expect(
      generateRecipes({ familyMembers: [], cookTime: 30, mealType: 'dinner', pantryItems: [] })
    ).rejects.toThrow('Network error');
  });
});
