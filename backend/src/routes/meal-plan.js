const { Router } = require('express');
const axios = require('axios');
const { db, auth } = require('../config/firebase');
const logger = require('../utils/logger');

const router = Router();
const OPENROUTER_URL = 'https://openrouter.ai/api/v1/chat/completions';

const authenticate = async (req, res, next) => {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) return res.status(401).json({ error: 'Unauthorized' });
  try {
    const decoded = await auth.verifyIdToken(header.split(' ')[1]);
    req.uid = decoded.uid;
    next();
  } catch {
    res.status(401).json({ error: 'Invalid token' });
  }
};

const buildPrompt = ({ membersText, days, budgetRub, maxCookMinutes, mode }) => {
  const dayWord = days === 1 ? 'день' : days < 5 ? 'дня' : 'дней';
  const modeNote = mode === 'quick'
    ? 'Режим: максимально быстро и просто. Разрешены полуготовые продукты, минимум готовки.'
    : 'Режим: обычное приготовление, простые домашние рецепты.';

  return `Ты нутрициолог и семейный планировщик питания.

Семья: ${membersText}
Период: ${days} ${dayWord}
Бюджет: ${budgetRub} ₽ на весь период
Время на готовку: до ${maxCookMinutes} минут в день
${modeNote}

Правила:
— простые блюда, ничего экзотического
— повторно используй ингредиенты (купил курицу → суп + второе + салат)
— уложись в бюджет ${budgetRub} ₽
— обычная плита/духовка, стандартная кухня

Верни ТОЛЬКО валидный JSON без комментариев:
{
  "plan": [
    {
      "day": 1,
      "breakfast": { "name": "Название", "time_minutes": 10, "note": "краткое описание" },
      "lunch": { "name": "Название", "time_minutes": 20, "note": "краткое описание" },
      "dinner": { "name": "Название", "time_minutes": 35, "note": "краткое описание" }
    }
  ],
  "shopping_list": [
    {
      "category": "Мясо и птица",
      "items": [
        { "name": "Куриное филе", "quantity": "1 кг", "price_approx": 280 }
      ]
    }
  ],
  "total_estimated_cost": 3200,
  "cooking_tips": ["Совет 1", "Совет 2", "Совет 3"]
}`;
};

// ── POST /api/meal-plan/generate ──────────────────────────────────────────────
router.post('/generate', authenticate, async (req, res, next) => {
  try {
    const {
      familyId,
      days = 7,
      budgetRub,
      maxCookMinutes = 40,
      mode = 'normal',
    } = req.body;

    if (!familyId) return res.status(400).json({ error: 'familyId is required' });
    if (!budgetRub || Number(budgetRub) <= 0) {
      return res.status(400).json({ error: 'budgetRub is required' });
    }

    // Fetch family members for personalisation
    const membersSnap = await db
      .collection('family_members')
      .where('familyId', '==', familyId)
      .get();
    const members = membersSnap.docs.map((d) => d.data());

    const membersText = members.length > 0
      ? members.map((m) => {
          const parts = [];
          if (m.dietaryPreferences?.length) parts.push(m.dietaryPreferences.join(', '));
          if (m.dislikedIngredients?.length) parts.push(`не любит: ${m.dislikedIngredients.join(', ')}`);
          return `${m.name} (${parts.join('; ') || 'без ограничений'})`;
        }).join(', ')
      : `${members.length || 1} человек, без особых предпочтений`;

    const prompt = buildPrompt({
      membersText,
      days: Math.min(Math.max(parseInt(days, 10) || 7, 1), 7),
      budgetRub: parseInt(budgetRub, 10),
      maxCookMinutes: parseInt(maxCookMinutes, 10),
      mode,
    });

    const model = process.env.OPENROUTER_MODEL || 'google/gemini-3.1-flash-lite-preview';
    logger.debug(`Meal plan: ${days} days, ${budgetRub}₽, model: ${model}`);

    const response = await axios.post(
      OPENROUTER_URL,
      {
        model,
        messages: [{ role: 'user', content: prompt }],
        temperature: 0.5,
        max_tokens: 4000,
      },
      {
        headers: {
          Authorization: `Bearer ${process.env.OPENROUTER_API_KEY}`,
          'Content-Type': 'application/json',
          'HTTP-Referer': process.env.FRONTEND_URL || 'http://localhost:5000',
          'X-Title': 'Family Nutrition Advisor',
        },
        timeout: 60000,
      }
    );

    const content = response.data.choices?.[0]?.message?.content;
    if (!content) throw new Error('Empty response from AI');

    const match = content.match(/\{[\s\S]*\}/);
    if (!match) throw new Error('No JSON in AI response');

    const plan = JSON.parse(match[0]);
    logger.info(`Meal plan generated: ${plan.plan?.length} days, ~${plan.total_estimated_cost}₽`);
    res.json(plan);
  } catch (err) {
    logger.error('Meal plan error:', err.message);
    next(err);
  }
});

module.exports = router;
