# Customization

Как переопределять правила, агентов и команды под конкретный проект, не редактируя
файлы kit'а.

## Три уровня override'ов

От мягкого к жёсткому.

### Уровень 1 — проектный контекст (стандартный путь)

Файл `.ai/project-context.md` импортируется в `CLAUDE.md` и читается всеми AI-инструментами.
Используйте его для:

- Краткого описания, что делает проект
- Списка сервисов и их назначения
- Локальных команд разработки
- Особенностей, которых нет в стандартном стеке kit'а
- Списка того, чего AI **не должен** делать в этом конкретном проекте

Пример раздела:

```markdown
## Project-specific deviations from kit standards

- В этом проекте используется MongoDB вместо PostgreSQL для сервиса аналитики.
  Правила postgres.md не применяются к `backend/services/analytics/`.
- Сервис legacy-billing использует .NET 8, не 10. Миграция запланирована на Q3.
- Frontend использует ngrx (классический), не Signals — миграция запланирована.
```

### Уровень 2 — override конкретного агента или правила

Файлы в `.ai/overrides/<name>.md` подхватываются автоматически: каждый kit-агент
в начале своего промпта читает `.ai/overrides/<self>.md`, если он есть.

Пример: проект отступает от backend-конвенций kit. Создаёте
`.ai/overrides/backend-dotnet.md`:

```markdown
# Project-specific overrides for backend-dotnet agent

В этом проекте:

- Не используем MediatR. Use cases вызываются напрямую из контроллеров.
- Не используем MassTransit — RabbitMQ через нативный RabbitMQ.Client.
  Контракты сообщений в `Shared.Contracts`.
- Тесты только xUnit без FluentAssertions (исторически).
```

Этот override **дополняет**, а не заменяет основной промпт агента. Агент сначала
читает kit-промпт, потом override, и при конфликте override побеждает.

### Уровень 3 — полная замена (escape hatch)

Если нужно полностью заменить kit-агента собственным:

```bash
# Удалить симлинк
rm .claude/agents/backend-dotnet.md

# Создать свой файл
cat > .claude/agents/backend-dotnet.md <<'EOF'
---
name: backend-dotnet
description: ...
tools: ...
model: sonnet
---

Свой собственный полный промпт.
EOF
```

Следующий `sync-ai-kit` увидит, что файл не симлинк, и:
- Сделает бэкап в `.claude/agents/backend-dotnet.md.bak`
- Заменит на kit-версию через симлинк
- Выведет warning

Чтобы запретить это поведение для конкретного файла — добавьте проверку в свой
проектный pre-sync hook (см. ниже) или просто не запускайте `sync-ai-kit` после
ручной замены, пока не решите, что делать с kit-версией.

## Когда какой уровень использовать

- **Уровень 1** — почти всегда. Большинство проектов отличаются мелочами:
  именами сервисов, портами, особенностями локального запуска.
- **Уровень 2** — когда конкретный агент должен вести себя иначе на этом проекте
  (например, не использует MediatR, или у вас Vue вместо Angular для одного фронта).
- **Уровень 3** — крайне редко. Если вы дошли до уровня 3, скорее всего:
  - Это сигнал, что в kit нужен новый агент или новое правило → улучшайте kit
  - Или этот проект настолько уникальный, что ему вообще не нужен kit

## Cursor: проектные правила

Можно добавлять свои правила в `.cursor/rules/`, но **не туда же, где симлинк
на kit** — добавляйте параллельно. Например, симлинк `.cursor/rules -> ../.ai-kit/cursor-rules`
указывает на директорию kit'а. Чтобы добавить проектное правило, не нарушая симлинк:

Вариант А — заменить симлинк на обычную директорию и положить файлы рядом:

```bash
rm .cursor/rules
mkdir .cursor/rules
# Симлинки на каждый kit-файл
for f in .ai-kit/cursor-rules/*.mdc; do
  ln -s "../../$f" ".cursor/rules/$(basename "$f")"
done
# Свои файлы поверх
cat > .cursor/rules/100-project.mdc <<'EOF'
---
description: Project-specific Cursor rules
alwaysApply: true
---

@.ai/project-context.md
EOF
```

Вариант Б — оставить симлинк на директорию и положить проектные правила в
поддиректорию (Cursor рекурсивен):

```bash
# .cursor/rules — симлинк на kit
mkdir -p frontend/.cursor/rules    # path-scoped — применяется только в frontend/
cat > frontend/.cursor/rules/100-project-frontend.mdc <<'EOF'
---
description: Frontend-specific overrides for this project
alwaysApply: false
globs:
  - "frontend/**/*.ts"
---

Тут проектные правила фронта.
EOF
```

Cursor читает все `.cursor/rules/` рекурсивно — поэтому путь в поддиректории
работает как path-scope в естественном виде.

## Pre-sync hook (опционально)

Если у вас часто бывают локальные модификации, которые `sync-ai-kit` затирает,
можно добавить проектный pre-sync hook. Просто создайте `.ai/pre-sync.sh`:

```bash
#!/usr/bin/env bash
# Запускается до sync-ai-kit (если вы его сами вызываете перед sync)
# Например, можно бэкапить локальные изменения в отдельную папку
echo "→ Pre-sync hook: backing up local mods"
mkdir -p .ai/local-backups
cp .claude/agents/*.md.bak .ai/local-backups/ 2>/dev/null || true
```

И запускайте как `.ai/pre-sync.sh && .ai-kit/bin/sync-ai-kit`. Kit ничего не знает
про этот hook — это чисто проектная штука.

## Что делать, если хочется внести правку, полезную всем проектам

Внесите её **в kit**, не в проект. Шаги:

1. Внутри `.ai-kit/`: `git checkout -b improve-reviewer-prompt`
2. Внесите изменения в нужный файл (например, `ai/agents/reviewer.md`)
3. Обновите `CHANGELOG.md` под `## [Unreleased]`
4. Закоммитьте, пушните, откройте PR в kit
5. После мержа и нового тега: в проектах сделайте
   `git submodule update --remote .ai-kit && .ai-kit/bin/sync-ai-kit`

Это золотое правило: **общие улучшения — в kit, проектная специфика — в `.ai/`.**
