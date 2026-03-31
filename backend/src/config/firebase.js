const admin = require('firebase-admin');
const logger = require('../utils/logger');

// Initialize Firebase Admin SDK using environment variables.
// Requires FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, FIREBASE_CLIENT_EMAIL in .env
const initFirebase = () => {
  if (admin.apps.length > 0) {
    return; // Already initialized (e.g. during tests)
  }

  const { FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, FIREBASE_CLIENT_EMAIL } = process.env;

  if (!FIREBASE_PROJECT_ID || !FIREBASE_PRIVATE_KEY || !FIREBASE_CLIENT_EMAIL) {
    throw new Error(
      'Missing Firebase credentials. Set FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, FIREBASE_CLIENT_EMAIL in .env'
    );
  }

  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: FIREBASE_PROJECT_ID,
      // The private key arrives as a string with literal \n — convert them to real newlines
      privateKey: FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
      clientEmail: FIREBASE_CLIENT_EMAIL,
    }),
    databaseURL: `https://${FIREBASE_PROJECT_ID}.firebaseio.com`,
  });

  logger.info('Firebase Admin SDK initialized');
};

try {
  initFirebase();
} catch (err) {
  // Log the error but don't crash — allows the server to start without real credentials
  // during local development. Routes that need Firestore will fail explicitly.
  require('../utils/logger').warn(`Firebase init skipped: ${err.message}`);
}

const db = admin.apps.length > 0 ? admin.firestore() : null;
const auth = admin.apps.length > 0 ? admin.auth() : null;

module.exports = { admin, db, auth };
