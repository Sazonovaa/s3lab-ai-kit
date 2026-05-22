# Cursor — вход для проекта

Перед любой задачей полностью следуй [`AGENTS.md`](AGENTS.md), расположенному рядом с этим `CURSOR.md`.

Path base: все относительные пути в этих инструкциях ([`AGENTS.md`](AGENTS.md), [`.ai/router.md`](.ai/router.md), [`.ai/skills/`](.ai/skills/), [`.ai/subagents/`](.ai/subagents/), [`.cursor/`](.cursor/)) разрешай относительно директории, где лежит этот `CURSOR.md`. Если этот файл открыт через submodule, используй `tiss.ai.kit.standart/` как базовую директорию.

Маршрутизация: прочитай [`.ai/router.md`](.ai/router.md) и выбери ровно один route — skill из [`.ai/skills/`](.ai/skills/) или subagent из [`.ai/subagents/`](.ai/subagents/).

Дополнительно для Cursor (IDE): [`.cursor/AGENTS.md`](.cursor/AGENTS.md), правила [`.cursor/rules/`](.cursor/rules/), хуки [`.cursor/hooks.json`](.cursor/hooks.json). Длинные процедуры не дублируй здесь — они в `.ai/skills/`.
