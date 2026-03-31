# 📘 claude_sessions/phase1_sprint1.md
## ФАЗА 1 СПРИНТ 1.1: Backend Setup

**Спринт:** ФАЗА 1, СПРИНТ 1.1  
**Фокус:** Node.js Backend + Express + Firebase Admin SDK  
**Задачи:** 1.1.1, 1.1.2, 1.1.3, 1.1.4  
**Ожидаемое время:** 4-5 часов  

---

## 📋 СОСТАВ СПРИНТА

```
ФАЗА 1 СПРИНТ 1.1
├── Задача 1.1.1: Инициализация Node.js проекта (20 мин)
├── Задача 1.1.2: Инициализация Express сервера (30 мин)
├── Задача 1.1.3: Firebase Admin SDK интеграция (25 мин)
└── Задача 1.1.4: Firestore Security Rules (20 мин)
```

---

## 🎯 ЗАДАЧА 1.1.1: Инициализация Node.js проекта

### Цель
Создать базовую структуру Node.js проекта с нужными зависимостями и конфигурацией.

### Файлы которые нужно создать

```
backend/
├── src/
│   └── .gitkeep
├── test/
│   └── .gitkeep
├── .env.example
├── .gitignore
├── package.json
└── README.md
```

### Инструкции для Claude

```
Разработаем Задачу 1.1.1: Инициализация Node.js проекта

Нужно создать структуру backend проекта с:

1. Папки: backend/, backend/src/, backend/test/
2. package.json с:
   - name: "family-nutrition-backend"
   - version: "0.1.0"
   - description: "Backend for Family Nutrition Advisor"
   - Скрипты: dev (nodemon), start (node), test (jest)
   - Зависимости: express, firebase-admin, axios, cors, helmet, morgan, dotenv
   - DevDependencies: nodemon, jest, supertest

3. .env.example с переменными:
   - FIREBASE_PROJECT_ID
   - FIREBASE_PRIVATE_KEY
   - FIREBASE_CLIENT_EMAIL
   - OPENROUTER_API_KEY
   - OPENROUTER_MODEL
   - PORT
   - NODE_ENV
   - FRONTEND_URL
   - LOG_LEVEL

4. .gitignore исключает:
   - node_modules/
   - .env
   - .env.local
   - .DS_Store
   - *.log
   - dist/
   - build/

5. README.md с:
   - Названием проекта
   - Quick start инструкциями
   - Структурой проекта

Дай полный готовый код для каждого файла.
```

### Что должно быть в итоге

✅ `backend/package.json` — готов к `npm install`  
✅ `backend/.env.example` — пример конфигурации  
✅ `backend/.gitignore` — правильные исключения  
✅ `backend/README.md` — документация  
✅ Git репо инициализирован  

### Коммит

```bash
git add .
git commit -m "feat: ФАЗА 1 Task 1.1.1 - Node.js project initialization"
```

---

## 🎯 ЗАДАЧА 1.1.2: Инициализация Express сервера

### Цель
Создать базовый Express сервер с middleware и структурой для API.

### Файлы которые нужно создать/обновить

```
backend/
└── src/
    ├── index.js ← ГЛАВНЫЙ ФАЙЛ
    ├── routes/
    │   ├── .gitkeep
    │   ├── auth.js
    │   ├── users.js
    │   ├── recipes.js
    │   └── shopping-lists.js
    ├── middleware/
    │   ├── .gitkeep
    │   └── error-handler.js
    └── utils/
        ├── .gitkeep
        └── logger.js
```

### Инструкции для Claude

```
Разработаем Задачу 1.1.2: Инициализация Express сервера

Нужно создать src/index.js с:

1. Импорты:
   - express
   - cors, helmet, morgan
   - dotenv config
   - routes (will import later)

2. Express app setup:
   - helmet() для security headers
   - cors() с FRONTEND_URL из env
   - morgan('combined') для логирования
   - express.json() для JSON парсинга

3. Endpoints:
   - GET /health → { status: 'OK', timestamp }
   - GET /api/status → { status, version, env }

4. Error handling middleware:
   - Catch-all error handler
   - 404 Not Found handler
   - Логирование ошибок в console

5. Server startup:
   - Слушает PORT из env (default 3000)
   - Логирует сообщение при запуске

6. Stub route files:
   - src/routes/auth.js
   - src/routes/users.js
   - src/routes/recipes.js
   - src/routes/shopping-lists.js
   (каждый просто экспортирует пустой router)

7. Utils:
   - src/utils/logger.js с функциями логирования

Дай полный production-ready код с комментариями.
```

### Что должно быть в итоге

✅ `npm run dev` запускает сервер  
✅ `curl http://localhost:3000/health` возвращает OK  
✅ Все middleware работают  
✅ Error handling готов  

### Проверка

```bash
cd backend
npm install
npm run dev

# В другом терминале:
curl http://localhost:3000/health
# Результат: {"status":"OK","timestamp":"..."}
```

### Коммит

```bash
git add .
git commit -m "feat: ФАЗА 1 Task 1.1.2 - Express server setup"
```

---

## 🎯 ЗАДАЧА 1.1.3: Firebase Admin SDK интеграция

### Цель
Интегрировать Firebase Admin SDK и создать конфигурацию.

### Файлы которые нужно создать/обновить

```
backend/
├── src/
│   ├── index.js ← ОБНОВИТЬ
│   └── config/
│       ├── .gitkeep
│       └── firebase.js ← НОВЫЙ ФАЙЛ
├── .env.example ← ОБНОВИТЬ
└── serviceAccountKey.json (локально, не коммитить!)
```

### Инструкции для Claude

```
Разработаем Задачу 1.1.3: Firebase Admin SDK интеграция

1. Создать src/config/firebase.js:
   - Импортировать firebase-admin
   - Инициализировать Firebase Admin с переменными окружения
   - initializeApp() с credential и databaseURL
   - Экспортировать { admin, db, auth }
   - Добавить error handling при инициализации

2. Обновить .env.example:
   - Добавить FIREBASE_PROJECT_ID
   - Добавить FIREBASE_PRIVATE_KEY (с \\n символами)
   - Добавить FIREBASE_CLIENT_EMAIL

3. Обновить .gitignore:
   - Добавить serviceAccountKey.json
   - Добавить .env (уже есть)

4. Обновить src/index.js:
   - Импортировать firebaseConfig в начало
   - Добавить try-catch для инициализации
   - Логировать успешную инициализацию Firebase

5. Обновить README.md:
   - Добавить раздел "Firebase Setup"
   - Инструкции как скачать serviceAccountKey.json
   - Как заполнить .env файл

Дай полный код с обработкой ошибок.
```

### Как получить Firebase credentials

1. Открываешь Firebase Console → Project Settings → Service Accounts
2. Нажимаешь "Generate new private key"
3. Скачиваешь JSON файл
4. Копируешь значения в .env или используешь как serviceAccountKey.json

### Что должно быть в итоге

✅ `src/config/firebase.js` создан  
✅ Firebase инициализируется при запуске  
✅ `npm run dev` не падает  
✅ Логируется успешная инициализация  

### Коммит

```bash
git add .
git commit -m "feat: ФАЗА 1 Task 1.1.3 - Firebase Admin SDK setup"
```

---

## 🎯 ЗАДАЧА 1.1.4: Firestore Security Rules

### Цель
Создать и развернуть правила безопасности для Firestore.

### Файлы которые нужно создать

```
firebase/
├── firestore.rules ← НОВЫЙ ФАЙЛ
└── firebase.json ← КОНФИГ (Firebase CLI генерирует)
```

### Инструкции для Claude

```
Разработаем Задачу 1.1.4: Firestore Security Rules

Создать файл firebase/firestore.rules с правилами:

1. Базовые правила (rules_version = '2'):
   - Функция isAuth() — проверка что пользователь залогинен
   - Функция isInFamily(familyId) — проверка что пользователь в семье

2. Правила для collections:
   - /users/{userId} — read/write только для самого пользователя
   - /families/{familyId} — read только для членов семьи, write: false
   - /family_members/{memberId} — read/write для членов семьи
   - /pantry/{pantryId} — read/write для членов семьи
   - /recipes/{recipeId} — read для членов семьи, write для семьи
   - /shopping_lists/{listId} — read/write для членов семьи

3. Fallback правило:
   - Всё остальное: allow read, write: if false

Дай полный Firestore Rules код с комментариями.
Также дай инструкции как развернуть правила через Firebase CLI.
```

### Как развернуть

```bash
# 1. Установить Firebase CLI (если еще не установлен)
npm install -g firebase-tools

# 2. Логин
firebase login

# 3. Инициализировать Firebase проект
firebase init

# 4. Развернуть правила
firebase deploy --only firestore:rules

# 5. Проверить
firebase firestore:rules:list
```

### Что должно быть в итоге

✅ `firebase/firestore.rules` создан  
✅ Правила развернуты на Firebase  
✅ Firestore Console показывает правила  

### Коммит

```bash
git add firebase/firestore.rules
git commit -m "feat: ФАЗА 1 Task 1.1.4 - Firestore Security Rules"
```

---

## ✅ КОНЕЦ СПРИНТА ФАЗА 1.1

### Что готово

✅ Backend структура  
✅ Express сервер запущен  
✅ Firebase Admin SDK интегрирован  
✅ Firestore правила развернуты  

### Проверка

```bash
cd backend
npm install
npm run dev

# Другой терминал:
curl http://localhost:3000/health
# {"status":"OK","timestamp":"2025-03-31T..."}
```

### Коммиты

```
feat: ФАЗА 1 Task 1.1.1 - Node.js project initialization
feat: ФАЗА 1 Task 1.1.2 - Express server setup
feat: ФАЗА 1 Task 1.1.3 - Firebase Admin SDK integration
feat: ФАЗА 1 Task 1.1.4 - Firestore Security Rules
```

### Следующий спринт

После завершения:
- **Обновляю:** CURRENT_TASK.md → ФАЗА 1 СПРИНТ 1.2
- **Обновляю:** PROGRESS.md → Отмечаю 4 задачи как ✅
- **Создаю:** claude_sessions/phase1_sprint2.md

Ты переходишь на Flutter фронтенд разработку.

---

## 📌 БЫСТРЫЕ КОМАНДЫ

```bash
# Запуск
npm run dev

# Проверка
curl http://localhost:3000/health

# Коммит
git add .
git commit -m "feat: ФАЗА 1 Task X.X.X - [Описание]"

# Push
git push origin main

# Логирование коммитов
git log --oneline -5
```

---

**Спринт ФАЗА 1.1 готов к разработке! 🚀**
