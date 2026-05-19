# .NET conventions

Conventions for .NET 10 microservices in s3lab projects.

## Service layout

Each microservice lives in `backend/services/<service-name>/`:

```
<service-name>/
├── src/
│   ├── <Service>.Domain/           # entities, value objects, domain events, interfaces
│   ├── <Service>.Application/      # use cases (CQRS), DTOs, validators
│   ├── <Service>.Infrastructure/   # EF, MassTransit, external APIs
│   └── <Service>.Api/              # controllers, middleware, Program.cs
└── tests/
    ├── <Service>.UnitTests/        # domain + application
    └── <Service>.IntegrationTests/ # API + DB via Testcontainers
```

## Code style

- File-scoped namespaces.
- `<Nullable>enable</Nullable>` and `<ImplicitUsings>enable</ImplicitUsings>`.
- Records for DTOs and value objects.
- `async` suffix on all async methods.
- `CancellationToken` as the last parameter on every async public method.
- No fire-and-forget: every `Task` is awaited or explicitly tracked.
- StyleCop + analyzers enabled; warnings as errors in CI.

## EF Core

- One `DbContext` per service.
- Configurations in `IEntityTypeConfiguration<T>` classes, never fluent-config in `OnModelCreating` directly.
- No lazy loading. Use `Include` explicitly.
- Migrations named in PascalCase describing intent: `AddOrderExportColumn`, not `Update1`.
- Raw SQL only for performance-critical paths, with a comment explaining why.

## MediatR (when used)

- Commands: `<Verb><Noun>Command` (e.g., `CreateOrderCommand`).
- Queries: `Get<Noun>Query` (e.g., `GetOrderByIdQuery`).
- Handlers in Application layer.
- Pipeline behaviors: Validation, Logging, Transaction.

## API design

- Errors as `ProblemDetails` (RFC 7807).
- Validation via `FluentValidation`, surfaced as 400 ProblemDetails.
- `[Authorize]` by default on every endpoint; `[AllowAnonymous]` explicit when needed.
- Versioning via URL segment: `/api/v1/orders`.
- Pagination: cursor-based for large lists, page+size for small admin lists.

## Logging

- `ILogger<T>` injected. Structured logging, no string interpolation in messages.
- Right: `_logger.LogInformation("Order {OrderId} created for {UserId}", id, userId);`
- Wrong: `_logger.LogInformation($"Order {id} created for {userId}");`
- Log levels: Trace/Debug for dev only, Information for business events, Warning for recoverable issues, Error for caught exceptions, Critical for unrecoverable.

## Testing

- xUnit + FluentAssertions + NSubstitute.
- Test naming: `MethodName_Scenario_ExpectedResult`.
- AAA structure with blank lines between Arrange, Act, Assert.
- Integration tests use `WebApplicationFactory<TProgram>` + Testcontainers (Postgres, RabbitMQ).
- Coverage target: 80% on Domain + Application, 50% on Infrastructure.

## Build & run

- `dotnet build` and `dotnet test` must pass after every change.
- Migrations: `dotnet ef migrations add <Name> -p <Infra> -s <Api>` from service folder.
- Local: `docker compose up -d` to bring up dependencies, then `dotnet run --project <Api>`.
