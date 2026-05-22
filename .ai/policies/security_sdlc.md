# Security & data policy (AI + SDLC)

## Purpose
Единые правила для любого AI-клиента (Cursor, Claude Code, Codex и др.): что **нельзя** попадать в промпты, логи и внешние сервисы; как встроить проверки в **DoR/DoD** и **PR**.

## Data classes (non-exhaustive)
| Class | Examples | In AI prompts / logs |
|-------|-----------|----------------------|
| **Secrets** | API keys, JWT signing keys, connection strings with password, PAT, `AWS_SECRET_*`, private PEM | **Never** — redact or use placeholders |
| **PII** | Имена клиентов, email, телефоны, адреса, ИНН там, где это не нужно задаче | Minimize; anonymize (`user_123`); ссылка на тикет без полного текста переписки |
| **Internal URLs** | prod/stage internal hostnames, VPN-only endpoints | Avoid unless ticket explicitly requires |
| **Customer production data** | DB dumps, spreadsheets with real users | **Never** — use fixtures / synthetic |

## DoR (Definition of Ready) — optional bullets for AI-assisted work
- [ ] В тикете указаны **границы** задачи и **acceptance criteria** без вложения секретов.
- [ ] Если нужен контекст продакшена — только **описание** или **схема**, не дампы.
- [ ] Выбран skill по `.ai/router.md` (или явно указан пользователем).

## DoD (Definition of Done)
- [ ] Нет новых секретов в репозитории (ключи только через vault/CI variables).
- [ ] PR не содержит закоммиченных `.env` с реальными значениями.
- [ ] Для изменений в data layer: при необходимости пройден чеклист `repository_layer_audit` (см. skill).
- [ ] Модульные тесты: **xUnit + Moq**; без поднятия реальной БД в unit-тестах без отдельного согласования.

## PR template (see `.github/pull_request_template.md`)
Автор отмечает соответствие этой политике и ссылки на тикет.

## Incident response (short)
Если секрет утёк в чат/лог: **ротировать ключ**, удалить из истории по процессу команды, зафиксировать инцидент.

## References
- Корпоративные политики ИБ (вставить ссылку на Confluence при наличии).
- Репозиторий: `.ai/router.md`, `.cursor/hooks` (пилот guard на shell).
