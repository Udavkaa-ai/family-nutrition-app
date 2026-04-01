const axios = require('axios');
const logger = require('../utils/logger');

const OPENROUTER_URL = 'https://openrouter.ai/api/v1/chat/completions';

/**
 * Build a prompt for recipe generation based on family members and preferences.
 */
const buildPrompt = (familyMembers, cookTime, mealType, pantryItems = []) => {
  const membersText = familyMembers.length > 0
    ? familyMembers.map((m) => {
        const parts = [];
        if (m.dietaryPreferences?.length) parts.push(m.dietaryPreferences.join(', '));
        if (m.dislikedIngredients?.length) parts.push(`не любит: ${m.dislikedIngredients.join(', ')}`);
        return `${m.name} (${parts.join('; ') || 'без ограничений'})`;
      }).join('\n')
    : 'Семья без особых предпочтений';

  const pantryText = pantryItems.length > 0
    ? `\nПродукты в кладовой: ${pantryItems.map((i) => `${i.name} (${i.quantity} ${i.unit})`).join(', ')}`
    : '';

  return `You are a family nutrition advisor. Generate recipe recommendations.

Family members:
${membersText}
${pantryText}
Cooking time: up to ${cookTime} minutes
Meal type: ${mealType}

Provide EXACTLY 4 recipes in valid JSON format. Prioritize using available pantry items.

[
  {
    "name": "Recipe Name",
    "time_minutes": 30,
    "difficulty": "easy",
    "description": "Brief appetizing description",
    "ingredients": [
      {"name": "ingredient", "quantity": 250, "unit": "g"}
    ],
    "instructions": ["Step 1", "Step 2", "Step 3"]
  }
]

difficulty must be one of: easy, medium, hard
Return ONLY valid JSON array, no additional text.`;
};

/**
 * Parse JSON array from AI response text.
 */
const parseRecipes = (text) => {
  const match = text.match(/\[[\s\S]*\]/);
  if (!match) throw new Error('No JSON array found in AI response');

  const recipes = JSON.parse(match[0]);
  if (!Array.isArray(recipes) || recipes.length === 0) {
    throw new Error('Invalid recipes format');
  }
  return recipes;
};

/**
 * Call OpenRouter API and return parsed recipes array.
 */
const generateRecipes = async ({ familyMembers, cookTime, mealType, pantryItems }) => {
  const model = process.env.OPENROUTER_MODEL || 'google/gemini-3-flash-preview';
  const prompt = buildPrompt(familyMembers, cookTime, mealType, pantryItems);

  logger.debug(`Calling OpenRouter model: ${model}`);

  const response = await axios.post(
    OPENROUTER_URL,
    {
      model,
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.7,
      max_tokens: 3000,
    },
    {
      headers: {
        Authorization: `Bearer ${process.env.OPENROUTER_API_KEY}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': process.env.FRONTEND_URL || 'http://localhost:5000',
        'X-Title': 'Family Nutrition Advisor',
      },
      timeout: 30000,
    }
  );

  const content = response.data.choices?.[0]?.message?.content;
  if (!content) throw new Error('Empty response from OpenRouter');

  return parseRecipes(content);
};

module.exports = { generateRecipes };
