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
Все параметризованные тесты пишутся в одной из трёх форм. Форма выбирается по природе результата SUT.

## Таблица выбора формы
| Что тестирует SUT                                  | Форма | Тип параметра `expected`             | Assert                          |
|----------------------------------------------------|-------|--------------------------------------|---------------------------------|
| Классификацию исхода (success/validation/notfound) | A     | `enum <Feature>ExpectedResult`       | `switch` по `expected`          |
| Детерминированное вычисление конкретного значения  | B     | скаляр (`int`, `string`, `decimal`, `Guid`, `bool`, `DateTime`) | одна ассерт-строка `Assert.Equal` |
| И категорию исхода, и конкретный payload           | C     | `enum expectedOutcome` + скаляр `expectedValue` | короткий `switch` + сравнение payload |

Сложные объекты в `[InlineData]` запрещены (CLR-ограничение и хрупкость) — для них использовать `[MemberData]` с фабрикой `TheoryData<...>` или Test Data Builder.

## Форма A — enum-категория
Применять, когда тест проверяет, **к какой категории** относится результат, а конкретное значение второстепенно.

```csharp
public enum CreateUserExpectedResult
{
    Success,
    ValidationFailed,
    AlreadyExists,
    ExternalUnavailable,
}

public sealed class CreateUserCommandHandlerTests
{
    [Theory]
    [InlineData("", "John", CreateUserExpectedResult.ValidationFailed)]
    [InlineData("user@example.com", "", CreateUserExpectedResult.ValidationFailed)]
    [InlineData("duplicate@example.com", "John", CreateUserExpectedResult.AlreadyExists)]
    [InlineData("user@example.com", "John", CreateUserExpectedResult.Success)]
    public async Task Handle_VariousInputs_ReturnsExpectedOutcome(
        string email,
        string name,
        CreateUserExpectedResult expected)
    {
        var sut = CreateUserHandlerBuilder.Default()
            .WithExistingEmail("duplicate@example.com")
            .Build();

        var result = await sut.Handle(new CreateUserCommand(email, name), CancellationToken.None);

        switch (expected)
        {
            case CreateUserExpectedResult.Success:
                Assert.True(result.IsSuccess);
                break;
            case CreateUserExpectedResult.ValidationFailed:
                Assert.Equal(ErrorKind.Validation, result.Error.Kind);
                break;
            case CreateUserExpectedResult.AlreadyExists:
                Assert.Equal(ErrorKind.Conflict, result.Error.Kind);
                break;
            case CreateUserExpectedResult.ExternalUnavailable:
                Assert.Equal(ErrorKind.External, result.Error.Kind);
                break;
            default:
                throw new InvalidOperationException($"Unhandled case: {expected}");
        }
    }
}
```

## Форма B — скалярный ожидаемый результат
Применять, когда SUT — детерминированное вычисление (форматирование, парсинг, расчёт). Никаких `switch` — одно сравнение.

```csharp
public sealed class DiscountCalculatorTests
{
    [Theory]
    [InlineData(100, 0,  100)]
    [InlineData(100, 10, 90)]
    [InlineData(100, 100, 0)]
    [InlineData(200, 25, 150)]
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

## Форма C — комбинированная (категория + payload)
Применять, когда нужно одновременно проверить категорию и конкретное значение (код ошибки, сумму, идентификатор).

```csharp
public enum CalculateOrderExpectedOutcome
{
    Success,
    Rejected,
}

public sealed class CalculateOrderTotalTests
{
    [Theory]
    [InlineData(0,   CalculateOrderExpectedOutcome.Rejected, "EMPTY_CART")]
    [InlineData(50,  CalculateOrderExpectedOutcome.Success,  "55.00")]
    [InlineData(500, CalculateOrderExpectedOutcome.Success,  "550.00")]
    public void Calculate_VariousCarts_ReturnsExpectedOutcomeAndPayload(
        decimal subtotal,
        CalculateOrderExpectedOutcome expectedOutcome,
        string expectedValue)
    {
        var sut = new OrderTotalCalculator(taxRate: 0.10m);

        var result = sut.Calculate(subtotal);

        switch (expectedOutcome)
        {
            case CalculateOrderExpectedOutcome.Success:
                Assert.True(result.IsSuccess);
                Assert.Equal(decimal.Parse(expectedValue, CultureInfo.InvariantCulture), result.Value);
                break;
            case CalculateOrderExpectedOutcome.Rejected:
                Assert.False(result.IsSuccess);
                Assert.Equal(expectedValue, result.Error.Code);
                break;
            default:
                throw new InvalidOperationException($"Unhandled outcome: {expectedOutcome}");
        }
    }
}
```

## Когда `[MemberData]`
Если хотя бы один параметр — не примитив (`record`, `List<T>`, `DateTime` со сложной семантикой, объект-строитель), писать `MemberData` через `TheoryData<...>`:

```csharp
public static TheoryData<CreateUserCommand, CreateUserExpectedResult> Cases() => new()
{
    { new CreateUserCommand("", "John"),                 CreateUserExpectedResult.ValidationFailed },
    { new CreateUserCommand("user@example.com", "John"), CreateUserExpectedResult.Success },
};

[Theory]
[MemberData(nameof(Cases))]
public async Task Handle_VariousCommands_ReturnsExpectedOutcome(
    CreateUserCommand command,
    CreateUserExpectedResult expected) { /* ... */ }
```

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
| Более **6 параметров** в `[InlineData]`                              | Сгруппировать в Value Object / `record` и передавать через `MemberData`|
| В одном Act-вызове проверяется **более 1 ветви бизнес-логики**       | Выделить ветви в отдельные Specification / Strategy / методы           |
| Один и тот же мок настраивается по-разному в **одном** тесте         | Признак ветвления в SUT по типу входа — разнести по разным методам     |
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
- `Handle_VariousEmails_ReturnsExpectedOutcome` — `[Theory]`, форма A.
- `Calculate_VariousPercents_ReturnsExpectedAmount` — `[Theory]`, форма B.
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
- [ ] Параметризованные сценарии — `[Theory]` с `expectedResult` в одной из форм A/B/C; форма обоснована природой результата.
- [ ] Один тест проверяет одно наблюдаемое поведение.
- [ ] Имена тестов соответствуют формату `MethodOrFeature_StateUnderTest_ExpectedBehavior`.
- [ ] Файл с тестом зеркалит путь production-класса, 1 файл = 1 SUT, имя класса — `<SUT>Tests`.
- [ ] `MockBehavior.Strict` для критичных зависимостей; `Verify` только на наблюдаемое поведение.
- [ ] Ни один из decomposition triggers не сработал; если сработал — указан раздел Refactoring с конкретным планом.
- [ ] Тест устойчив к рефакторингу реализации SUT: правка внутреннего кода без смены контракта не ломает тест.

# Анти-паттерны
- ❌ `[Fact]` с копипастой одного теста на 5+ наборов данных вместо `[Theory]`.
- ❌ `[InlineData]` со сложными объектами (`record` с коллекциями, `JObject` и т. п.) — должно быть `[MemberData]`.
- ❌ Скаляр-результат, проверяемый через `switch` по фиктивному enum (форма B решается одной строкой `Assert.Equal`).
- ❌ Прямые вызовы `DateTime.UtcNow`, `Guid.NewGuid()`, `Environment.GetEnvironmentVariable`, `File.*` в SUT.
- ❌ Реальный SQL, Testcontainers, Docker в unit-проекте.
- ❌ `Verify(..., Times.Once)` на приватные/служебные вызовы (логирование, внутренние методы).
- ❌ `await Task.Delay`, `Thread.Sleep`, `SpinWait` для синхронизации в тесте.
- ❌ Статические поля и синглтоны, шарящие состояние между тестами.
- ❌ Тест, который ломается при рефакторинге внутренней реализации SUT без изменения её контракта.
- ❌ Игнорирование decomposition triggers — «допишем как-нибудь» с 8+ моками или 10+ параметрами `InlineData`.
- ❌ Группировка тестов через комментарии или `#region` вместо nested classes.
- ❌ Использование NUnit или MSTest в `*.Tests`-проекте.
