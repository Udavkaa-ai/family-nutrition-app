# Family Nutrition Backend

Node.js/Express backend for the Family Nutrition Advisor app.

## Quick Start

```bash
# Install dependencies
npm install

# Copy env file and fill in your values
cp .env.example .env

# Start development server (hot-reload)
npm run dev

# Check server is running
curl http://localhost:3000/health
```

## Project Structure

```
backend/
├── src/
│   ├── index.js            # Entry point, Express app setup
│   ├── config/
│   │   └── firebase.js     # Firebase Admin SDK init
│   ├── routes/
│   │   ├── auth.js         # Auth endpoints
│   │   ├── users.js        # User endpoints
│   │   ├── recipes.js      # Recipe endpoints
│   │   └── shopping-lists.js
│   ├── middleware/
│   │   └── error-handler.js
│   └── utils/
│       └── logger.js
├── test/                   # Jest tests
├── .env.example            # Environment variable template
└── package.json
```

## Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com) → Project Settings → Service Accounts
2. Click **Generate new private key** and download the JSON file
3. Copy values from the JSON into your `.env`:
   - `FIREBASE_PROJECT_ID` ← `project_id`
   - `FIREBASE_CLIENT_EMAIL` ← `client_email`
   - `FIREBASE_PRIVATE_KEY` ← `private_key` (keep the `\n` newlines)

## API Endpoints

| Method | Path         | Description        |
|--------|--------------|--------------------|
| GET    | /health      | Health check       |
| GET    | /api/status  | API version/status |

## Scripts

| Command            | Description              |
|--------------------|--------------------------|
| `npm run dev`      | Start with hot-reload    |
| `npm start`        | Start production server  |
| `npm test`         | Run Jest tests           |
| `npm run test:coverage` | Tests with coverage |
