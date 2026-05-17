---
name: geo-distribution
description: Конвенции гео-распределения для .NET сервисов TISS.AI.KIT: UTC, локализация, RabbitMQ, PostgreSQL, MinIO, compliance и latency.
triggers:
  - geo distribution
  - гео-распределение
  - мультирегион
  - timezone
  - rabbitmq federation
  - minio replication
  - data residency
---

# Назначение
Дать обязательный контекст для проектирования, реализации и ревью сервисов, которые работают в нескольких странах или регионах.

# Когда использовать
- Сервис хранит или передаёт пользовательские данные между регионами.
- Изменение затрагивает RabbitMQ, PostgreSQL, MinIO, external API или regional settings.
- Нужно оценить ADR, MR/PR или архитектурный план на geo-impact.

# Timezones
- Все persisted timestamps хранить в UTC.
- Конвертацию в локальную timezone делать только на границе отображения или внешнего контракта.
- Не использовать `DateTime.Now` в доменной и application-логике; передавать время через clock abstraction, если логика зависит от времени.
- В API явно документировать timezone для входных и выходных дат.

# Localization
- Не хранить hardcoded пользовательские строки в доменной логике.
- Использовать resource files или согласованный механизм локализации.
- Для каждого пользовательского текста должен быть fallback на язык по умолчанию.
- Error codes должны быть стабильными и не зависеть от языка сообщения.

# RabbitMQ
- Routing keys должны явно отражать bounded context, event type и при необходимости регион.
- Consumers должны быть идемпотентными: повторная доставка не должна ломать состояние.
- Ошибки должны уходить в retry/DLQ по явной политике.
- Для cross-region messaging заранее выбрать federation или shovel и описать trade-offs.
- Не полагаться на ordering между регионами без отдельного архитектурного решения.

# PostgreSQL
- Региональные connection strings задавать через env/config, не hardcode.
- Учитывать replication lag при чтении из replica.
- FK и поля фильтрации по tenant/region должны иметь индексы.
- Миграции должны быть идемпотентными и безопасными для rolling deploy.
- Sharding или partitioning strategy фиксировать в ADR до реализации.

# MinIO
- Bucket naming должен учитывать environment и регион.
- Presigned URLs должны иметь минимально достаточный expiry.
- Прямой публичный доступ к bucket/object запрещён без отдельного security review.
- Lifecycle и replication policies должны быть описаны рядом с infrastructure configuration.
- Object keys не должны раскрывать PII или внутреннюю структуру tenant без необходимости.

# Compliance
- Данные EU-резидентов не перемещать за пределы разрешённого региона без legal/compliance решения.
- PII не передавать в logs, prompts, metrics labels и object keys.
- Для cross-region transfer фиксировать основание, тип данных и срок хранения.

# Latency and resilience
- Cross-region HTTP/gRPC вызовы должны иметь timeout, retry policy и circuit breaker.
- Timeout нельзя копировать из локального сценария без оценки latency.
- Для деградации региона должен быть описан fallback или явный отказ.
- Background jobs должны быть безопасны к повторному запуску после partial failure.

# Формат вывода
1) **Geo-impact:** `none` | `low` | `medium` | `high`
2) **Затронутые регионы/данные**
3) **Риски:** timezone, localization, messaging, storage, compliance, latency
4) **Обязательные правки**
5) **Проверки**

# Планка качества
- [ ] Нет hardcoded regional values.
- [ ] Persisted timestamps остаются UTC.
- [ ] RabbitMQ consumers идемпотентны.
- [ ] PostgreSQL миграции и индексы проверены.
- [ ] MinIO access не раскрывает прямой публичный доступ.
- [ ] Compliance/data residency явно оценены.
