const axios = require('axios');
const logger = require('../utils/logger');

const OPENROUTER_URL = 'https://openrouter.ai/api/v1/chat/completions';

/**
 * Build a prompt for recipe generation based on family members and preferences.
 */
const buildPrompt = (familyMembers, cookTime, mealType, pantryItems = [], wishText = '') => {
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

  const wishSection = wishText?.trim()
    ? `\nОсобое пожелание семьи: ${wishText.trim()}`
    : '';

  return `You are a family nutrition advisor. Generate recipe recommendations.

Family members:
${membersText}
${pantryText}${wishSection}
Cooking time: up to ${cookTime} minutes
Meal type: ${mealType}

Provide EXACTLY 4 recipes in valid JSON format. Prioritize using available pantry items and respecting the special request if provided.

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
const generateRecipes = async ({ familyMembers, cookTime, mealType, pantryItems, wishText = '' }) => {
  const model = process.env.OPENROUTER_MODEL || 'google/gemini-3.1-flash-lite-preview';
  const prompt = buildPrompt(familyMembers, cookTime, mealType, pantryItems, wishText);

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

/**
 * Analyze a pantry photo using Gemini Vision and return a list of detected products.
 * @param {string} base64Image - Base64-encoded JPEG image
 * @returns {Promise<Array<{name: string, quantity: number, unit: string}>>}
 */
const analyzePantryPhoto = async (base64Image) => {
  // Use the same model as text generation — gemini-3.1-flash-lite-preview supports vision
  const model = process.env.OPENROUTER_MODEL || 'google/gemini-3.1-flash-lite-preview';

  logger.debug(`Analyzing pantry photo with model: ${model}`);

  const response = await axios.post(
    OPENROUTER_URL,
    {
      model,
      messages: [
        {
          role: 'user',
          content: [
            {
              type: 'image_url',
              image_url: { url: `data:image/jpeg;base64,${base64Image}` },
            },
            {
              type: 'text',
              text: 'Определи все продукты питания на этом фото (кладовая, холодильник, полка с едой). Верни ТОЛЬКО валидный JSON массив объектов с полями: name (название по-русски), quantity (число), unit (единица: г, кг, мл, л, шт, уп, пач). Пример: [{"name":"Молоко","quantity":1,"unit":"л"},{"name":"Яйца","quantity":6,"unit":"шт"},{"name":"Масло сливочное","quantity":200,"unit":"г"}]. Только JSON массив, без пояснений.',
            },
          ],
        },
      ],
      max_tokens: 1000,
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
  if (!content) throw new Error('Empty response from AI vision');

  const match = content.match(/\[[\s\S]*\]/);
  if (!match) throw new Error('No JSON array found in vision response');

  const products = JSON.parse(match[0]);
  if (!Array.isArray(products)) throw new Error('Invalid products format');

  return products;
};

module.exports = { generateRecipes, analyzePantryPhoto };
