# Claude Code — вход для проекта

Перед любой задачей полностью следуй [`AGENTS.md`](AGENTS.md), расположенному рядом с этим `CLAUDE.md`.

Path base: все относительные пути в этих инструкциях ([`AGENTS.md`](AGENTS.md), [`.ai/router.md`](.ai/router.md), [`.ai/skills/`](.ai/skills/), [`.ai/subagents/`](.ai/subagents/), [`.claude/`](.claude/)) разрешай относительно директории, где лежит этот `CLAUDE.md`. Если этот файл открыт через submodule, используй `s3lab-ai-kit/` как базовую директорию.

Маршрутизация: прочитай [`.ai/router.md`](.ai/router.md) и выбери ровно один route — skill из [`.ai/skills/`](.ai/skills/) или subagent из [`.ai/subagents/`](.ai/subagents/).

Дополнительно для Claude Code: проектные хуки и настройки в [`.claude/`](.claude/) (при наличии). Длинные процедуры не дублируй здесь — они в `.ai/skills/`.
