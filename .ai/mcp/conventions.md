---
name: mcp-conventions
description: >-
  Конвенции работы с MCP-серверами: transport, секреты, синхронизация
  между vendor-конфигами (.claude / .cursor / .codex), безопасность.
metadata:
  type: conventions
---

# Конвенции MCP

## Назначение

Правила, которые держат [`.ai/mcp/servers.md`](servers.md) и vendor-конфиги
(`.claude/settings.json`, `.cursor/mcp.json`, `.codex/config.toml`)
консистентными между собой.

> Сам список одобренных серверов → [`servers.md`](servers.md)
> Процедура добавления нового   → [`.ai/skills/engineering/configure_mcp_server.md`](../skills/engineering/configure_mcp_server.md)

---

## Поток правды

```
.ai/mcp/servers.md  ──┬──→  .claude/settings.json  (mcpServers)
   (источник)         ├──→  .cursor/mcp.json
                      └──→  .codex/config.toml     ([mcp_servers.<id>])
```

- **Никогда** не добавлять сервер сразу в vendor-конфиг. Сначала — запись в
  `servers.md` через MR + ревью Tech Lead, затем синхронизация во все три
  vendor-файла **одним PR**.
- Имя сервера (`id`) одинаково во всех трёх клиентах. Расхождение — баг.
- Статусы записей в `servers.md`: `✅ Approved` (рабочий, синхронизирован во
  все vendor-конфиги), `🚧 Planned` (согласован, но нет реализации — vendor-
  конфиги **не** заполнять), `⚠️ Limited` (поддерживает не все три клиента —
  перечислить поддерживаемые), `🔴 Deprecated` (вывод из эксплуатации). Полная
  легенда — в [`servers.md`](servers.md).

---

## Transport

- **stdio** — по умолчанию. Для всех серверов из стартового набора.
- **HTTP / SSE** — только если сервер не имеет stdio-реализации; обязательно
  указывать `url` и authentication в `servers.md`.
- **TCP / sockets** — запрещены без отдельного обсуждения с Tech Lead.

---

## Секреты

### Правила

1. **Никогда** не коммитить реальные API-ключи / PAT / connection strings в
   vendor-конфиги. Только placeholder `${VAR_NAME}`.
2. Реальные значения — в `~/.env` разработчика **или** Windows Credential
   Manager **или** менеджере секретов команды. Не в репозитории.
3. Vendor-конфиг должен парситься даже когда env-переменная пустая — MCP
   просто не стартует. Никаких "если ключа нет, подставим default".
4. PAT и API-ключи проходят политику ротации: GitHub PAT — раз в 90 дней,
   облачные ключи — по политике вендора, но не реже 180 дней.

### Допустимые формы placeholder'а

| Клиент      | Форма                       | Пример                                              |
|-------------|-----------------------------|-----------------------------------------------------|
| Claude Code | `${VAR}` в `env`            | `"GITHUB_PERSONAL_ACCESS_TOKEN": "${GH_PAT}"`       |
| Cursor      | `${VAR}` в `env`            | `"GITHUB_PERSONAL_ACCESS_TOKEN": "${GH_PAT}"`       |
| Codex       | `env = { VAR = "${ENV}" }`  | `env = { GITHUB_PERSONAL_ACCESS_TOKEN = "${GH_PAT}" }` |

### Что делать при утечке

Действовать по разделу 7 [`ai-usage-policy.md`](../policies/ai-usage-policy.md)
и процессу из `security_sdlc.md`: немедленно ротировать ключ, зафиксировать
инцидент, провести post-mortem.

---

## Совместимость с secret-guard

Hook `secret-guard.mjs` блокирует подозрительные shell-команды. MCP-серверы
обходят shell — это **их преимущество, не уязвимость**, потому что:

- MCP-команды стартуют через JSON-конфиг, без интерпретации shell-метасимволов.
- В env передаётся **значение переменной**, а не строка `Password=...`.

Однако: **не размещать** секреты в `args` MCP-сервера. Только в `env`.

---

## Read-only по умолчанию

- Любой новый сервер регистрируется как `write: no`, если PR явно не
  обосновывает обратное.
- Серверы с правом записи (`filesystem`, `github`, `memory`) проходят
  отдельный security-review:
  - какой минимальный whitelist путей / scope PAT нужен;
  - что произойдёт при ошибочном вызове агентом.

---

## Запрещённые серверы

Без согласования Tech Lead **не** подключать:

- MCP-серверы с доступом к prod-БД (даже read-only) — данные клиентов под
  152-ФЗ / KZ.
- MCP-серверы для отправки сообщений (Slack, Email, Telegram) от имени
  пользователя — высокий риск спама и непреднамеренных рассылок.
- MCP-серверы для управления инфраструктурой (kubectl, terraform,
  cloud-provider) — кросс-домен с CI/CD, blast radius огромный.
- MCP-серверы из непроверенных репозиториев (< 50 stars, нет последних
  релизов, нет CI). Дополнить такие пакеты в [`security_sdlc.md`](../policies/security_sdlc.md).

---

## Версионирование

- Версии MCP-пакетов **фиксируются** в vendor-конфиге через `@version` либо
  через lockfile разработчика (`package-lock.json` для npx-серверов).
- При апгрейде версии — отдельный PR с changelog'ом сервера в описании.

---

## Sync-скрипт (опционально, Фаза 2)

В будущем `scripts/ai/sync-mcp.cmd` сгенерирует vendor-конфиги из `servers.md`
автоматически. До тех пор — ручная синхронизация по чеклисту в
[`.ai/skills/engineering/configure_mcp_server.md`](../skills/engineering/configure_mcp_server.md).

---

## Чеклист консистентности (для ревью PR)

- [ ] Запись в `.ai/mcp/servers.md` существует и заполнена полностью.
- [ ] Один и тот же `id` во всех трёх vendor-конфигах.
- [ ] Секреты — только через `${ENV_VAR}`, реальных значений в diff нет.
- [ ] Если `write: yes` — в PR есть обоснование.
- [ ] При новом transport != stdio — указан в `servers.md`.
- [ ] PAT/API-ключи имеют минимально необходимый scope.
