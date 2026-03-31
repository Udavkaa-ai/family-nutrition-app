const { Router } = require('express');
const { db, auth } = require('../config/firebase');
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

// ── POST /api/shopping-lists — create list (manual or from recipes) ───────────
router.post('/', authenticate, async (req, res, next) => {
  try {
    const { familyId, items = [], recipeIds = [] } = req.body;
    if (!familyId) return res.status(400).json({ error: 'familyId is required' });

    await assertFamilyMember(req.uid, familyId);

    let allItems = [...items];

    // Aggregate ingredients from selected recipes
    if (recipeIds.length > 0) {
      const recipeSnap = await Promise.all(
        recipeIds.map((id) => db.collection('recipes').doc(id).get())
      );

      const ingredientMap = {};
      for (const doc of recipeSnap) {
        if (!doc.exists || doc.data().familyId !== familyId) continue;
        for (const ing of doc.data().ingredients ?? []) {
          const key = `${ing.name.toLowerCase()}_${ing.unit}`;
          if (ingredientMap[key]) {
            ingredientMap[key].quantity += ing.quantity;
          } else {
            ingredientMap[key] = { name: ing.name, quantity: ing.quantity, unit: ing.unit, checked: false };
          }
        }
      }
      allItems = [...allItems, ...Object.values(ingredientMap)];
    }

    // Ensure all items have required fields
    const normalizedItems = allItems.map((item) => ({
      name: item.name,
      quantity: item.quantity ?? 1,
      unit: item.unit ?? '',
      checked: item.checked ?? false,
    }));

    const listRef = db.collection('shopping_lists').doc();
    await listRef.set({
      familyId,
      items: normalizedItems,
      createdAt: new Date(),
      createdBy: req.uid,
    });

    logger.info(`Shopping list created: ${listRef.id} for family ${familyId}`);
    res.status(201).json({ id: listRef.id, items: normalizedItems });
  } catch (err) {
    next(err);
  }
});

// ── GET /api/shopping-lists/:familyId — list all shopping lists ───────────────
router.get('/:familyId', authenticate, async (req, res, next) => {
  try {
    const { familyId } = req.params;
    await assertFamilyMember(req.uid, familyId);

    const snap = await db
      .collection('shopping_lists')
      .where('familyId', '==', familyId)
      .orderBy('createdAt', 'desc')
      .limit(20)
      .get();

    res.json(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
  } catch (err) {
    next(err);
  }
});

// ── PUT /api/shopping-lists/:listId/items/:index — toggle checked ─────────────
router.put('/:listId/items/:index', authenticate, async (req, res, next) => {
  try {
    const { listId, index } = req.params;
    const { checked } = req.body;

    const doc = await db.collection('shopping_lists').doc(listId).get();
    if (!doc.exists) return res.status(404).json({ error: 'List not found' });

    await assertFamilyMember(req.uid, doc.data().familyId);

    await doc.ref.update({ [`items.${index}.checked`]: checked });
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
});

// ── DELETE /api/shopping-lists/:listId — delete list ─────────────────────────
router.delete('/:listId', authenticate, async (req, res, next) => {
  try {
    const { listId } = req.params;
    const doc = await db.collection('shopping_lists').doc(listId).get();
    if (!doc.exists) return res.status(404).json({ error: 'List not found' });

    await assertFamilyMember(req.uid, doc.data().familyId);
    await doc.ref.delete();

    logger.info(`Shopping list deleted: ${listId}`);
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
