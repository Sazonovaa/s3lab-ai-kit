# Документация AI / стандартизация

| Документ | Назначение |
|----------|------------|
| [AI_STANDARDIZATION.md](AI_STANDARDIZATION.md) | Полный перенос плана: мультивендор, оси 1–11, схема каталогов, xUnit/Moq, хуки (AI + GitLab + Jira + вики), примеры конфигов |
| [../.ai/catalog.md](../../.ai/catalog.md) | Минимальный набор артефактов и владелец |
| [../.ai/policies/security_sdlc.md](../../.ai/policies/security_sdlc.md) | Данные, секреты, DoR/DoD |
| [../.ai/multi_vendor_tool_matrix.md](../../.ai/multi_vendor_tool_matrix.md) | Матрица Cursor / Claude / Codex |

Корневые входы для инструментов: [CURSOR.md](../../CURSOR.md), [CLAUDE.md](../../CLAUDE.md), [CODEX.md](../../CODEX.md) (дублировать смысл в `docs/ai/CODEX.md` не обязательно — достаточно корневого файла).

## Использование в стороннем проекте

Сторонний проект подключает `s3lab-ai-kit` как Git submodule и запускает синхронизацию из своего корня:

```cmd
.\s3lab-ai-kit\scripts\ai\sync-ai-kit.cmd
```

Скрипт обновляет submodule и создаёт в корне стороннего проекта `CURSOR.md`, `CLAUDE.md`, `CODEX.md`. Эти файлы являются entry-point файлами: они не копируют правила, а указывают AI-клиентам читать правила, skills, subagents, hooks и routing из `s3lab-ai-kit`.

Для проверки без записи файлов:

```cmd
.\s3lab-ai-kit\scripts\ai\sync-ai-kit.cmd --dry-run
```
