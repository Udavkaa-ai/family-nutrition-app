# 🍽️ Family Nutrition Advisor
## Семейный Советчик по Питанию

Android приложение для подбора рецептов на основе предпочтений семьи, наличия продуктов и времени на готовку с использованием ИИ.

---

## 📱 Возможности

✅ **Управление профилями** — каждый член семьи со своими предпочтениями  
✅ **Рекомендации рецептов** — через OpenRouter API (Claude AI)  
✅ **Управление кладовой** — отслеживание продуктов дома  
✅ **Автоматический список покупок** — недостающие ингредиенты  
✅ **Real-time синхронизация** — все изменения видны всем членам семьи  
✅ **Минималистичный интерфейс** — быстрый и удобный UX  

---

## 🛠️ СТЕК ТЕХНОЛОГИЙ

### Frontend
- **Flutter** (Dart) — кроссплатформенное мобильное приложение
- **Provider** — управление состоянием
- **Firebase** — авторизация и Firestore БД
- **Go Router** — навигация

### Backend
- **Node.js + Express** — REST API
- **Firebase Admin SDK** — работа с БД
- **OpenRouter API** — интеграция с Claude AI
- **Firestore** — реальная база данных

### DevOps
- **Firebase** — хостинг, auth, БД
- **GitHub** — версионный контроль

---

## 📁 СТРУКТУРА ПРОЕКТА

```
family-nutrition-app/
├── backend/                      # Node.js Backend
│   ├── src/
│   │   ├── index.js             # Entry point
│   │   ├── config/
│   │   │   └── firebase.js       # Firebase config
│   │   ├── routes/              # API endpoints
│   │   ├── services/            # Business logic
│   │   ├── middleware/
│   │   └── utils/
│   ├── test/                    # Tests
│   ├── .env.example             # Environment template
│   ├── package.json
│   └── README.md
│
├── frontend/                     # Flutter App
│   ├── lib/
│   │   ├── main.dart
│   │   ├── config/
│   │   ├── models/              # Data models
│   │   ├── screens/             # UI screens
│   │   ├── widgets/             # Reusable components
│   │   ├── providers/           # State management
│   │   ├── services/            # API & Firebase
│   │   └── utils/
│   ├── test/                    # Tests
│   ├── pubspec.yaml
│   └── README.md
│
├── firebase/                     # Firebase config
│   └── firestore.rules          # Security rules
│
├── claude_sessions/              # Claude Code инструкции
│   ├── phase1_sprint1.md
│   ├── phase1_sprint2.md
│   └── ...
│
├── CLAUDE_INSTRUCTIONS.md        # ← Скопируй в Claude Code
├── CURRENT_TASK.md               # ← Текущий этап
├── PROGRESS.md                   # ← Прогресс разработки
├── README.md                     # ← Этот файл
└── .gitignore
```

---

## 🚀 БЫСТРЫЙ СТАРТ

### Предварительные требования

- **Backend:** Node.js 14+, npm
- **Frontend:** Flutter SDK 3.0+, Android SDK
- **Firebase:** Firebase Project (free tier достаточно)
- **OpenRouter:** API ключ (оптимизирует стоимость запросов к Claude)

### Установка Backend

```bash
cd backend
npm install
cp .env.example .env
# Заполни .env своими переменными окружения
npm run dev
# Сервер запустится на http://localhost:3000
```

### Установка Frontend

```bash
cd frontend
flutter pub get
# Обнови firebase_config.dart с твоими Firebase credentials
flutter run
```

### Firebase Setup

1. Создай новый проект в [Firebase Console](https://console.firebase.google.com)
2. Включи Firestore Database
3. Включи Authentication (Email/Password)
4. Скачай Service Account JSON для Backend
5. Скачай google-services.json для Frontend

---

## 🔐 ПЕРЕМЕННЫЕ ОКРУЖЕНИЯ

### Backend (.env)

```env
# Firebase
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----
FIREBASE_CLIENT_EMAIL=your-email@appspot.gserviceaccount.com

# OpenRouter (AI)
OPENROUTER_API_KEY=your-openrouter-key
OPENROUTER_MODEL=claude-3.5-sonnet

# Server
PORT=3000
NODE_ENV=development
FRONTEND_URL=http://localhost:5000
LOG_LEVEL=info
```

### Frontend (lib/config/firebase_config.dart)

```dart
const firebaseOptions = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  appId: 'YOUR_APP_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  authDomain: 'YOUR_PROJECT.firebaseapp.com',
  databaseURL: 'https://YOUR_PROJECT.firebaseio.com',
  storageBucket: 'YOUR_PROJECT.appspot.com',
);
```

---

## 📋 РАЗРАБОТКА С CLAUDE CODE

### Как работать

1. **Открой Claude Code сессию**
2. **Скопируй весь текст из `CLAUDE_INSTRUCTIONS.md`** (главный файл)
3. **Открой `CURRENT_TASK.md`** — узнай текущий этап
4. **Начни разработку** по инструкциям

### После каждого спринта

- Я обновляю `CURRENT_TASK.md` с следующим этапом
- Я обновляю `PROGRESS.md` с прогрессом
- Ты коммитишь и пушишь в GitHub

### Структура инструкций

```
CLAUDE_INSTRUCTIONS.md       ← Скопируй в Claude Code сессию
├── CURRENT_TASK.md          ← Текущая задача
├── PROGRESS.md              ← Отслеживание прогресса
└── claude_sessions/
    ├── phase1_sprint1.md    ← Детальная инструкция
    ├── phase1_sprint2.md
    └── ...
```

---

## 📊 ФАЗЫ РАЗРАБОТКИ

```
НЕДЕЛЯ 1: ФАЗА 1 — Backend Setup + Auth UI ✅
  Спринт 1.1: Backend (4 задачи)
  Спринт 1.2: Flutter Auth (8 задач)
  
НЕДЕЛЯ 2: ФАЗА 2 — Family Management
  Спринт 2: Create/Join Family + Profiles
  
НЕДЕЛЯ 3: ФАЗА 3 — Pantry Management
  Спринт 3: Pantry CRUD + Sync
  
НЕДЕЛЯ 4: ФАЗА 4 — Recipes + OpenRouter AI
  Спринт 4: Recipe Generation + UI
  
НЕДЕЛЯ 5: ФАЗА 5 — Shopping List
  Спринт 5: Auto-generation + Export
  
НЕДЕЛЯ 6: ФАЗА 6 — Testing + Polish
  Спринт 6: Tests + Optimization
  
НЕДЕЛЯ 7-8: Deploy & Release 🚀
```

---

## 📖 ДОКУМЕНТАЦИЯ

| Файл | Описание |
|------|---------|
| `CLAUDE_INSTRUCTIONS.md` | ← **ГЛАВНЫЙ ФАЙЛ** (скопируй в Claude Code) |
| `CURRENT_TASK.md` | Текущий этап разработки |
| `PROGRESS.md` | Отслеживание прогресса (обновляется после каждого спринта) |
| `backend/README.md` | Backend документация |
| `frontend/README.md` | Frontend документация |
| `app_development_plan.md` | Полная архитектура и дизайн |
| `DETAILED_DEVELOPMENT_PLAN.md` | Пошаговый план всех фаз |
| `QUICK_START.md` | Быстрая инструкция для Claude Code |

---

## 🧪 ТЕСТИРОВАНИЕ

### Backend

```bash
cd backend
npm test
```

### Frontend

```bash
cd frontend
flutter test
```

---

## 🚢 РАЗВЕРТЫВАНИЕ

### Backend на Firebase

```bash
firebase deploy --only functions
```

### Frontend на Google Play

```bash
cd frontend
flutter build appbundle
# Загрузи build/app/outputs/bundle/release/app-release.aab в Google Play Console
```

---

## 🤝 ВКЛАД

Это проект для личного использования, но если ты хочешь:
1. Форк репо
2. Создай ветку (`git checkout -b feature/amazing-feature`)
3. Коммит изменений (`git commit -m 'feat: add amazing feature'`)
4. Push в ветку (`git push origin feature/amazing-feature`)
5. Открой Pull Request

---

## 📞 ПОМОЩЬ

**Забыл как начать разработку?**  
→ Посмотри `CLAUDE_INSTRUCTIONS.md`

**Не знаю на какой задаче остановился?**  
→ Посмотри `CURRENT_TASK.md` и `PROGRESS.md`

**Нужны детали для текущего спринта?**  
→ Посмотри `claude_sessions/phase[N]_sprint[N].md`

**Полная архитектура и дизайн?**  
→ Посмотри `app_development_plan.md`

---

## 📝 ЛИЦЕНЗИЯ

MIT License — используй как хочешь

---

## 🎯 СТАТУС ПРОЕКТА

- ✅ Планирование завершено
- ✅ Архитектура готова
- ✅ Инструкции для Claude Code подготовлены
- 🟡 Разработка готова начаться (ФАЗА 1)
- ⏳ ФАЗА 2-6 в ожидании

**Прогресс:** 0% (готов к началу разработки)

---

## 📋 ЧЕКЛИСТ ПЕРЕД НАЧАЛОМ

- [ ] Клонирован репо с GitHub
- [ ] Backend .env заполнен
- [ ] Frontend firebase_config.dart обновлен
- [ ] Прочитан CLAUDE_INSTRUCTIONS.md
- [ ] Посмотрен CURRENT_TASK.md
- [ ] Готов начать разработку ✅

---

## 🚀 НАЧНИ РАЗРАБОТКУ

1. **Скопируй `CLAUDE_INSTRUCTIONS.md`** в Claude Code сессию
2. **Посмотри `CURRENT_TASK.md`** — текущая задача
3. **Начни ФАЗУ 1 СПРИНТ 1.1** — Backend Setup
4. **Коммитируй каждые 30-60 минут**
5. **После спринта я обновлю файлы** с прогрессом

---

**Готов начать разработку? Скопируй CLAUDE_INSTRUCTIONS.md в Claude Code! 🎉**

---

*Last updated: 2025-03-31*  
*Project Status: Ready for development 🟢*
