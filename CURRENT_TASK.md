# 📍 CURRENT_TASK.md
## Текущий Этап Разработки

**Последний обновлен:** 2026-03-31
**Текущая фаза:** ФАЗА 1
**Статус:** СПРИНТ 1.1 ✅ СПРИНТ 1.2 ✅ — ГОТОВ К ФАЗЕ 2 🟢

---

## ✅ ЗАВЕРШЁННЫЕ СПРИНТЫ

### ФАЗА 1 СПРИНТ 1.1: Backend Setup — DONE
- [x] 1.1.1 — Инициализация Node.js проекта
- [x] 1.1.2 — Инициализация Express сервера
- [x] 1.1.3 — Firebase Admin SDK интеграция
- [x] 1.1.4 — Firestore Security Rules

### ФАЗА 1 СПРИНТ 1.2: Flutter Auth UI — DONE
- [x] 1.2.1 — Инициализация Flutter проекта
- [x] 1.2.2 — Firebase конфигурация в Flutter
- [x] 1.2.3 — Authentication Service
- [x] 1.2.4 — Auth Provider (State Management)
- [x] 1.2.5 — Navigation Setup
- [x] 1.2.6 — Login Screen UI
- [x] 1.2.7 — Register Screen UI
- [x] 1.2.8 — Main App Setup

---

## 🎯 СЛЕДУЮЩИЙ СПРИНТ

### ФАЗА 2: Family Management

**Цель:** Создание и управление семьёй, профили членов семьи

**Список задач:**

- [ ] **2.1.1** — Family Create/Join Backend
  - `backend/src/routes/users.js` — POST /api/families, POST /api/families/join
  - Firestore: /families, /family_members

- [ ] **2.1.2** — Family Management UI
  - `frontend/lib/screens/home/home_screen.dart` — экран выбора/создания семьи

- [ ] **2.1.3** — Member Preferences Management
  - `frontend/lib/screens/profile/` — экран настройки предпочтений члена семьи
  - dietaryPreferences, dislikedIngredients, preferredCuisines, cookingLevel

- [ ] **2.2.1** — Family Sync Services
  - `frontend/lib/services/family_service.dart`
  - Реалтайм синхронизация через Firestore streams

---

## 📝 ЗАПРОС К CLAUDE CODE ДЛЯ СЛЕДУЮЩЕЙ СЕССИИ

```
# ФАЗА 2 — Family Management

ФАЗА 1 полностью готова (backend + Flutter auth).
Начинаем ФАЗА 2.

Задача 2.1.1: Family Create/Join Backend

Нужно создать в backend:
- POST /api/families — создать семью, добавить создателя как члена
- POST /api/families/join — присоединиться по invite коду
- GET /api/families/:familyId — данные семьи + члены
- POST /api/families/:familyId/members — добавить члена семьи (ребёнок/пожилой)

Дай полный код с Firestore интеграцией.
```

---

**Статус: ФАЗА 1 завершена! Готов к ФАЗЕ 2 🚀**
