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

/** Resolve pantry doc for the family. Creates it if it doesn't exist yet. */
const getPantryRef = async (familyId) => {
  const snap = await db
    .collection('pantry')
    .where('familyId', '==', familyId)
    .limit(1)
    .get();

  if (!snap.empty) return snap.docs[0].ref;

  // Create an empty pantry for the family
  const ref = db.collection('pantry').doc();
  await ref.set({ familyId, items: {}, updatedAt: new Date() });
  return ref;
};

/** Verify the requesting user belongs to the family. */
const assertFamilyMember = async (uid, familyId) => {
  const doc = await db.collection('families').doc(familyId).get();
  if (!doc.exists || !doc.data()?.members?.[uid]) {
    throw Object.assign(new Error('Not a member of this family'), { status: 403 });
  }
};

// ── GET /api/pantry/:familyId ─────────────────────────────────────────────────
router.get('/:familyId', authenticate, async (req, res, next) => {
  try {
    const { familyId } = req.params;
    await assertFamilyMember(req.uid, familyId);

    const ref = await getPantryRef(familyId);
    const doc = await ref.get();
    const items = doc.data()?.items ?? {};

    // Return items as an array for easier Flutter consumption
    const itemsArray = Object.entries(items).map(([id, item]) => ({ id, ...item }));
    res.json({ familyId, items: itemsArray });
  } catch (err) {
    next(err);
  }
});

// ── POST /api/pantry/:familyId/items — add item ───────────────────────────────
router.post('/:familyId/items', authenticate, async (req, res, next) => {
  try {
    const { familyId } = req.params;
    await assertFamilyMember(req.uid, familyId);

    const { name, quantity, unit } = req.body;
    if (!name?.trim()) return res.status(400).json({ error: 'Item name is required' });

    const itemId = db.collection('_').doc().id; // generate unique id
    const item = {
      name: name.trim(),
      quantity: quantity ?? 1,
      unit: unit?.trim() ?? '',
    };

    const ref = await getPantryRef(familyId);
    await ref.update({
      [`items.${itemId}`]: item,
      updatedAt: new Date(),
    });

    logger.info(`Pantry item added: ${itemId} to family ${familyId}`);
    res.status(201).json({ id: itemId, ...item });
  } catch (err) {
    next(err);
  }
});

// ── PUT /api/pantry/:familyId/items/:itemId — update item ────────────────────
router.put('/:familyId/items/:itemId', authenticate, async (req, res, next) => {
  try {
    const { familyId, itemId } = req.params;
    await assertFamilyMember(req.uid, familyId);

    const allowed = ['name', 'quantity', 'unit'];
    const updates = {};
    for (const key of allowed) {
      if (req.body[key] !== undefined) updates[`items.${itemId}.${key}`] = req.body[key];
    }
    if (Object.keys(updates).length === 0) {
      return res.status(400).json({ error: 'No valid fields to update' });
    }
    updates.updatedAt = new Date();

    const ref = await getPantryRef(familyId);
    await ref.update(updates);

    res.json({ success: true });
  } catch (err) {
    next(err);
  }
});

// ── DELETE /api/pantry/:familyId/items/:itemId — remove item ─────────────────
router.delete('/:familyId/items/:itemId', authenticate, async (req, res, next) => {
  try {
    const { familyId, itemId } = req.params;
    await assertFamilyMember(req.uid, familyId);

    const { FieldValue } = require('firebase-admin/firestore');
    const ref = await getPantryRef(familyId);
    await ref.update({
      [`items.${itemId}`]: FieldValue.delete(),
      updatedAt: new Date(),
    });

    logger.info(`Pantry item deleted: ${itemId} from family ${familyId}`);
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
});

// ── DELETE /api/pantry/:familyId — clear all items ───────────────────────────
router.delete('/:familyId', authenticate, async (req, res, next) => {
  try {
    const { familyId } = req.params;
    await assertFamilyMember(req.uid, familyId);

    const ref = await getPantryRef(familyId);
    await ref.update({ items: {}, updatedAt: new Date() });

    res.json({ success: true });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
