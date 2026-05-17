# Codex CLI — вход для проекта

Перед любой задачей в этом репозитории **полностью следуй корневому [`AGENTS.md`](AGENTS.md)** (маршрутизация через [`.ai/router.md`](.ai/router.md): ровно один route — skill из [`.ai/skills/`](.ai/skills/) или subagent из [`.ai/subagents/`](.ai/subagents/)).

Дополнительно для Codex: [`.codex/config.toml`](.codex/config.toml), [`.codex/hooks.json`](.codex/hooks.json). Включение хуков — флаг `codex_hooks` в `config.toml` (см. документацию OpenAI Codex). Длинные процедуры не дублируй здесь — они в `.ai/skills/`.
