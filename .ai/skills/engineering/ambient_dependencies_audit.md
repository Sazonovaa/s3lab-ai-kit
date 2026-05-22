---
name: ambient-dependencies-audit
description: >-
  Аудит прямых обращений к недетерминистичным / ambient API
  (`DateTime.UtcNow`, `Guid.NewGuid`, `Random`, `Environment.*`, `File.*`,
  `CultureInfo.Current*`, прямой `HttpClient`) в production-коде и обязательная
  замена на port-интерфейс для возможности мокирования в xUnit + Moq.
triggers:
  - DateTime.UtcNow
  - DateTime.Now
  - DateTimeOffset.UtcNow
  - DateTimeOffset.Now
  - Guid.NewGuid
  - new Random
  - Random.Shared
  - Environment.GetEnvironmentVariable
  - Environment.MachineName
  - Environment.UserName
  - File.ReadAllText
  - File.WriteAllText
  - Directory.GetFiles
  - CultureInfo.CurrentCulture
  - HttpClient new
  - ClaimsPrincipal.Current
  - Thread.CurrentPrincipal
  - ambient dependencies
  - ambient api
  - non-determinism
  - недетерминизм
  - изолировать время
  - изолировать guid
  - IClock
  - IGuidProvider
  - IRandomProvider
  - IFileSystem
  - IEnvironmentProvider
  - ICultureProvider
  - ICurrentUserProvider
  - port abstraction
  - clock abstraction
  - BannedApiAnalyzers
  - BannedSymbols
---

# Назначение
Проверить, что в production-коде (Domain, Application, Infrastructure handlers и services) **нет прямых обращений** к недетерминистичным / ambient API. Любая такая зависимость должна быть скрыта за **port-интерфейсом**, реализация которого живёт в Infrastructure-адаптере. Это обязательное условие, чтобы зависимость можно было замокать в unit-тестах через `Mock<T>` ([dotnet_unit_tests_xunit_moq.md](../dotnet/dotnet_unit_tests_xunit_moq.md)).

# Когда применять
- Ревью diff'а: затронуты handler, service, validator, доменная сущность, доменный сервис.
- Подготовка к написанию unit-тестов для существующего класса: видишь в SUT прямой вызов ambient API — сначала рефакторинг, потом тест.
- При работе с любым кодом, где встречаются ключевые слова из `triggers`.
- При разборе нестабильного теста, который «иногда падает».

# Что считать нарушением

## Запрещённые API → обязательный port-интерфейс

| Прямой вызов в production | Port-интерфейс | Где разрешена реальная реализация |
|---|---|---|
| `DateTime.UtcNow`, `DateTime.Now`, `DateTimeOffset.UtcNow`, `DateTimeOffset.Now` | `IClock` (или `TimeProvider` из BCL .NET 8+) | `SystemClock : IClock` в Infrastructure |
| `Guid.NewGuid()`, `Guid.CreateVersion7()` | `IGuidProvider` | `GuidProvider : IGuidProvider` в Infrastructure |
| `new Random()`, `Random.Shared.*` | `IRandomProvider` | `RandomProvider : IRandomProvider` в Infrastructure |
| `Environment.GetEnvironmentVariable`, `Environment.MachineName`, `Environment.UserName`, `Environment.ProcessId`, `Environment.CurrentDirectory` | `IOptions<T>` (через configuration binding) или `IEnvironmentProvider` | биндинг в `Program.cs` / `Startup` |
| `File.*`, `Directory.*`, `Path.GetTempFileName`, `Path.GetTempPath` | `IFileSystem` | `SystemFileSystem : IFileSystem` в Infrastructure |
| `CultureInfo.CurrentCulture`, `CultureInfo.CurrentUICulture` | `ICultureProvider` или явный параметр метода | `CultureProvider : ICultureProvider` в Infrastructure |
| `new HttpClient(...)`, прямой `HttpClient` | `IHttpClientFactory` + типизированный клиент с интерфейсом (`IMyApiClient`) | DI-регистрация `AddHttpClient<IMyApiClient, MyApiClient>()` |
| `Thread.CurrentPrincipal`, `ClaimsPrincipal.Current` | `ICurrentUserProvider` | `HttpCurrentUserProvider : ICurrentUserProvider` в Infrastructure (через `IHttpContextAccessor`) |
| `Stopwatch.GetTimestamp()` внутри бизнес-логики | `IClock` (выдать два snapshot времени) | `SystemClock : IClock` |

## Исключения (нарушением **не** являются)
- Реализация самого адаптера в Infrastructure: `SystemClock`, `GuidProvider`, `SystemFileSystem` и т. п. — единственное легитимное место для прямого вызова.
- `Program.cs` / `Startup` / DI-биндинг: `builder.Configuration.GetValue<string>("...")`, регистрация `HttpClient`, регистрация `TimeProvider.System`.
- Миграции БД, генераторы кода, скрипты `tools/`, тестовые билдеры — вне зоны аудита.
- Логирование через `ILogger<T>` (внутри Serilog enricher время берётся отдельно, это не SUT).

# Процедура
1) Определить границу аудита: changed files в diff'е, либо указанный класс / папка.
2) Прогнать по списку запрещённых символов (см. таблицу). Поиск по конкретным сигнатурам, а не по подстроке: `DateTime.UtcNow`, `DateTime.Now`, `Guid.NewGuid(`, `new Random(`, `Random.Shared`, `Environment.GetEnvironmentVariable`, `Environment.MachineName`, `File.`, `Directory.`, `CultureInfo.Current`, `new HttpClient(`, `ClaimsPrincipal.Current`, `Thread.CurrentPrincipal`.
3) Для каждого попадания зафиксировать: путь + строка, тип нарушения, целевой port-интерфейс, есть ли уже подходящий port в проекте.
4) Если в проекте **уже есть** port-интерфейс (например, `IClock`) — нарушение требует только заменить вызов и пробросить зависимость через конструктор.
5) Если port'а **нет** — добавить шаг «создать port-интерфейс в Application/Abstractions + адаптер в Infrastructure + регистрация в DI».
6) Проверить файл, на который ссылается каждое нарушение: это **не** Infrastructure-адаптер этого же port'а (иначе попадание ложное — исключение).
7) Не переписывать код целиком — только аудит и план рефакторинга. Само исправление — отдельным PR / шагом по согласованию.

# Формат вывода
1) **Verdict:** `clean` | `needs_refactor`
2) **Findings** (список нарушений):
   - `Path/To/File.cs:LINE` — `<вызов>` — целевой port `<IName>` — port `существует` | `нужно создать`
3) **Refactor plan** (обязательно при `needs_refactor`):
   - Для каждого port'а: интерфейс (пример сигнатуры), реализация-адаптер (путь в Infrastructure), регистрация в DI, список конструкторов, в которые он пробрасывается.
   - Порядок шагов (1..n) минимальными PR.
4) **Tests:** какие зависимости в новых unit-тестах мокать (`Mock<IClock>`, `Mock<IGuidProvider>`, ...) и какие assertion'ы это разблокирует (детерминистичные `CreatedAtUtc`, `Id`, `CorrelationId`).

# Планка качества (самопроверка)
- [ ] Каждое нарушение привязано к конкретному файлу и строке.
- [ ] Для каждого нарушения указан целевой port-интерфейс из таблицы выше.
- [ ] Учтены исключения: Infrastructure-адаптер этого же port'а, `Program.cs` / DI-биндинг, миграции, генераторы.
- [ ] План рефакторинга выполним небольшими PR (новый интерфейс → адаптер → DI → замена вызова в SUT → тест с моком).
- [ ] Если port уже есть в проекте — не предлагать создавать дубликат.
- [ ] В тестовой секции указано, что мокать через `Mock<T>` и какие `Setup` нужны.

# Анти-паттерны
- ❌ «Обернули в `IClock`, но в конструкторе SUT всё равно `DateTime.UtcNow` как дефолтное значение» — port должен быть **единственным** источником времени.
- ❌ Перенести `DateTime.UtcNow` в private static helper того же сборки — это не изоляция, замокать всё ещё нельзя.
- ❌ Создавать port-интерфейс в Domain с зависимостью от `System.Net.Http` или `Microsoft.Extensions.Configuration` — порт должен быть BCL-only.
- ❌ Делать `IGuidProvider.NewGuid()` через `new Guid("...")` в проде — реализация-адаптер обязана вызывать настоящий `Guid.NewGuid()`.
- ❌ Требовать «переписать всё на ports» в одном PR — план рефакторинга обязательно дробится.
- ❌ Помечать как нарушение `DateTime.UtcNow` в самом `SystemClock : IClock` или в `Program.cs` при регистрации `TimeProvider.System`.

# Приложение: рекомендация по автоматическому enforcement

Skill не правит реальные `.csproj` репозитория. Это **рекомендуемая** конфигурация, которую команда может включить отдельным PR через `Microsoft.CodeAnalysis.BannedApiAnalyzers` ([nuget.org/packages/Microsoft.CodeAnalysis.BannedApiAnalyzers](https://www.nuget.org/packages/Microsoft.CodeAnalysis.BannedApiAnalyzers)).

## `BannedSymbols.txt` (рядом с проектом или в `Directory.Build.props`)

```text
M:System.DateTime.get_UtcNow;Use IClock.UtcNow
M:System.DateTime.get_Now;Use IClock.UtcNow
M:System.DateTimeOffset.get_UtcNow;Use IClock.UtcNow
M:System.DateTimeOffset.get_Now;Use IClock.UtcNow
M:System.Guid.NewGuid;Use IGuidProvider.NewGuid
M:System.Environment.GetEnvironmentVariable(System.String);Use IOptions<T> or IEnvironmentProvider
M:System.Environment.GetEnvironmentVariable(System.String,System.EnvironmentVariableTarget);Use IOptions<T> or IEnvironmentProvider
P:System.Environment.MachineName;Use IEnvironmentProvider
P:System.Environment.UserName;Use IEnvironmentProvider
P:System.Environment.ProcessId;Use IEnvironmentProvider
T:System.Random;Use IRandomProvider
P:System.Random.Shared;Use IRandomProvider
P:System.Globalization.CultureInfo.CurrentCulture;Use ICultureProvider or explicit parameter
P:System.Globalization.CultureInfo.CurrentUICulture;Use ICultureProvider or explicit parameter
P:System.Security.Claims.ClaimsPrincipal.Current;Use ICurrentUserProvider
P:System.Threading.Thread.CurrentPrincipal;Use ICurrentUserProvider
```

## Подключение в `.csproj` (фрагмент)

```xml
<ItemGroup>
  <PackageReference Include="Microsoft.CodeAnalysis.BannedApiAnalyzers" Version="3.3.4">
    <PrivateAssets>all</PrivateAssets>
    <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
  </PackageReference>
  <AdditionalFiles Include="BannedSymbols.txt" />
</ItemGroup>
```

## `.editorconfig` (фрагмент)

```ini
[*.cs]
dotnet_diagnostic.RS0030.severity = error
```

Включение анализатора в Infrastructure-адаптерах, реализующих port (`SystemClock`, `GuidProvider`, `SystemFileSystem`), сопровождается локальным `#pragma warning disable RS0030 // legitimate adapter` вокруг единственного вызова с комментарием-обоснованием.
