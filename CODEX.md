# Codex CLI — вход для проекта

Перед любой задачей полностью следуй [`AGENTS.md`](AGENTS.md), расположенному рядом с этим `CODEX.md`.

Path base: все относительные пути в этих инструкциях ([`AGENTS.md`](AGENTS.md), [`.ai/router.md`](.ai/router.md), [`.ai/skills/`](.ai/skills/), [`.ai/subagents/`](.ai/subagents/), [`.codex/`](.codex/)) разрешай относительно директории, где лежит этот `CODEX.md`. Если этот файл открыт через submodule, используй `s3lab-ai-kit/` как базовую директорию.

Маршрутизация: прочитай [`.ai/router.md`](.ai/router.md) и выбери ровно один route — skill из [`.ai/skills/`](.ai/skills/) или subagent из [`.ai/subagents/`](.ai/subagents/).

Дополнительно для Codex: [`.codex/config.toml`](.codex/config.toml), [`.codex/hooks.json`](.codex/hooks.json). Включение хуков — флаг `codex_hooks` в `config.toml` (см. документацию OpenAI Codex). Длинные процедуры не дублируй здесь — они в `.ai/skills/`.
