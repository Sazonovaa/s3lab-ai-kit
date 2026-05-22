# Schema: frontmatter единого описания AI-kit

Формальная спецификация источника, из которого `scripts/ai/build-ai-kit.mjs`
генерирует нативные артефакты вендоров. Источник правды — frontmatter каждого
`.md` в каталогах ниже. Сгенерированные файлы помечены `DO NOT EDIT`.

## Источники и kind
| Каталог | kind по умолчанию | Обязателен frontmatter | Проекция |
|---------|-------------------|------------------------|----------|
| `.ai/subagents/**` | `subagent` | да | `.claude/agents`, `.cursor/skills`, router, индексы |
| `.ai/skills/**` | `skill` | да | `.claude/skills`, `.cursor/skills`, router, индексы |
| `.ai/policies/**` | `policy` | нет (`optional`) | router, индексы (НЕ нативные skills) |
| `.ai/rules/**` | `rule` | да | `.cursor/rules/*.mdc` (НЕ router/индексы) |

`optional`: файл без frontmatter (например `security_sdlc.md`) пропускается, а не
ломает сборку. Поле `kind` во frontmatter переопределяет kind каталога.

## Поля frontmatter
| Поле | Тип | Для kind | Обяз. | Назначение |
|------|-----|----------|-------|------------|
| `name` | string (kebab `^[a-z0-9](-[a-z0-9])*$`) | все | да | Имя артефакта/файла; нормализуется (`_`/пробел → `-`). |
| `description` | string (можно folded `>-`) | все | да | Матчинг маршрута; в Claude/Cursor — поле `description`. |
| `triggers` | list[string] | skill, subagent, policy | нет | Ключевые фразы для выбора маршрута. |
| `kind` | `subagent`/`skill`/`policy`/`rule` | все | нет | Переопределяет kind каталога. |
| `model` | `heavy`/`standard`/`light` | subagent | нет | Класс модели → Claude `model` (heavy→opus, standard→sonnet, light→haiku). |
| `tools` | list[string] | subagent | нет | Allowlist инструментов для Claude-агента. |
| `globs` | string \| list[string] | rule | да для rule | Path-scope для `.cursor/rules/*.mdc`. |
| `always_apply` | bool | rule | нет | `alwaysApply` в `.mdc` (по умолчанию `false`). |
| `vendor_overrides` | map | все | нет | Зарезервировано для точечных vendor-исключений. |

Прочие ключи → предупреждение «неизвестное поле».

## Матрица проекции (kind → выход)
| kind | `.claude/agents` | `.claude/skills` | `.cursor/skills` | `.cursor/rules` | router + индексы |
|------|:---:|:---:|:---:|:---:|:---:|
| subagent | ✅ | — | ✅ | — | ✅ |
| skill | — | ✅ | ✅ | — | ✅ |
| policy | — | — | — | — | ✅ |
| rule | — | — | — | ✅ | — |

Индексы: `.ai/routes.generated.md`, таблица в `.ai/router.md` (блок `AIKIT:ROUTES`),
секция в `AGENTS.md` (блок `AIKIT:INDEX`).

## Валидация
**Ошибки (валят сборку, exit 1):**
- отсутствует `name` или `description` (для не-`optional` источников);
- `name` не соответствует `^[a-z0-9](-[a-z0-9])*$`;
- дубль `name` между любыми записями (skill+subagent делят namespace `.cursor/skills`).

**Предупреждения (не валят):**
- неизвестное поле frontmatter;
- `model` вне `{heavy, standard, light, opus, sonnet, haiku, inherit}`;
- `rule` без `globs`;
- `description` длиннее 1000 символов;
- дубли `triggers` внутри записи (без учёта регистра);
- один триггер у нескольких маршрутов.

## Команды
```cmd
node scripts\ai\build-ai-kit.mjs          :: сборка
node scripts\ai\build-ai-kit.mjs --check  :: drift-гейт (CI / pre-commit)
node scripts\ai\build-ai-kit.mjs --out .  :: проекция в корень проекта-потребителя
```

Добавление/изменение skill — через [`.ai/skills/engineering/create_skill.md`](skills/engineering/create_skill.md).
