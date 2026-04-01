const { Router } = require('express');
const { db, auth } = require('../config/firebase');
const { generateRecipes } = require('../services/openrouter');
const logger = require('../utils/logger');

const router = Router();

// ── Auth middleware ────────────────────────────────────────────────────────────
const authenticate = async (req, res, next) => {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing authorization header' });
  }
  try {
    const decoded = await auth.verifyIdToken(header.split(' ')[1]);
    req.uid = decoded.uid;
    next();
  } catch {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
};

const assertFamilyMember = async (uid, familyId) => {
  const doc = await db.collection('families').doc(familyId).get();
  if (!doc.exists || !doc.data()?.members?.[uid]) {
    throw Object.assign(new Error('Not a member of this family'), { status: 403 });
  }
};

// ── POST /api/recipes/generate — generate via AI ──────────────────────────────
router.post('/generate', authenticate, async (req, res, next) => {
  try {
    const { familyId, cookTime = 30, mealType = 'dinner' } = req.body;
    if (!familyId) return res.status(400).json({ error: 'familyId is required' });

    await assertFamilyMember(req.uid, familyId);

    // Fetch family members
    const membersSnap = await db
      .collection('family_members')
      .where('familyId', '==', familyId)
      .get();
    const familyMembers = membersSnap.docs.map((d) => d.data());

    // Fetch pantry items
    const pantrySnap = await db
      .collection('pantry')
      .where('familyId', '==', familyId)
      .limit(1)
      .get();
    const pantryItems = pantrySnap.empty
      ? []
      : Object.values(pantrySnap.docs[0].data()?.items ?? {});

    // Call OpenRouter
    const recipes = await generateRecipes({ familyMembers, cookTime, mealType, pantryItems });

    // Save generated recipes to Firestore
    const batch = db.batch();
    const savedRecipes = recipes.map((recipe) => {
      const ref = db.collection('recipes').doc();
      const data = {
        familyId,
        name: recipe.name,
        timeMinutes: recipe.time_minutes,
        difficulty: recipe.difficulty,
        description: recipe.description ?? '',
        ingredients: recipe.ingredients ?? [],
        instructions: recipe.instructions ?? [],
        source: 'ai',
        createdAt: new Date(),
      };
      batch.set(ref, data);
      return { id: ref.id, ...data };
    });

    await batch.commit();

    logger.info(`Generated ${savedRecipes.length} recipes for family ${familyId}`);
    res.json(savedRecipes);
  } catch (err) {
    next(err);
  }
});

// ── GET /api/recipes/:familyId — list saved recipes ──────────────────────────
router.get('/:familyId', authenticate, async (req, res, next) => {
  try {
    const { familyId } = req.params;
    await assertFamilyMember(req.uid, familyId);

    const snap = await db
      .collection('recipes')
      .where('familyId', '==', familyId)
      .orderBy('createdAt', 'desc')
      .limit(50)
      .get();

    const recipes = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    res.json(recipes);
  } catch (err) {
    next(err);
  }
});

// ── GET /api/recipes/:familyId/:recipeId — single recipe ─────────────────────
router.get('/:familyId/:recipeId', authenticate, async (req, res, next) => {
  try {
    const { familyId, recipeId } = req.params;
    await assertFamilyMember(req.uid, familyId);

    const doc = await db.collection('recipes').doc(recipeId).get();
    if (!doc.exists || doc.data().familyId !== familyId) {
      return res.status(404).json({ error: 'Recipe not found' });
    }
    res.json({ id: doc.id, ...doc.data() });
  } catch (err) {
    next(err);
  }
});

// ── DELETE /api/recipes/:familyId/:recipeId ───────────────────────────────────
router.delete('/:familyId/:recipeId', authenticate, async (req, res, next) => {
  try {
    const { familyId, recipeId } = req.params;
    await assertFamilyMember(req.uid, familyId);

    const doc = await db.collection('recipes').doc(recipeId).get();
    if (!doc.exists || doc.data().familyId !== familyId) {
      return res.status(404).json({ error: 'Recipe not found' });
    }
    await doc.ref.delete();
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
