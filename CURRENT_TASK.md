# 📍 CURRENT_TASK.md
## Текущий Этап Разработки

**Последний обновлен:** 2026-03-31
**Текущая фаза:** ФАЗА 1
**Статус:** СПРИНТ 1.1 ЗАВЕРШЕН ✅ — ГОТОВ К СПРИНТУ 1.2 🟢

---

## ✅ ЗАВЕРШЕННЫЙ СПРИНТ

### ФАЗА 1 СПРИНТ 1.1: Backend Setup — DONE

- [x] **1.1.1** - Инициализация Node.js проекта
- [x] **1.1.2** - Инициализация Express сервера
- [x] **1.1.3** - Firebase Admin SDK интеграция
- [x] **1.1.4** - Firestore Security Rules

---

## 🎯 СЛЕДУЮЩИЙ СПРИНТ

### ФАЗА 1 СПРИНТ 1.2: Flutter Auth UI

**Цель:** Настроить Flutter проект с Firebase и реализовать авторизацию

**Список задач:**

- [ ] **1.2.1** - Инициализация Flutter проекта
  - Файлы: `frontend/pubspec.yaml`, `frontend/lib/main.dart`
  - Зависимости: firebase_core, firebase_auth, provider, go_router

- [ ] **1.2.2** - Firebase конфигурация в Flutter
  - Файлы: `frontend/lib/config/firebase_config.dart`
  - FlutterFire CLI, google-services.json

- [ ] **1.2.3** - Authentication Service
  - Файлы: `frontend/lib/services/auth_service.dart`
  - register, login, logout, currentUser

- [ ] **1.2.4** - Auth Provider (State Management)
  - Файлы: `frontend/lib/providers/auth_provider.dart`
  - ChangeNotifier, authState stream

- [ ] **1.2.5** - Navigation Setup
  - Файлы: `frontend/lib/navigation/app_router.dart`
  - go_router, redirect на login если не авторизован

- [ ] **1.2.6** - Login Screen UI
  - Файлы: `frontend/lib/screens/auth/login_screen.dart`
  - Email + Password форма, валидация

- [ ] **1.2.7** - Register Screen UI
  - Файлы: `frontend/lib/screens/auth/register_screen.dart`
  - Name + Email + Password форма

- [ ] **1.2.8** - Main App Setup
  - Файлы: обновить `frontend/lib/main.dart`
  - ProviderScope, MaterialApp с роутером

---

## 📝 ЗАПРОС К CLAUDE CODE ДЛЯ СЛЕДУЮЩЕЙ СЕССИИ

```
# ФАЗА 1 СПРИНТ 1.2 - Flutter Auth UI

[СКОПИРУЙ ВЕСЬ CLAUDE_INSTRUCTIONS.md]

---

Смотря на CURRENT_TASK.md, разработаем ФАЗА 1 СПРИНТ 1.2.

Backend (Sprint 1.1) уже готов и запушен. Начинаем Flutter фронтенд.

Задача 1.2.1: Инициализация Flutter проекта

Нужно создать:
- frontend/pubspec.yaml с зависимостями (firebase_core, firebase_auth, provider, go_router, http)
- frontend/lib/main.dart (заглушка)
- Структуру папок: models/, screens/auth/, providers/, services/, widgets/, utils/, navigation/

Дай полный готовый код.
```

---

## 🔗 ССЫЛКА НА ИНСТРУКЦИИ

Детальные инструкции для текущего спринта:
→ `/phase1_sprint1.md`

---

**Статус: Готов к СПРИНТУ 1.2! 🚀**
