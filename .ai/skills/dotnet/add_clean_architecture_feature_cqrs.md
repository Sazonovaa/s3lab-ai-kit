---
name: add-clean-architecture-feature-cqrs
description: >-
  Добавляет CQRS-фичу в существующий .NET Clean Architecture сервис:
  размещает файлы в Application по схеме Features/<Entity>/<Feature>/,
  использует MediatR, FluentValidation и Result pattern, не добавляет
  бизнес-логику в Api или Infrastructure.
triggers:
  - добавить фичу
  - новая cqrs feature
  - cqrs фича
  - MediatR handler
  - command handler
  - query handler
  - Features/
---

# Назначение
Добавить новую **CQRS-фичу** в существующий .NET Clean Architecture сервис без изменения каркаса solution и без смешивания бизнес-логики со слоями Api/Infrastructure.

# Когда применять
- Пользователь просит добавить command/query/use case в существующий сервис.
- Нужно создать `Command` или `Query`, `Handler`, `Validator` и связанные DTO/Result-типы.
- Нужно проверить, что фича лежит в `Application/Features/<Entity>/<Feature>/`.

# Входные данные
1. **Сервис**: путь к существующему сервису или его имя. Если сервисов несколько и пользователь не указал нужный — спросить.
2. **Entity**: бизнес-сущность, к которой относится фича. Если не указана — спросить.
3. **Feature**: конкретное действие или сценарий. Если не указано — спросить.
4. **Тип операции**: `Command` для изменения состояния или `Query` для чтения. Если не ясно — спросить.

# Порядок работы
1. Найти проекты `Application` и `Domain` выбранного сервиса.
2. Проверить существующую структуру `Application/Features/` и следовать локальному стилю.
3. Создать папку:

   ```text
   Features/
     <Entity>/
       <Feature>/
   ```

4. Для `Command` создать минимальный набор:
   - `<Feature>Command.cs`
   - `<Feature>CommandHandler.cs`
   - `<Feature>CommandValidator.cs`

5. Для `Query` создать минимальный набор:
   - `<Feature>Query.cs`
   - `<Feature>QueryHandler.cs`
   - `<Feature>QueryValidator.cs` — только если входные параметры требуют валидации.

6. Использовать MediatR для входной модели:
   - `IRequest<Result<T>>` или локальный эквивалент Result pattern;
   - не возвращать инфраструктурные DTO напрямую.

7. Валидацию входа размещать во FluentValidation validator.
8. Если нужен доступ к данным, использовать порт/интерфейс Application. Реализацию добавлять в Infrastructure только если пользователь явно попросил полный вертикальный срез.
9. Не создавать unit-тесты без прямой команды. Для тестов применять `.ai/skills/dotnet/dotnet_unit_tests_xunit_moq.md`.

# Формат вывода
1) **План**: сервис, entity, feature, тип операции, файлы в `Application/Features/<Entity>/<Feature>/`.
2) **Результат (Deliverable)**: созданные/изменённые файлы, используемые MediatR/Result/Validator-типы, новые порты Application при наличии.
3) **Самопроверка**: чеклист ниже.

# Планка качества (самопроверка)
- [ ] Фича лежит в `Application/Features/<Entity>/<Feature>/`, не плоско в `Features/`.
- [ ] Один файл содержит только один объект.
- [ ] Handler не зависит напрямую от Infrastructure.
- [ ] Api не содержит бизнес-логики.
- [ ] Валидация входа вынесена во FluentValidation validator.
- [ ] Result pattern используется по локальному стилю проекта.
- [ ] Unit-тесты не созданы без отдельного запроса.

# Анти-паттерны
- ❌ Создавать фичу плоско в `Application/Features/`.
- ❌ Размещать handler или бизнес-логику в Api.
- ❌ Подключать Infrastructure напрямую в Application handler через конкретные классы.
- ❌ Создавать несколько объектов в одном `.cs` файле.
- ❌ Добавлять тестовые сценарии без прямой команды пользователя.
