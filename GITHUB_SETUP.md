# 🐙 GITHUB_SETUP.md
## Инструкции по Размещению Проекта на GitHub

---

## 📋 ШАГИ

### Шаг 1: Создание репозитория на GitHub

1. Открой [GitHub](https://github.com) и авторизуйся
2. Нажми **"New"** (создать новый репо)
3. Заполни:
   - **Repository name:** `family-nutrition-app`
   - **Description:** Family Nutrition Advisor — Семейный советчик по питанию
   - **Public:** Выбери (если хочешь делиться) или Private (если приватный)
   - **Initialize repository:** ☐ Не выбирай (у тебя уже есть файлы)
4. Нажми **"Create repository"**

---

### Шаг 2: Инициализация Git локально

```bash
# Перейди в папку проекта
cd family-nutrition-app

# Инициализируй git (если еще не сделал)
git init

# Добавь все файлы
git add .

# Первый коммит
git commit -m "Initial commit: Project structure and documentation"

# Добавь remote (замени USERNAME на свой GitHub username, REPO на название репо)
git remote add origin https://github.com/USERNAME/family-nutrition-app.git

# Переименуй ветку в main (если нужно)
git branch -M main

# Пушь на GitHub
git push -u origin main
```

---

### Шаг 3: Проверка на GitHub

1. Открой `https://github.com/USERNAME/family-nutrition-app`
2. Проверь что все файлы залиты:
   - ✅ `CLAUDE_INSTRUCTIONS.md`
   - ✅ `CURRENT_TASK.md`
   - ✅ `PROGRESS.md`
   - ✅ `README.md`
   - ✅ `.gitignore`
   - ✅ `claude_sessions/` папка

---

## 🔑 GITHUB SETUP ДЛЯ CLAUDE CODE

### Что Claude Code будет делать автоматически

После каждого спринта:
1. Читает файлы из GitHub
2. Пушит обновления в репо
3. Обновляет `CURRENT_TASK.md` и `PROGRESS.md`
4. Создает коммиты с правильными сообщениями

### Git Config (первый раз на новой машине)

```bash
# Если еще не настроил Git
git config --global user.name "Твое имя"
git config --global user.email "твой@email.com"

# Проверь что правильно
git config --list
```

### Authentication

**Способ 1: HTTPS + Personal Access Token (рекомендуется)**

1. Открой GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Нажми "Generate new token (classic)"
3. Выбери:
   - ☑️ repo (полный доступ к приватным репо)
   - ☑️ workflow (для GitHub Actions)
   - ☑️ delete_repo (если нужно удалять)
4. Скопируй токен
5. Используй при запросе пароля:
   ```
   Username: твой_github_username
   Password: ghp_xxx... (твой токен)
   ```

**Способ 2: SSH (продвинутый)**

```bash
# Генерируешь SSH ключ
ssh-keygen -t ed25519 -C "твой@email.com"

# Копируешь содержимое ~/.ssh/id_ed25519.pub
cat ~/.ssh/id_ed25519.pub

# На GitHub: Settings → SSH Keys → New SSH key
# Вставляешь ключ

# Проверяешь
ssh -T git@github.com
```

---

## 📁 СТРУКТУРА РЕПО НА GITHUB

```
family-nutrition-app/
├── backend/
│   ├── src/
│   ├── test/
│   ├── .env.example
│   ├── package.json
│   └── README.md
├── frontend/
│   ├── lib/
│   ├── test/
│   ├── pubspec.yaml
│   └── README.md
├── firebase/
│   └── firestore.rules
├── claude_sessions/
│   ├── phase1_sprint1.md
│   ├── phase1_sprint2.md
│   └── ...
├── CLAUDE_INSTRUCTIONS.md    ← Главный файл
├── CURRENT_TASK.md           ← Текущий этап (обновляется)
├── PROGRESS.md               ← Прогресс (обновляется)
├── README.md
├── .gitignore
└── GITHUB_SETUP.md           ← Этот файл
```

---

## 🔄 WORKFLOW РАЗРАБОТКИ

### Каждая Claude Code сессия:

```
1. Claude Code берет актуальный CLAUDE_INSTRUCTIONS.md
   ↓
2. Разрабатывает задачи из CURRENT_TASK.md
   ↓
3. Коммитит с правильными сообщениями (feat:, fix:, etc)
   ↓
4. Пушит в GitHub
   ↓
5. Обновляет CURRENT_TASK.md (следующий спринт)
   ↓
6. Обновляет PROGRESS.md (прогресс)
   ↓
7. Коммитит обновления инструкций
```

---

## 📝 GIT COMMIT MESSAGES

Claude Code будет использовать такой формат:

```
feat: ФАЗА N Task N.N.N - [Описание задачи]

- Создан файл X
- Реализована функция Y
- Добавлены тесты Z

Закрывает #[issue_number] (если есть)
```

### Примеры:

```
feat: ФАЗА 1 Task 1.1.1 - Node.js project initialization

- Created backend/ directory structure
- Initialized npm project with dependencies
- Created .env.example with environment variables
- Added .gitignore for Node.js

fix: ФАЗА 1 Task 1.1.2 - Fix Express middleware order

- Moved helmet before cors
- Added proper error handling
- Fixed CORS headers

chore: Update PROGRESS.md after PHASE 1 SPRINT 1

- Marked tasks 1.1.1-1.1.4 as complete
- Updated current task for next sprint
- Added estimated time for next phase
```

---

## 🔐 ЗАЩИТА РЕПО

### Рекомендуемые настройки

**GitHub → Settings → Code and automation → Actions**
- ☑️ Allow all actions and reusable workflows

**GitHub → Settings → Code and automation → Branch protection rules**
- Правило для `main`:
  - ☑️ Require a pull request before merging
  - ☑️ Require status checks to pass
  - ☑️ Require branches to be up to date

**GitHub → Settings → Security and analysis**
- ☑️ Dependabot alerts
- ☑️ Dependabot security updates

---

## 📌 ВАЖНО: ЧТО НЕ КОММИТИТЬ

❌ Никогда не коммитируй:
- `.env` файл (только `.env.example`)
- `serviceAccountKey.json` (Firebase credentials)
- `node_modules/` (будет в .gitignore)
- Личные ключи и токены
- Пароли

✅ Коммитируй:
- Исходный код
- Тесты
- Конфиги (без конфидециальных данных)
- Документацию

---

## 🛠️ ПОЛЕЗНЫЕ КОМАНДЫ GIT

```bash
# Проверка статуса
git status

# История коммитов
git log --oneline -10

# Просмотр изменений
git diff
git diff --cached

# Отмена последнего коммита
git reset --soft HEAD~1

# Удаление веток
git branch -d branch_name

# Просмотр удаленных репо
git remote -v

# Обновление из GitHub
git pull origin main

# Просмотр веток
git branch -a
```

---

## 🐛 ЕСЛИ ЧТО-ТО ПОШЛО НЕ ТАК

### Ошибка: "fatal: remote origin already exists"

```bash
git remote remove origin
git remote add origin https://github.com/USERNAME/family-nutrition-app.git
```

### Ошибка: "Permission denied (publickey)"

```bash
# Проверь SSH ключ
ssh -T git@github.com

# Если не работает - используй HTTPS с Personal Access Token
git remote set-url origin https://github.com/USERNAME/family-nutrition-app.git
```

### Ошибка: Забыл добавить .gitignore перед коммитом

```bash
# Удали кешированные файлы
git rm -r --cached .
git add .
git commit -m "chore: Update .gitignore"
```

---

## 📊 BRANCHES STRATEGY

```
main (production-ready)
└── phase1-sprint1 (feature branch)
    └── phase1-sprint2
        └── phase2
```

**Процесс:**
1. Создаешь ветку для спринта
2. Claude Code коммитит туда
3. После завершения спринта → merge в main
4. Удаляешь ветку спринта

---

## 🔔 GITHUB NOTIFICATIONS

Рекомендуемые настройки для GitHub notifications:
- Settings → Notifications
- ☑️ Email notifications for pushes to your repositories
- ☑️ Email notifications for pull requests
- ☑️ Comments on pull requests

---

## 📱 РАБОТА С ТЕЛЕФОНА

### Mobile GitHub Apps

**Рекомендуемые приложения:**
- [GitHub Mobile (официальное)](https://github.com/mobile)
- [GitHub (by Copilot Labs)](https://github.com/apps/copilot-labs)

### Что можешь делать с телефона:
- ✅ Смотреть коммиты и изменения
- ✅ Читать инструкции из README/CLAUDE_INSTRUCTIONS
- ✅ Проверять PROGRESS
- ✅ Проверять CURRENT_TASK
- ❌ Писать код в редакторе (используй Claude Code)

### Рекомендуемый workflow с телефона:

1. Открываешь GitHub app
2. Проверяешь latest коммиты и PROGRESS.md
3. Открываешь Claude Code в браузере
4. Скопируешь CLAUDE_INSTRUCTIONS.md из GitHub
5. Вставляешь в Claude Code сессию
6. Claude Code пушит результаты обратно в GitHub

---

## 🎯 ИТОГОВЫЙ ЧЕКЛИСТ

- [ ] Создал репозиторий на GitHub
- [ ] Инициализировал Git локально (`git init`)
- [ ] Добавил все файлы (`git add .`)
- [ ] Создал первый коммит (`git commit -m "Initial commit"`)
- [ ] Добавил remote (`git remote add origin`)
- [ ] Пушнул на GitHub (`git push -u origin main`)
- [ ] Проверил что все файлы на GitHub
- [ ] Установил Git user.name и user.email
- [ ] Создал Personal Access Token (если используешь HTTPS)
- [ ] Готов к разработке с Claude Code ✅

---

## 🚀 НАЧИНАЙ РАЗРАБОТКУ

После настройки GitHub:

1. **В Claude Code:**
   - Открой репозиторий с GitHub
   - Скопируй CLAUDE_INSTRUCTIONS.md из GitHub
   - Вставь в Claude Code сессию

2. **Начни ФАЗУ 1 СПРИНТ 1:**
   - Посмотри CURRENT_TASK.md
   - Разрабатывай Задачи 1.1.1-1.1.4
   - Коммитируй каждые 30-60 минут

3. **После спринта:**
   - Claude Code обновит инструкции
   - Ты пулишь обновления
   - Переходишь на следующий спринт

---

**GitHub готов! Начинай разработку! 🎉**

Скопируй `CLAUDE_INSTRUCTIONS.md` из GitHub в Claude Code и начинай сессию!
