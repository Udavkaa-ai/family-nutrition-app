# 🍽️ CLAUDE_INSTRUCTIONS.md
## Family Nutrition Advisor App — Инструкции для Claude Code

**Это главный файл! Скопируй всё содержимое в начало каждой Claude Code сессии.**

---

## ⚡ БЫСТРЫЙ СТАРТ

### Перед работой:
1. ✅ Прочитай `CURRENT_TASK.md` (текущий этап)
2. ✅ Посмотри `PROGRESS.md` (что сделано)
3. ✅ Скопируй этот файл в Claude Code сессию

### После работы:
1. ✅ Я обновлю `CURRENT_TASK.md`
2. ✅ Я обновлю `PROGRESS.md`
3. ✅ Ты коммитишь и пушишь в GitHub

---

## 🏗️ АРХИТЕКТУРА ПРОЕКТА

```
family-nutrition-app/
├── backend/                    # Node.js Express
│   ├── src/
│   │   ├── index.js
│   │   ├── config/
│   │   │   └── firebase.js
│   │   ├── routes/
│   │   │   ├── auth.js
│   │   │   ├── users.js
│   │   │   ├── recipes.js
│   │   │   └── shopping-lists.js
│   │   ├── services/
│   │   ├── middleware/
│   │   └── utils/
│   ├── .env.example
│   └── package.json
│
├── frontend/                   # Flutter
│   ├── lib/
│   │   ├── main.dart
│   │   ├── config/
│   │   │   └── firebase_config.dart
│   │   ├── models/
│   │   ├── screens/
│   │   │   ├── auth/
│   │   │   ├── home/
│   │   │   ├── recipe/
│   │   │   ├── pantry/
│   │   │   ├── shopping_list/
│   │   │   └── profile/
│   │   ├── providers/
│   │   ├── services/
│   │   ├── widgets/
│   │   └── utils/
│   └── pubspec.yaml
│
├── firebase/
│   └── firestore.rules
│
├── claude_sessions/            # Инструкции для каждого спринта
│   ├── phase1_sprint1.md
│   ├── phase1_sprint2.md
│   └── ...
│
├── CLAUDE_INSTRUCTIONS.md      # ← ТЫ СКОПИРУЕШЬ ЭТО В НАЧАЛО
├── CURRENT_TASK.md             # ← ТЕКУЩИЙ ЭТАП
├── PROGRESS.md                 # ← ЧТО СДЕЛАНО
├── README.md
└── .gitignore
```

---

## 📋 СТАНДАРТЫ КОДИРОВАНИЯ

### Dart/Flutter

```dart
// ✅ Всегда типизированный код
class RecipeProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;
  List<Recipe> _recipes = [];
  List<Recipe> get recipes => _recipes;
  
  Future<void> fetchRecipes(String familyId) async {
    try {
      _recipes = await _firebaseService.getRecipes(familyId);
      notifyListeners();
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }
}

// Правила:
// - Никогда dynamic, всегда конкретные типы
// - async/await для асинхронных операций
// - try-catch везде где может быть ошибка
// - camelCase для переменных, PascalCase для классов
```

### JavaScript/Node.js

```javascript
// ✅ Production-ready код
const getRecipesFromOpenRouter = async (preferences, cookTime) => {
  try {
    const response = await axios.post(
      'https://openrouter.io/api/v1/chat/completions',
      {
        model: 'claude-3.5-sonnet',
        messages: [{ role: 'user', content: buildPrompt(preferences, cookTime) }],
        temperature: 0.7,
        max_tokens: 2000,
      },
      { headers: { 'Authorization': `Bearer ${process.env.OPENROUTER_KEY}` } }
    );
    
    return parseRecipesFromResponse(response.data);
  } catch (error) {
    logger.error('OpenRouter error:', error);
    throw new Error('Failed to fetch recipes');
  }
};

// Правила:
// - Всегда обработка ошибок
// - const/let, никогда var
// - async/await вместо .then()
// - Комментарии только где неочевидно
```

---

## 🔧 БЫСТРЫЕ КОМАНДЫ

### Backend

```bash
cd backend
npm install           # Первый раз
npm run dev          # Запуск с hot-reload
npm test             # Тесты
curl http://localhost:3000/health  # Проверка
```

### Frontend

```bash
cd frontend
flutter pub get      # Первый раз
flutter run          # Запуск
flutter test         # Тесты
```

### Git

```bash
git status
git add .
git commit -m "feat: ФАЗА N Task N.N.N - Описание"
git push origin main
```

---

## 🔐 ENVIRONMENT VARIABLES

### Backend `.env`

```
# Firebase
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----
FIREBASE_CLIENT_EMAIL=your-client-email@appspot.gserviceaccount.com

# OpenRouter
OPENROUTER_API_KEY=your-openrouter-key
OPENROUTER_MODEL=claude-3.5-sonnet

# Server
PORT=3000
NODE_ENV=development
FRONTEND_URL=http://localhost:5000
```

### Flutter

```
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_API_KEY=your-api-key
FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
BACKEND_API_URL=http://localhost:3000
```

---

## 📊 СТРУКТУРА ДАННЫХ (Firestore)

### Collections:

```
/users/{userId}
  ├── email: string
  ├── name: string
  ├── familyId: string
  └── createdAt: timestamp

/families/{familyId}
  ├── name: string
  ├── members: map<userId, bool>
  └── createdAt: timestamp

/family_members/{memberId}
  ├── familyId: string
  ├── name: string
  ├── dietaryPreferences: array<string>
  ├── dislikedIngredients: array<string>
  ├── preferredCuisines: array<string>
  ├── cookingLevel: string
  └── createdAt: timestamp

/pantry/{pantryId}
  ├── familyId: string
  ├── items: map<itemId, {name, quantity, unit}>
  └── updatedAt: timestamp

/recipes/{recipeId}
  ├── familyId: string
  ├── name: string
  ├── timeMinutes: number
  ├── difficulty: string
  ├── ingredients: array<{name, quantity, unit}>
  ├── instructions: array<string>
  ├── source: string ('ai' | 'user')
  └── createdAt: timestamp

/shopping_lists/{listId}
  ├── familyId: string
  ├── items: array<{name, quantity, unit, checked}>
  ├── createdAt: timestamp
  └── createdBy: string
```

### Security Rules (Firestore):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isInFamily(familyId) {
      return get(/databases/$(database)/documents/families/$(familyId))
        .data.members[request.auth.uid] == true;
    }
    
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    match /families/{familyId} {
      allow read: if isInFamily(familyId);
    }
    
    match /family_members/{memberId} {
      allow read: if isInFamily(resource.data.familyId);
    }
    
    match /pantry/{pantryId} {
      allow read, write: if isInFamily(resource.data.familyId);
    }
    
    match /recipes/{recipeId} {
      allow read: if isInFamily(resource.data.familyId);
    }
    
    match /shopping_lists/{listId} {
      allow read, write: if isInFamily(resource.data.familyId);
    }
  }
}
```

---

## 🤖 OPENROUTER API ИНТЕГРАЦИЯ

### Базовый промпт:

```javascript
const buildRecipePrompt = (familyMembers, cookTime, mealType) => `
You are a family nutrition advisor. Generate recipe recommendations.

Family members: ${familyMembers.map(m => `${m.name} (${m.preferences.join(', ')})`).join('; ')}
Cooking time: ${cookTime} minutes
Meal type: ${mealType}

Provide EXACTLY 4 recipes in valid JSON format:
[
  {
    "name": "Recipe Name",
    "time_minutes": 30,
    "difficulty": "easy|medium|hard",
    "description": "Brief description",
    "ingredients": [
      {"name": "ingredient", "quantity": 250, "unit": "g"}
    ],
    "instructions": ["Step 1", "Step 2"]
  }
]

Return ONLY valid JSON, no additional text.
`;
```

### Парсинг ответа:

```javascript
const parseAIResponse = (responseText) => {
  try {
    const jsonMatch = responseText.match(/\[[\s\S]*\]/);
    if (!jsonMatch) throw new Error('No JSON found');
    
    const recipes = JSON.parse(jsonMatch[0]);
    if (!Array.isArray(recipes) || recipes.length === 0) {
      throw new Error('Invalid format');
    }
    
    return recipes;
  } catch (error) {
    logger.error('Parse error:', error);
    throw new Error('Invalid AI response');
  }
};
```

---

## 🧪 ТЕСТИРОВАНИЕ

### Unit Tests (Dart):

```dart
void main() {
  group('AuthService', () {
    test('register creates user successfully', () async {
      // Arrange
      const email = 'test@example.com';
      
      // Act
      final user = await authService.register(
        email: email,
        password: 'password123',
        name: 'Test User',
      );
      
      // Assert
      expect(user?.email, email);
    });
  });
}
```

### Integration Tests (Backend):

```javascript
describe('Recipe API', () => {
  it('should return recipes from OpenRouter', async () => {
    const response = await request(app)
      .post('/api/recipes/generate')
      .send({
        familyMembers: ['user1'],
        cookTime: 30,
      });
    
    expect(response.status).toBe(200);
    expect(Array.isArray(response.body)).toBe(true);
  });
});
```

---

## 📈 GIT WORKFLOW

```bash
# Создание ветки для спринта
git checkout -b phase1-sprint1

# Во время разработки - коммиты каждые 30-60 минут
git add .
git commit -m "feat: ФАЗА 1 Task 1.1.3 - Firebase Admin SDK setup"

# После спринта
git push origin phase1-sprint1
# Создаешь PR в GitHub (или merge в main если solo)

git checkout main
git pull origin main
git merge phase1-sprint1
git branch -d phase1-sprint1
```

---

## 🎯 ЧТО ДЕЛАТЬ ПЕРЕД НАЧАЛОМ СЕССИИ

1. **Открой этот файл** (CLAUDE_INSTRUCTIONS.md)
2. **Скопируй всё содержимое**
3. **Вставь в Claude Code** в начало сессии
4. **Открой CURRENT_TASK.md** - узнай текущий этап
5. **Открой PROGRESS.md** - посмотри что сделано
6. **Начни разработку** по инструкциям из папки `/claude_sessions/`

---

## ✅ ЧТО ДЕЛАТЬ ПОСЛЕ ЗАВЕРШЕНИЯ СПРИНТА

1. **Я обновлю эти файлы:**
   - `CURRENT_TASK.md` — следующий этап
   - `PROGRESS.md` — что сделано + что осталось
   - Файл в `/claude_sessions/` — итоги спринта

2. **Ты:**
   - Пушишь код в GitHub
   - Открываешь следующую сессию
   - Скопируешь обновленный CLAUDE_INSTRUCTIONS.md

---

## 🚨 ЧАСТЫЕ ОШИБКИ

❌ **Забыл скопировать инструкции**  
✅ Скопируй этот файл целиком в Claude Code

❌ **Не знаю на какой задаче остановился**  
✅ Посмотри `CURRENT_TASK.md` и `PROGRESS.md`

❌ **Код не компилируется**  
✅ Проверь: `flutter pub get`, `npm install`

❌ **Забыл коммитить**  
✅ Коммитируй каждые 30-60 минут: `git commit -m "feat: ..."`

---

## 📞 ПОМОЩЬ И ВОПРОСЫ

**В начало сессии:** Скопируй этот файл + CURRENT_TASK.md

**Потом спроси:**
```
"Смотря на CURRENT_TASK.md и PROGRESS.md, 
разработаем [НАЗВАНИЕ ЗАДАЧИ]

Нужно реализовать:
- ...
- ...

Дай полный код."
```

---

**ГОТОВ! Скопируй этот файл и начинай разработку! 🚀**
