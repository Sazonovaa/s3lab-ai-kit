---
name: dotnet-unit-tests-xunit-moq
description: >-
  Стандарт модульных тестов .NET в этом репозитории: xUnit + Moq, Theory-first
  с параметром expectedResult, моки всех DI-зависимостей и недетерминизма
  (время, Guid, окружение, файлы, HTTP, шина), отказ от реальных БД и внешних
  систем, единые правила именования и группировки, числовые пороги для
  декомпозиции SUT перед написанием тестов. Применять при написании, ревью и
  оценке тестируемости любого .NET кода.
triggers:
  - xUnit
  - Moq
  - unit test
  - модульный тест
  - юнит тест
  - Theory
  - теория
  - параметризованный тест
  - InlineData
  - MemberData
  - expectedResult
  - mock
  - replace DateTime.UtcNow
  - IClock
  - IDateTimeProvider
  - decompose for tests
  - split theory
  - tuple expected
  - Assert.Equal tuple
  - test naming
  - тест на репозиторий
---

# Назначение
Зафиксировать единый стандарт **модульных тестов на .NET**: стек **xUnit + Moq**, anti-fragile подход (тесты не правятся при каждом изменении реализации), параметризация через **`[Theory]`** с обязательным `expectedResult`, полная изоляция от БД, внешних систем и недетерминизма (время, Guid, окружение). Skill применяется как контракт для агента и разработчика: написать или отревьюить тест можно только так, как описано здесь.

# Когда применять
- Написание новых модульных тестов в `*.Tests` / `*.Test` проекте решения.
- Ревью существующих тестов на хрупкость, дублирование и нарушение изоляции.
- Оценка тестируемости SUT **до** написания теста: если SUT не проходит пороги из раздела «Decomposition triggers», сначала рефакторинг production-кода.
- Реакция на сигнал из `repository_layer_audit` skill: «бизнес-логика в репозитории» → вынести и покрыть тестами по этому контракту.

# Входные данные
1. **SUT**: класс/метод/handler, его публичный контракт (вход, выход, исключения).
2. **Зависимости через DI**: репозитории, шины, HTTP-клиенты, доменные сервисы, провайдеры конфигурации.
3. **Источники недетерминизма**: время, Guid, рандом, чтение окружения, файлов, текущей культуры.
4. **Существующие порты-интерфейсы**: `IClock`, `IGuidProvider`, `IRepository<T>` и т. д. Если их нет — фиксируется как блокер на рефакторинг.

# Базовые принципы (anti-fragile)
1. **Тестируем поведение, а не реализацию.** Проверка опирается на публичный контракт SUT (возвращаемое значение, опубликованное событие, состояние агрегата). Не проверять, сколько раз вызвался приватный или внутренний помощник.
2. **AAA-структура** (`Arrange / Act / Assert`) — три блока, разделённые пустой строкой. Не писать комментарии `// Arrange`, `// Act`, `// Assert` — структура читается из пробелов.
3. **Один тест — одно поведение.** Несколько `Assert.*` в одном тесте допустимы только если они описывают **одно** наблюдаемое поведение (например, поля одного DTO в одном Result). Разные сценарии — разные тесты или разные строки `[InlineData]`.
4. **Theory-first.** Если у метода есть классы эквивалентности входов — обязателен `[Theory]` с `[InlineData]` / `[MemberData]` и параметром `expectedResult`. `[Fact]` — только когда поведение принципиально единичное (например, проверка инварианта конструктора).
5. **Никакого недетерминизма в SUT.** `DateTime.UtcNow`, `DateTime.Now`, `Guid.NewGuid()`, `Random`, `Environment.GetEnvironmentVariable`, `File.*`, `CultureInfo.CurrentCulture` в production-коде запрещены — только через интерфейс (см. «Изоляция недетерминизма»).
6. **Всё внедрённое через DI — мокается.** Любая зависимость, пересекающая границу bounded context (репозиторий, шина, HTTP, файловая система, доменный сервис из другого слоя), оборачивается `Mock<T>`.
7. **Внешние системы не тестируем.** Реальная БД, RabbitMQ, MinIO, Redis, HTTP-эндпоинты, контейнеры — не используются. Мы описываем их возможные ответы как состояния (success / not-found / timeout / 5xx / malformed) и проверяем реакцию SUT.

# Стек и запреты
- **Разрешено**: `xUnit` (`[Fact]`, `[Theory]`, `[InlineData]`, `[MemberData]`, `[ClassData]`, `IClassFixture<T>`), `Moq` (`Mock<T>`, `It.IsAny<T>`, `Setup`, `Returns`, `ReturnsAsync`, `Throws`, `Verify`, `MockBehavior.Strict`), `FluentAssertions` — только если уже используется в проекте.
- **Запрещено**:
  - `NUnit` (`[Test]`, `[TestCase]`, `Assert.That`), `MSTest`.
  - Реальный SQL, `Testcontainers`, `Docker`, любые контейнеры в unit-проекте.
  - Реальные HTTP-вызовы (`HttpClient` без замокированного `HttpMessageHandler`).
  - `Thread.Sleep`, `await Task.Delay` для синхронизации с асинхронным поведением.
  - Прямые обращения к `DateTime.UtcNow`, `Guid.NewGuid()`, `Environment.*`, `File.*` в production-коде и тестах.
  - Статические поля / синглтоны, шарящие состояние между тестами.

# Шаблон Theory с `expectedResult`
Все параметризованные тесты подчиняются одному правилу:

> **`expectedResult` — это полностью описанный ожидаемый исход. Assert — одна декларативная инструкция эквивалентности. Никаких `switch` / `if` / `?:` в Assert-блоке.**

Если в одном Theory кейсы проверяют **разные по форме** результаты (например, success проверяет `Id`, а failure — `ErrorCode`) — это **разные Theory-методы**. Не пытаться втиснуть всё в один Theory с веткой в Assert.

## Таблица выбора формы (по приоритету)
| Что тестирует SUT                                                                 | Форма | Тип параметра `expected`                                            | Assert                                          |
|-----------------------------------------------------------------------------------|-------|---------------------------------------------------------------------|-------------------------------------------------|
| Разные сценарии с **разной формой ожидания** (success vs failure разные поля)     | 1 (предпочтительно) | один скаляр / простой набор полей одного смысла | `Assert.Equal(expected, actual)` — одна строка  |
| Детерминированное вычисление одного значения (расчёт, парсинг, форматирование)    | 2     | скаляр (`int`, `string`, `decimal`, `Guid`, `bool`, `DateTime`)     | `Assert.Equal(expected, actual)`                |
| Все кейсы проверяют **одинаковый** набор полей одной структуры (fallback)         | 3     | несколько примитивных параметров, собираемых в кортеж/`record`      | одно `Assert.Equal((...), (...))` без switch    |

Сложные объекты в `[InlineData]` запрещены (CLR-ограничение) — для них `[MemberData]` с `TheoryData<...>` или Test Data Builder.

## Форма 1 — Split Theory (предпочтительно)
Принцип: **«одна форма ожидания — один Theory-метод»**. Кейсы группируются не по типу входа, а по типу проверки. Каждый метод заканчивается одной декларативной ассерт-строкой.

```csharp
public sealed class CreateUserCommandHandlerTests
{
    [Theory]
    [InlineData("user@example.com", "John")]
    [InlineData("alice@example.com", "Alice")]
    public async Task Handle_ValidInput_ReturnsSuccess(string email, string name)
    {
        var sut = CreateUserHandlerBuilder.Default().Build();

        var result = await sut.Handle(new CreateUserCommand(email, name), CancellationToken.None);

        Assert.True(result.IsSuccess);
    }

    [Theory]
    [InlineData("",                 "John", "Error.Validation")]
    [InlineData("user@example.com", "",     "Error.Validation")]
    [InlineData("dup@example.com",  "John", "Error.Conflict")]
    public async Task Handle_InvalidInput_ReturnsExpectedErrorCode(
        string email, string name, string expectedErrorCode)
    {
        var sut = CreateUserHandlerBuilder.Default()
            .WithExistingEmail("dup@example.com")
            .Build();

        var result = await sut.Handle(new CreateUserCommand(email, name), CancellationToken.None);

        Assert.Equal(expectedErrorCode, result.Error.Code);
    }

    [Theory]
    [InlineData("bus-down@example.com", "John")]
    public async Task Handle_WhenEventBusUnavailable_PublishesNothing(string email, string name)
    {
        var bus = new Mock<IEventBus>(MockBehavior.Strict);
        bus.Setup(b => b.PublishAsync(It.IsAny<UserCreatedEvent>(), It.IsAny<CancellationToken>()))
           .ThrowsAsync(new BrokerUnavailableException());
        var sut = CreateUserHandlerBuilder.Default().WithBus(bus).Build();

        var result = await sut.Handle(new CreateUserCommand(email, name), CancellationToken.None);

        Assert.Equal("Error.External", result.Error.Code);
    }
}
```

Зачем так:
- Каждый метод читается как одно бизнес-правило.
- Изменился контракт одной ветки — правится один метод; остальные не трогаются.
- Никакого условного кода в Assert — баги в тесте невозможны.
- Имя метода уже содержит ожидание (`ReturnsSuccess`, `ReturnsExpectedErrorCode`), пользователь видит покрытие в Test Explorer.

## Форма 2 — Скаляр (детерминированное вычисление)
Применять для расчётов, парсинга, форматирования. Один параметр `expected`, одна ассерт-строка.

```csharp
public sealed class DiscountCalculatorTests
{
    [Theory]
    [InlineData(100, 0,   100)]
    [InlineData(100, 10,  90)]
    [InlineData(100, 100, 0)]
    [InlineData(200, 25,  150)]
    public void Calculate_VariousPercents_ReturnsExpectedAmount(
        decimal amount,
        decimal percent,
        decimal expected)
    {
        var sut = new DiscountCalculator();

        var actual = sut.Calculate(amount, percent);

        Assert.Equal(expected, actual);
    }
}
```

## Форма 3 — Кортеж/record (fallback, когда у всех кейсов одинаковая форма ожидания)
Применять только если **все** строки `[InlineData]` проверяют одни и те же поля одной структуры (например, везде `(IsSuccess, ErrorCode)`). Сравнение — один `Assert.Equal` кортежей. Если форма у разных кейсов разная — это форма 1.

```csharp
public sealed class CalculateOrderTotalTests
{
    [Theory]
    [InlineData(0,   false, "EMPTY_CART", 0)]
    [InlineData(50,  true,  null,         55)]
    [InlineData(500, true,  null,         550)]
    public void Calculate_VariousCarts_ReturnsExpectedTotalAndStatus(
        decimal subtotal,
        bool    expectedIsSuccess,
        string? expectedErrorCode,
        decimal expectedTotal)
    {
        var sut = new OrderTotalCalculator(taxRate: 0.10m);

        var result = sut.Calculate(subtotal);

        Assert.Equal(
            (expectedIsSuccess, expectedErrorCode, expectedTotal),
            (result.IsSuccess,  result.Error?.Code, result.Value));
    }
}
```

Замечание: `null` в кортеже допустим как явное «поле не значимо в этом кейсе», если оно не значимо **во всех** кейсах одной структуры. Если для success-кейса осмысленно одно поле, а для failure — другое, переходить на форму 1.

## Размещение тестовых данных
Правило приоритета — данные должны быть **видны сразу над методом теста**:

1. **`[InlineData]` — всегда первый выбор.** Все параметры теста перечислены атрибутами над методом, читаются как таблица: одна строка — один кейс.
2. **Если в кейсе нужен сложный объект** (`record`, `command`, `dto`) — **разложить его на примитивные поля** и собрать объект **внутри** теста. Это сохраняет «вся data inline» и устраняет `MemberData` в 90% случаев.
3. **`[MemberData]` — только когда CLR-ограничение не оставляет выбора**: коллекции (`List<T>`, массив сложных объектов), несколько сложных объектов в одной строке, неименуемые литералы (`DateTimeOffset` с TZ, `Guid`-литералы). В этом случае:
   - провайдер — `public static TheoryData<...>` **в том же файле**, **в том же классе**;
   - размещается **вплотную над методом теста** (между провайдером и `[Theory]` — только сам атрибут `[MemberData]`);
   - один провайдер обслуживает **ровно один** тест-метод (нельзя переиспользовать на N тестов — теряется наглядность данных);
   - имя провайдера = имя теста + `Cases`: `Handle_ValidCommand_ReturnsSuccess` → `Handle_ValidCommand_ReturnsSuccessCases`.

### Способ 1 — декомпозиция (предпочтительно)
Сложный `CreateUserCommand` разложен на поля; объект собирается в Arrange:

```csharp
[Theory]
[InlineData("user@example.com",  "John",  "RU")]
[InlineData("alice@example.com", "Alice", "EN")]
public async Task Handle_ValidInput_ReturnsSuccess(string email, string name, string locale)
{
    var sut = CreateUserHandlerBuilder.Default().Build();
    var command = new CreateUserCommand(email, name, locale);

    var result = await sut.Handle(command, CancellationToken.None);

    Assert.True(result.IsSuccess);
}
```

### Способ 2 — `MemberData` рядом с тестом (только когда декомпозиция невозможна)
Например, нужно передать список тегов и `DateTimeOffset` с конкретным часовым поясом:

```csharp
public static TheoryData<List<string>, DateTimeOffset> Handle_ValidInput_AcceptsTagsAndScheduleCases() => new()
{
    { new List<string> { "vip", "trial" }, new DateTimeOffset(2026, 5, 17, 10, 0, 0, TimeSpan.FromHours(3)) },
    { new List<string>(),                  new DateTimeOffset(2026, 5, 17, 23, 59, 0, TimeSpan.FromHours(3)) },
};

[Theory]
[MemberData(nameof(Handle_ValidInput_AcceptsTagsAndScheduleCases))]
public async Task Handle_ValidInput_AcceptsTagsAndSchedule(List<string> tags, DateTimeOffset scheduledAt)
{
    var sut = CreateUserHandlerBuilder.Default().Build();

    var result = await sut.Handle(new CreateUserCommand(tags, scheduledAt), CancellationToken.None);

    Assert.True(result.IsSuccess);
}
```

Зачем такие требования к `MemberData`:
- Данные не теряются в утилитном классе / отдельном файле — читаются на одном экране с тестом.
- Имя провайдера привязано к тесту → видно «откуда какие данные».
- Запрещён общий провайдер на несколько тестов: разные тесты — разные данные по составу.

# Изоляция недетерминизма
В production-коде каждый источник недетерминизма обязан скрываться за интерфейсом-портом. В тестах порт мокается. Если порта нет — это блокер: сначала ввести порт в production, потом писать тест.

| Источник                                | Порт-интерфейс (обязателен)                 | Мок в тесте                                       |
|-----------------------------------------|---------------------------------------------|---------------------------------------------------|
| `DateTime.UtcNow` / `DateTimeOffset.Now`| `IClock` (`UtcNow`)                         | `Mock<IClock>().SetupGet(c => c.UtcNow).Returns(...)` |
| `Guid.NewGuid()`                        | `IGuidProvider` (`NewGuid()`)               | `Mock<IGuidProvider>().Setup(g => g.NewGuid()).Returns(...)` |
| `new Random()`                          | `IRandomProvider`                           | `Mock<IRandomProvider>`                           |
| `Environment.GetEnvironmentVariable`    | `IConfigProvider` / `IOptions<T>`           | `Options.Create(new TOptions { ... })`            |
| `File.*`, `Directory.*`                 | `IFileSystem`                               | `Mock<IFileSystem>`                               |
| `HttpClient` напрямую                   | `IHttpClientFactory` + типизированный клиент с интерфейсом | `Mock<HttpMessageHandler>` через `Protected().Setup` |
| `CultureInfo.CurrentCulture`            | `ICultureProvider` или явный аргумент       | `Mock<ICultureProvider>`                          |

Правило: **«нет порта — нет теста»**. Видишь `DateTime.UtcNow` в SUT — останови написание теста, оформи рефакторинг в production (минимальный: добавь `IClock`, прокинь через DI, замени вызов) и продолжай.

# Decomposition triggers
Сигналы, что SUT перегружен и тест получится хрупким. При срабатывании любого триггера — сначала декомпозиция production-кода, потом тест.

| Триггер                                                              | Куда выносить                                                          |
|----------------------------------------------------------------------|------------------------------------------------------------------------|
| Нужно более **4 моков** в одном тесте                                | Разнести оркестрацию по нескольким handler / domain service            |
| Более **6 параметров** в `[InlineData]`                              | Не уходить в `MemberData`. Сократить контракт SUT: выделить Value Object / отдельный handler / разнести Theory на несколько методов с меньшим набором осей варьирования |
| В одном Act-вызове проверяется **более 1 ветви бизнес-логики**       | Выделить ветви в отдельные Specification / Strategy / методы           |
| Один и тот же мок настраивается по-разному в **одном** тесте         | Признак ветвления в SUT по типу входа — разнести по разным методам     |
| В Assert хочется написать `switch` / `if` / `?:` по `expected*`      | Разнести Theory на **N методов** по форме ожидания (форма 1) или свести expectedResult к одному кортежу (форма 3) |
| В тесте нужны **приватные** методы SUT для проверки                  | Эти методы — отдельный класс с публичным контрактом                    |
| Бизнес-логика обнаружена внутри `*Repository*`                       | Применить [.ai/skills/engineering/repository_layer_audit.md](.ai/skills/engineering/repository_layer_audit.md) и вынести в Application/Domain |
| Тест требует знаний о порядке вызовов внутренних методов             | SUT нарушает инкапсуляцию — выделить наблюдаемое поведение (событие, состояние) |

Все триггеры — численные, не «на глаз». Если порог сработал, тест не пишется до правки production.

# Правила именования
Единый формат для всех тестов в репозитории:

```
<MethodOrFeature>_<StateUnderTest>_<ExpectedBehavior>
```

- `MethodOrFeature` — имя публичного метода SUT, имя use case или handler (PascalCase).
- `StateUnderTest` — короткое описание сценария: `WhenUserNotFound`, `WithEmptyEmail`, `WhenRabbitTimeout`, `OnDuplicateKey`.
- `ExpectedBehavior` — что должно произойти: `ReturnsNotFound`, `ThrowsValidationException`, `PublishesUserCreatedEvent`, `ReturnsExpectedAmount`.

Для `[Theory]` имя метода описывает **общее поведение группы кейсов**, конкретика — в параметре `expectedResult` и `DisplayName` строки данных при необходимости.

Примеры:
- `Handle_WhenUserNotFound_ReturnsNotFound` — `[Fact]`, единичный сценарий.
- `Handle_ValidInput_ReturnsSuccess` — `[Theory]`, форма 1 (один тип ожидания на метод).
- `Handle_InvalidInput_ReturnsExpectedErrorCode` — `[Theory]`, форма 1.
- `Calculate_VariousPercents_ReturnsExpectedAmount` — `[Theory]`, форма 2 (скаляр).
- `Calculate_VariousCarts_ReturnsExpectedTotalAndStatus` — `[Theory]`, форма 3 (кортеж).
- `Publish_OnSuccessfulSave_PublishesUserCreatedEvent` — `[Fact]`, проверка наблюдаемого события.
- `Constructor_WithNullRepository_ThrowsArgumentNullException` — `[Fact]`, инвариант конструктора.

Запрещено: `Test1`, `TestHandle`, `Handle_Works`, `Should_Work`, `WhenSomething` без `Expected*`.

# Правила группировки
## Файловая структура
- **1 файл = 1 тестовый класс = 1 production-класс под тестом** (правило репозитория «один файл — один объект»).
- Путь тестов **зеркалит** production:

```text
src/<Service>/Application/Features/User/CreateUser/CreateUserCommandHandler.cs
tests/<Service>.Tests/Application/Features/User/CreateUser/CreateUserCommandHandlerTests.cs
```

- Имя класса теста: `<SUT>Tests`.
- Общие билдеры моков и Test Data Builders — отдельная папка `Builders/` внутри тест-проекта; один builder = один файл.
- Тяжёлые общие сетапы (например, общий `Mock<IClock>` для группы тестов) — через `IClassFixture<T>`. Никаких статических полей.

## Внутри тестового класса
- Если в SUT 3–4+ ветви, группировать через **nested classes** по типу сценария. Это даёт читаемый список в Test Explorer (`HandlerTests/ValidationCases/...`):

```csharp
public sealed class CreateUserCommandHandlerTests
{
    public sealed class ValidationCases { /* [Theory] / [Fact] */ }
    public sealed class HappyPath { /* ... */ }
    public sealed class FailurePaths { /* ... */ }
    public sealed class Idempotency { /* ... */ }
    public sealed class Concurrency { /* ... */ }
}
```

- Если у SUT ≤ 3 простых ветви, оставлять плоско, без nested classes.
- Никаких `#region` для группировки тестов — только nested classes.

# Mock policy
- `MockBehavior.Strict` по умолчанию для зависимостей, контракт которых критичен (репозитории, шина, HTTP-клиент). Это ловит непредусмотренные вызовы.
- `MockBehavior.Loose` допустим только для откровенно вспомогательных моков (`ILogger<T>`).
- `Verify` использовать **только** на наблюдаемое поведение: «было опубликовано событие», «было записано в репозиторий», «было отправлено сообщение в очередь». Не верифицировать внутренние/служебные вызовы (`logger.LogInformation`, приватные хелперы, EF-конкретные методы).
- `It.IsAny<T>()` — нормально для аргументов, которые тест не проверяет; для проверяемых аргументов — `It.Is<T>(x => ...)` или `Callback`.
- Один тест — одна конфигурация моков. Если конфигурация меняется внутри теста — это триггер декомпозиции (см. выше).

# Формат вывода агента
При работе по этому skill агент возвращает результат в таком виде:

1. **Test matrix** — таблица «вход → ожидаемый результат», по строкам — классы эквивалентности.
2. **Test code** — готовый код тестового класса на xUnit + Moq, выбранная форма Theory (A/B/C) обоснована одной строкой.
3. **Gaps** — что ещё не покрыто и почему (граничные значения, отложенные на интеграционный уровень, т. д.).
4. **Refactoring** — если сработал хотя бы один decomposition trigger или отсутствует обязательный порт изоляции: какой именно триггер, какой минимальный рефакторинг production-кода нужен **до** написания теста.

# Планка качества (самопроверка)
- [ ] Стек — только xUnit + Moq. Нет NUnit (`[Test]`, `[TestCase]`, `Assert.That`) и MSTest.
- [ ] В тесте нет реальной БД, Docker, Testcontainers, реальных HTTP/RabbitMQ/MinIO/Redis.
- [ ] В SUT и в тесте нет прямых обращений к `DateTime.UtcNow`, `Guid.NewGuid`, `Environment.*`, `File.*`, `Random`, `CultureInfo.Current*` — всё через порты.
- [ ] Параметризованные сценарии — `[Theory]` с `expectedResult` в одной из форм 1/2/3; форма обоснована природой результата.
- [ ] В Assert-блоке **нет** `switch`, `if`, `?:`. Каждый тест заканчивается одной декларативной инструкцией эквивалентности.
- [ ] Если у сценариев разная форма ожидания — это разные Theory-методы (форма 1), а не один Theory с веткой.
- [ ] Тестовые данные — `[InlineData]` (видно сразу над методом). `[MemberData]` использован только когда CLR не оставляет выбора; провайдер расположен вплотную над методом и обслуживает ровно один тест.
- [ ] Один тест проверяет одно наблюдаемое поведение.
- [ ] Имена тестов соответствуют формату `MethodOrFeature_StateUnderTest_ExpectedBehavior`.
- [ ] Файл с тестом зеркалит путь production-класса, 1 файл = 1 SUT, имя класса — `<SUT>Tests`.
- [ ] `MockBehavior.Strict` для критичных зависимостей; `Verify` только на наблюдаемое поведение.
- [ ] Ни один из decomposition triggers не сработал; если сработал — указан раздел Refactoring с конкретным планом.
- [ ] Тест устойчив к рефакторингу реализации SUT: правка внутреннего кода без смены контракта не ломает тест.

# Анти-паттерны
- ❌ **`switch` / `if` / `?:` в Assert-блоке** по `expected*`-параметру. Тест с условной логикой — это второй непроверенный код; правильный приём — разнести Theory на N методов (форма 1) либо свести ожидание к кортежу (форма 3).
- ❌ Один Theory, в котором success-кейс проверяет одни поля, а failure — другие. Это разные Theory-методы.
- ❌ Enum-тип `<Feature>ExpectedResult { Success, ValidationFailed, ... }` как параметр Theory с раскруткой через `switch` в Assert.
- ❌ `[Fact]` с копипастой одного теста на 5+ наборов данных вместо `[Theory]`.
- ❌ `[MemberData]`-провайдер, оторванный от теста: общий на несколько методов, в `TestDataFixtures.cs`, в base-классе, в `partial class`-другом файле. Данные должны быть видны на одном экране с тестом.
- ❌ Уход в `[MemberData]` ради «компактности», когда сложный объект можно разложить на примитивные поля `[InlineData]` и собрать внутри теста.
- ❌ `[InlineData]` со сложными объектами (`record`, `List<T>`, `JObject`) — это CLR-ограничение, не «эстетика».
- ❌ Прямые вызовы `DateTime.UtcNow`, `Guid.NewGuid()`, `Environment.GetEnvironmentVariable`, `File.*` в SUT.
- ❌ Реальный SQL, Testcontainers, Docker в unit-проекте.
- ❌ `Verify(..., Times.Once)` на приватные/служебные вызовы (логирование, внутренние методы).
- ❌ `await Task.Delay`, `Thread.Sleep`, `SpinWait` для синхронизации в тесте.
- ❌ Статические поля и синглтоны, шарящие состояние между тестами.
- ❌ Тест, который ломается при рефакторинге внутренней реализации SUT без изменения её контракта.
- ❌ Игнорирование decomposition triggers — «допишем как-нибудь» с 8+ моками или 10+ параметрами `InlineData`.
- ❌ Группировка тестов через комментарии или `#region` вместо nested classes.
- ❌ Использование NUnit или MSTest в `*.Tests`-проекте.
