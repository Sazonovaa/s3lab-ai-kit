# Multi-repo → monorepo migration

s3lab-ai-kit предполагает monorepo. Если ваши backend и frontend сейчас живут в
отдельных репозиториях, этот гайд проведёт через консолидацию с сохранением истории.

## Зачем

Главный pipeline kit'а (`/feature`) опирается на **атомарность изменений между
backend и frontend**:

- Оркестратор должен видеть оба слоя в одной сессии, чтобы декомпозировать задачу
- `api-contract` агент меняет OpenAPI на бэке и регенерирует TypeScript-клиент на
  фронте — это должен быть один коммит, иначе контракт временно битый
- Ревью изменений идёт в одном PR, а не в трёх скоординированных

При multi-repo каждое из этих требований превращается в координационный кошмар:
3 PR на задачу, ручная синхронизация submodule pin'ов, риск рассинхрона.

## Алгоритм миграции

### Шаг 0 — подготовка

```bash
# Закройте все открытые PR в обеих репах. Смержите или закройте.
# Убедитесь, что main у обеих реп зелёный.
# Сделайте бэкап (просто склонируйте обе репы в отдельную папку).
```

### Шаг 1 — создать новую monorepo

```bash
mkdir my-product && cd my-product
git init -b main

# Первый коммит — пустой, нужен чтобы subtree merge сработал
git commit --allow-empty -m "chore: initial commit"
```

### Шаг 2 — втянуть backend через subtree

```bash
# Локальный путь или URL — оба работают
git remote add backend-src ~/path/to/backend-repo
git fetch backend-src

# subtree add подтягивает всю историю под префиксом backend/
git subtree add --prefix=backend backend-src main

# Снять временный remote
git remote remove backend-src
```

Проверьте, что история сохранилась:
```bash
git log --oneline -- backend/ | head -20
```
Должны быть видны старые коммиты backend.

### Шаг 3 — втянуть frontend

```bash
git remote add frontend-src ~/path/to/frontend-repo
git fetch frontend-src
git subtree add --prefix=frontend frontend-src main
git remote remove frontend-src
```

### Шаг 4 — подключить ai-kit

```bash
git submodule add git@github.com:s3lab/s3lab-ai-kit.git .ai-kit
.ai-kit/bin/sync-ai-kit
```

### Шаг 5 — починить пути

Большинство файлов будут работать как есть, потому что они лежат внутри
`backend/` или `frontend/` и ссылаются на относительные пути. Но проверьте:

- **Pipeline workflows** (`.github/workflows/`) — пути в `paths:` фильтрах
- **Docker compose** — пути билд-контекстов: `context: ./backend/services/orders`
- **CI скрипты** — `working-directory: backend` вместо корня
- **README** — обновите ссылки, инструкции по запуску
- **Symlinks / относительные импорты** между слоями — если такие были

### Шаг 6 — заполнить project-context.md

```bash
$EDITOR .ai/project-context.md
```

Опишите:
- Что делает продукт
- Список backend-сервисов в `backend/services/`
- Особенности проекта (deviation от kit-стандартов)

### Шаг 7 — initial commit и push

```bash
git add -A
git commit -m "chore: consolidate backend + frontend + ai-kit into monorepo"

gh repo create s3lab/my-product --private --source=. --remote=origin
git push -u origin main
```

### Шаг 8 — заархивировать старые репы

```bash
gh repo archive s3lab/old-backend
gh repo archive s3lab/old-frontend
```

Архив, не удаление. История остаётся read-only и доступна для исторических справок.

## Проверка после миграции

```bash
# История бэка сохранилась?
git log --follow backend/services/<name>/src/Program.cs | head

# История фронта сохранилась?
git log --follow frontend/package.json | head

# CI собирается?
gh workflow run ci-backend
gh workflow run ci-frontend

# Локально работает?
docker compose up -d
cd backend/services/<name> && dotnet build
cd ../../../frontend && npm install && npm run build
```

## Path-based CI: backend и frontend как "независимые модули"

Часто аргумент против monorepo — "хочу деплоить backend и frontend отдельно".
В monorepo это решается через path-filter в workflows. Шаблоны kit'а уже это делают:

```yaml
# .github/workflows/ci-backend.yml
on:
  push:
    paths:
      - 'backend/**'
      - '.github/workflows/ci-backend.yml'
```

Изменение только в `frontend/` — backend CI не запустится. Деплой бэка не сработает,
если не было изменений в бэке. Эффективно — те же независимые pipeline'ы, что и в
multi-repo, но без координации submodule pin'ов.

## А что если миграцию делать нельзя

Если у вас жёсткое требование сохранить раздельные репозитории — есть два менее
удобных варианта:

### Meta-repo с тремя submodules

```
my-product-meta/                   (новая мета)
├── backend/    (submodule)
├── frontend/   (submodule)
└── .ai-kit/    (submodule)
```

AI-инструменты работают в корне меты, видят все три проекта. Минусы:
- Каждая задача — 3 PR (back, front, мета bump)
- Submodule pin'ы можно забыть обновить
- Rollback через submodule сложнее

Если идёте этим путём — в `.ai/project-context.md` явно зафиксируйте multi-repo
особенности, чтобы оркестратор знал.

### kit отдельно в каждой репе

```
backend-repo/
└── .ai-kit/    (submodule)

frontend-repo/
└── .ai-kit/    (submodule)
```

**Этот вариант ломает главный pipeline.** Оркестратор не сможет координировать
back и front в одной сессии. `api-contract` не сможет атомарно обновить spec и
client. Pipeline `/feature` не сработает в его текущем виде.

Подходит только если задачи **в принципе** не пересекают границу back/front
(что для веб-продукта почти не встречается).
