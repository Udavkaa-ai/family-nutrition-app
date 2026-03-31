# 📍 CURRENT_TASK.md
## Текущий Этап Разработки

**Последний обновлен:** 2025-03-31  
**Текущая фаза:** ФАЗА 1  
**Статус:** ГОТОВ К НАЧАЛУ 🟢

---

## 🎯 ТЕКУЩИЙ СПРИНТ

### ФАЗА 1 СПРИНТ 1.1: Backend Setup

**Цель:** Настроить Node.js backend с Express и Firebase Admin SDK

**Список задач:**

- [ ] **1.1.1** - Инициализация Node.js проекта
  - Файлы: `package.json`, `.gitignore`
  - Зависимости: express, firebase-admin, axios, cors, helmet, morgan, dotenv
  
- [ ] **1.1.2** - Инициализация Express сервера
  - Файлы: `src/index.js`
  - Middleware: cors, helmet, morgan
  - Health check endpoint

- [ ] **1.1.3** - Firebase Admin SDK интеграция
  - Файлы: `src/config/firebase.js`
  - Инициализация Firebase Admin
  - Экспорт db и auth объектов

- [ ] **1.1.4** - Firestore Security Rules
  - Файлы: `firebase/firestore.rules`
  - Rules для всех collections
  - Deploy на Firebase

---

## 📝 ЧТО РАЗВИВАТЬ В ЭТУ СЕССИЮ

### Запрос к Claude Code:

```
# ФАЗА 1 СПРИНТ 1.1 - Backend Setup

[СКОПИРУЙ ВЕСЬ CLAUDE_INSTRUCTIONS.md]

---

Смотря на задачи в CURRENT_TASK.md, разработаем ФАЗА 1 СПРИНТ 1.1.

Начинаем с Задачи 1.1.1: Инициализация Node.js проекта

Нужно создать:
- Папку family-nutrition-app/backend
- package.json с нужными скриптами и зависимостями
- .env.example с всеми переменными окружения
- .gitignore (игнорить node_modules, .env, .DS_Store)
- README.md в backend папке
- Начальную структуру: src/, test/ папки

Дай полный готовый код и команды для запуска.
```

---

## 🔗 ССЫЛКА НА ИНСТРУКЦИИ

Детальные инструкции для текущего спринта находятся в:  
→ `/claude_sessions/phase1_sprint1.md`

---

## 📊 ПРОВЕРКА ПРОГРЕССА

После завершения Задачи 1.1.1, ты должен иметь:
- ✅ Папка `backend/` с структурой
- ✅ `package.json` с зависимостями
- ✅ `.env.example` готов для заполнения
- ✅ `.gitignore` исключает нужные файлы
- ✅ Git репозиторий инициализирован
- ✅ Коммит: `feat: ФАЗА 1 Task 1.1.1 - Node.js project initialization`

---

## 🚀 ПОСЛЕ ЭТОГО СПРИНТА

Когда закончишь все 4 задачи ФАЗА 1 СПРИНТ 1.1:

1. **Код готов к запуску:**
   ```bash
   cd backend
   npm install
   npm run dev
   # Server running on http://localhost:3000
   ```

2. **Файл CURRENT_TASK.md обновится на:**
   - ФАЗА 1 СПРИНТ 1.2: Flutter Auth UI

3. **Файл PROGRESS.md обновится с:**
   - ✅ ФАЗА 1 СПРИНТ 1.1 завершен
   - Осталось: 7 задач в ФАЗА 1.2

---

## 💡 СОВЕТЫ

- Работаешь с телефона? Просто копируй инструкции в Claude Code
- Забыл что делать? Посмотри `/claude_sessions/phase1_sprint1.md`
- Нужна помощь? Спроси в начало сессии с этим файлом

---

**Статус: Готов начать разработку! 🎉**

Следующий шаг: Скопируй CLAUDE_INSTRUCTIONS.md в Claude Code и начни Задачу 1.1.1
