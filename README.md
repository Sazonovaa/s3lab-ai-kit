# s3lab-ai-kit

`s3lab-ai-kit` — Claude Code plugin marketplace для команды s3lab/TISS. Стандартные политики, skills, subagents и hooks упакованы в плагины и подключаются через `/plugin install`.

Репозиторий нужен, чтобы все AI-инструменты команды работали по одним правилам: соблюдали security policy, выполняли обязательный review flow и не зависели от устных договорённостей.

## Marketplace (Claude Code)

Manifest лежит в `.claude-plugin/marketplace.json`. Плагины разложены по доменам в `plugins/<имя>/`. Плагин `s3lab-policy` обязателен — устанавливайте его первым в каждом проекте: его `SessionStart` hook автоматически ставит `pre-commit` и `pre-push` с `gitleaks`-сканером в репозитории, где открыта сессия Claude Code. Остальные плагины опциональны и устанавливаются по нужде; полностью оформлен только демо-плагин `s3lab-engineering` (заглушка skill + slash-команда), `s3lab-dotnet`/`s3lab-product`/`s3lab-testing`/`s3lab-research`/`s3lab-writing` — пустые скелеты.

Установка локально:

```text
/plugin marketplace add /Users/saa/Projects/s3lab/s3lab-ai-kit
/plugin install s3lab-policy@s3lab
/plugin install s3lab-engineering@s3lab
```

Что включает baseline (`s3lab-policy`):

- `pre-commit` и `pre-push` блокируют коммит/push с найденным secret через `gitleaks` (~150 встроенных правил).
- Per-repo allowlist в `.s3lab-policy/gitleaks.toml` — коммитится в репо, фиксирует командные договорённости по false positives.
- Slash-команда `/policy-status` показывает текущее состояние защиты.
- Skill `secrets-incident-response` — runbook на случай, когда secret уже попал в историю.
- `gitleaks` ставится автоматически через `brew install gitleaks`, если его нет.

Доступные плагины:

- `s3lab-policy` — Обязательный baseline: secrets-guard на git pre-commit/pre-push, общие правила для всех s3lab-проектов.
- `s3lab-engineering` — Engineering skills, agents, commands and hooks for s3lab team workflows.
- `s3lab-dotnet` — .NET 10 backend skills and agents (Clean Architecture, CQRS, infrastructure). *skeleton*
- `s3lab-product` — Product skills: PRD/MVP preparation, sprint acceptance criteria. *skeleton*
- `s3lab-testing` — Testing skills and agents for web/e2e/UI and unit-test guidance. *skeleton*
- `s3lab-research` — Research skills: competitors, technologies, market analysis. *skeleton*
- `s3lab-writing` — Writing skills: structure and tone for technical articles (Habr/VC). *skeleton*
- `s3lab-loop` — Goal-driven research-draft-critique-refine loop orchestrator. *experimental*

## Обязательные правила для команды

- Изменения в плагинах (`plugins/**`), marketplace manifest и политиках проходят через MR + review.
- Secrets, токены, private keys, connection strings с паролями, production dumps и PII нельзя отправлять в AI prompts, logs и telemetry.
- AI-assisted Code Review обязателен перед push и перед merge в `develop` или `main`.
- Для .NET unit-тестов используется `xUnit + Moq`; NUnit не добавлять.
- Для backend API по умолчанию использовать порт `5001`, если задача требует локального запуска сервера.
- Для geo-sensitive задач учитывать UTC, data residency, RabbitMQ DLQ/retry, PostgreSQL индексы и MinIO access policy.

## Документация

- [`docs/review/CODE_REVIEW.md`](docs/review/CODE_REVIEW.md) — стандарт code review (приоритеты, архитектура, ambient-зависимости, стиль, тесты, формат).
- [`docs/superpowers/`](docs/superpowers/) — specs и плановые документы по плагинам marketplace.
