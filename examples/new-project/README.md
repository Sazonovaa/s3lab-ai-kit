# Examples

Эталонные проекты для проверки целостности kit'а после изменений.

## new-project/

Пустой проект, в который успешно встал kit. Используется как smoke-test:
если структура new-project/ соответствует ожидаемой после `sync-ai-kit`, kit
работает корректно.

### Запуск smoke-теста

```bash
cd /tmp
rm -rf ai-kit-smoke && mkdir ai-kit-smoke && cd ai-kit-smoke
git init -q --initial-branch=main
git submodule add /path/to/local/s3lab-ai-kit .ai-kit
.ai-kit/bin/sync-ai-kit

# Проверки
test -f CLAUDE.md || echo "FAIL: CLAUDE.md missing"
test -f AGENTS.md || echo "FAIL: AGENTS.md missing"
test -L .claude/agents || echo "FAIL: .claude/agents is not a symlink"
test -L .claude/commands || echo "FAIL: .claude/commands is not a symlink"
test -L .cursor/rules || echo "FAIL: .cursor/rules is not a symlink"
test -f .ai/project-context.md || echo "FAIL: .ai/project-context.md missing"

# Проверка, что симлинки указывают куда надо
[ "$(readlink .claude/agents)" = "../../.ai-kit/ai/agents" ] || echo "FAIL: wrong agents symlink"
[ "$(readlink .claude/commands)" = "../../.ai-kit/ai/commands" ] || echo "FAIL: wrong commands symlink"
[ "$(readlink .cursor/rules)" = "../.ai-kit/cursor-rules" ] || echo "FAIL: wrong cursor symlink"

# Идемпотентность — второй запуск не должен ничего ломать
.ai-kit/bin/sync-ai-kit
test -L .claude/agents || echo "FAIL: agents broken after re-sync"

echo "Smoke test passed."
```

При желании можно завернуть это в `bin/lib/smoke-test.sh` и запускать в CI самого kit'а.
