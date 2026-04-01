const { Router } = require('express');
const { db, auth } = require('../config/firebase');
const logger = require('../utils/logger');

const router = Router();

// ── Helpers ───────────────────────────────────────────────────────────────────

/** Verify Firebase ID token and attach uid to req */
const authenticate = async (req, res, next) => {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing authorization header' });
  }
  try {
    const token = header.split(' ')[1];
    const decoded = await auth.verifyIdToken(token);
    req.uid = decoded.uid;
    next();
  } catch {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
};

/** Generate a short random invite code */
const generateInviteCode = () =>
  Math.random().toString(36).substring(2, 8).toUpperCase();

// ── POST /api/families — create a new family ──────────────────────────────────
router.post('/', authenticate, async (req, res) => {
  const { name } = req.body;
  if (!name?.trim()) {
    return res.status(400).json({ error: 'Family name is required' });
  }

  const uid = req.uid;

  // Check user isn't already in a family
  const userDoc = await db.collection('users').doc(uid).get();
  if (userDoc.data()?.familyId) {
    return res.status(409).json({ error: 'You are already in a family' });
  }

  const inviteCode = generateInviteCode();
  const batch = db.batch();

  const familyRef = db.collection('families').doc();
  batch.set(familyRef, {
    name: name.trim(),
    inviteCode,
    members: { [uid]: true },
    createdBy: uid,
    createdAt: new Date(),
  });

  // Update user's familyId
  batch.update(db.collection('users').doc(uid), { familyId: familyRef.id });

  await batch.commit();

  logger.info(`Family created: ${familyRef.id} by ${uid}`);
  res.status(201).json({ familyId: familyRef.id, inviteCode });
});

// ── POST /api/families/join — join by invite code ─────────────────────────────
router.post('/join', authenticate, async (req, res) => {
  const { inviteCode } = req.body;
  if (!inviteCode?.trim()) {
    return res.status(400).json({ error: 'Invite code is required' });
  }

  const uid = req.uid;

  const userDoc = await db.collection('users').doc(uid).get();
  if (userDoc.data()?.familyId) {
    return res.status(409).json({ error: 'You are already in a family' });
  }

  // Find family by invite code
  const snap = await db
    .collection('families')
    .where('inviteCode', '==', inviteCode.trim().toUpperCase())
    .limit(1)
    .get();

  if (snap.empty) {
    return res.status(404).json({ error: 'Invalid invite code' });
  }

  const familyDoc = snap.docs[0];
  const batch = db.batch();

  batch.update(familyDoc.ref, { [`members.${uid}`]: true });
  batch.update(db.collection('users').doc(uid), { familyId: familyDoc.id });

  await batch.commit();

  logger.info(`User ${uid} joined family ${familyDoc.id}`);
  res.json({ familyId: familyDoc.id, name: familyDoc.data().name });
});

// ── GET /api/families/:familyId — get family + members ───────────────────────
router.get('/:familyId', authenticate, async (req, res) => {
  const { familyId } = req.params;
  const uid = req.uid;

  const familyDoc = await db.collection('families').doc(familyId).get();
  if (!familyDoc.exists) {
    return res.status(404).json({ error: 'Family not found' });
  }

  const family = familyDoc.data();
  if (!family.members?.[uid]) {
    return res.status(403).json({ error: 'Not a member of this family' });
  }

  // Fetch family members
  const membersSnap = await db
    .collection('family_members')
    .where('familyId', '==', familyId)
    .get();

  const members = membersSnap.docs.map((d) => ({ id: d.id, ...d.data() }));

  res.json({
    id: familyDoc.id,
    name: family.name,
    inviteCode: family.inviteCode,
    members,
  });
});

// ── POST /api/families/:familyId/members — add a family member profile ────────
router.post('/:familyId/members', authenticate, async (req, res) => {
  const { familyId } = req.params;
  const uid = req.uid;

  const familyDoc = await db.collection('families').doc(familyId).get();
  if (!familyDoc.exists || !familyDoc.data().members?.[uid]) {
    return res.status(403).json({ error: 'Not a member of this family' });
  }

  const {
    name,
    dietaryPreferences = [],
    dislikedIngredients = [],
    preferredCuisines = [],
    cookingLevel = 'medium',
  } = req.body;

  if (!name?.trim()) {
    return res.status(400).json({ error: 'Member name is required' });
  }

  const memberRef = await db.collection('family_members').add({
    familyId,
    name: name.trim(),
    dietaryPreferences,
    dislikedIngredients,
    preferredCuisines,
    cookingLevel,
    createdAt: new Date(),
  });

  logger.info(`Family member added: ${memberRef.id} to family ${familyId}`);
  res.status(201).json({ id: memberRef.id });
});

// ── PUT /api/families/:familyId/members/:memberId — update member ─────────────
router.put('/:familyId/members/:memberId', authenticate, async (req, res) => {
  const { familyId, memberId } = req.params;
  const uid = req.uid;

  const familyDoc = await db.collection('families').doc(familyId).get();
  if (!familyDoc.exists || !familyDoc.data().members?.[uid]) {
    return res.status(403).json({ error: 'Not a member of this family' });
  }

  const allowed = ['name', 'dietaryPreferences', 'dislikedIngredients', 'preferredCuisines', 'cookingLevel'];
  const updates = {};
  for (const key of allowed) {
    if (req.body[key] !== undefined) updates[key] = req.body[key];
  }

  await db.collection('family_members').doc(memberId).update(updates);
  res.json({ success: true });
});

module.exports = router;
