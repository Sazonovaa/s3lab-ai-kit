# Upgrade guide

Как мигрировать проекты между версиями s3lab-ai-kit.

## Семвер

- **PATCH** (0.1.0 → 0.1.1) — улучшения промптов, исправления опечаток.
  Безопасно обновляться вслепую.
- **MINOR** (0.1.0 → 0.2.0) — новые агенты, команды, правила.
  Безопасно, но прочитайте `CHANGELOG.md` — могут появиться новые возможности,
  которые вы хотите использовать.
- **MAJOR** (0.x.y → 1.0.0) — breaking change. Переименование агентов, удаление правил,
  изменение структуры. **Читайте этот гайд перед обновлением.**

## Стандартная процедура обновления (PATCH/MINOR)

```bash
cd ~/Projects/my-service

# 1. Подтянуть последний коммит kit
git submodule update --remote .ai-kit

# 2. Посмотреть, что изменилось
cd .ai-kit
git log --oneline HEAD@{1}..HEAD
cat CHANGELOG.md | head -50
cd ..

# 3. Запустить sync (идемпотентно, но обновит шаблоны при необходимости)
.ai-kit/bin/sync-ai-kit

# 4. Проверить, что симлинки на месте
ls -la .claude/agents .claude/commands .cursor/rules

# 5. Прогнать тестовый /feature на маленькой задаче, убедиться что агенты работают

# 6. Закоммитить bump
git add .ai-kit
git commit -m "chore: bump ai-kit to v$(cat .ai-kit/VERSION)"
```

## MAJOR обновления

MAJOR-версия означает breaking change. Алгоритм:

### Перед обновлением

1. **Завершите текущие in-flight задачи.** Не апгрейдьте kit в середине pipeline.
2. **Создайте ветку под апгрейд:**
   ```bash
   git checkout -b chore/upgrade-ai-kit-vX.0.0
   ```
3. **Прочитайте CHANGELOG.md в kit:** там перечислены конкретные breaking changes
   и инструкции для каждого.

### Во время обновления

1. Pin на новую версию:
   ```bash
   cd .ai-kit
   git fetch --tags
   git checkout vX.0.0
   cd ..
   ```

2. Запустите sync:
   ```bash
   .ai-kit/bin/sync-ai-kit
   ```

3. **Если в CHANGELOG.md указаны breaking changes — примените миграции в проекте:**

   Типичные случаи:

   - **Переименование агента**: проверьте `.ai/overrides/<old-name>.md` — если есть,
     переименуйте в `<new-name>.md`. Убедитесь, что в `docs/architecture.md` и
     других проектных доках старое имя не упоминается.
   - **Удаление правила**: если ваш проект полагался на удалённое правило,
     перенесите его в `.ai/overrides/` или в `.ai/project-context.md`.
   - **Изменение формата `.ai/project-context.md`**: следуйте инструкции в CHANGELOG.

4. **Прогоните полный smoke-test:**
   - `claude` → `/memory` → проверить, что все рулсы загрузились
   - `/agents` → проверить, что все агенты на месте
   - `/feature тестовая задача` → проверить, что пайплайн работает end-to-end
   - В Cursor: открыть TS-файл, убедиться, что `010-dotnet.mdc` не сработал, а
     `020-angular.mdc` сработал
   - Кодекс: `codex run "опиши проект"` — должен прочитать `AGENTS.md` и `.ai-kit/ai/core.md`

5. **Закоммитьте:**
   ```bash
   git add -A
   git commit -m "chore: upgrade ai-kit to vX.0.0

   Breaking changes applied:
   - <конкретные изменения, которые потребовались>
   "
   ```

### После обновления

- Откройте PR. Дайте время поработать пару дней.
- Если что-то ломается — откатывайте сначала pin'ом обратно, потом думайте, что не так:
  ```bash
  cd .ai-kit && git checkout v<previous-version> && cd ..
  .ai-kit/bin/sync-ai-kit
  ```

## История breaking changes

(заполняется по мере появления MAJOR-релизов)

### v1.0.0 → v2.0.0
(пока не релизилось)

## Что делать, если апгрейд сломал агента

1. Прочитайте `.ai-kit/CHANGELOG.md` — возможно, поведение агента изменилось намеренно.
2. Сравните diff конкретного агента:
   ```bash
   cd .ai-kit
   git diff v<old>..v<new> -- ai/agents/<name>.md
   ```
3. Если разница не подходит вам — создайте `.ai/overrides/<name>.md` с нужным поведением.
4. Если думаете, что это баг kit'а — заведите issue в репозитории kit'а.

## Что делать, если хочется откатиться

```bash
cd .ai-kit && git checkout v<previous-version> && cd ..
.ai-kit/bin/sync-ai-kit
git add .ai-kit && git commit -m "chore: revert ai-kit to v<previous-version>"
```

Так же безопасно, как и forward-обновление. Симлинки переподключатся автоматически.
