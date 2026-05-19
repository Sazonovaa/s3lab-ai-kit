# RabbitMQ / MassTransit conventions

How services communicate asynchronously in s3lab projects.

## When to use

- **REST** for synchronous request/response within a single user action.
- **RabbitMQ** for cross-service events, background jobs, long-running operations,
  and anything where the caller doesn't need the result immediately.

## Message types

- **Event** — past-tense, "something happened": `OrderCreated`, `PaymentReceived`.
  Multiple consumers possible. Publishers don't know who listens.
- **Command** — imperative, "do this": `SendInvoiceEmail`, `ExportOrdersToExcel`.
  Single consumer. Use when you know which service must act.

## Naming

- Messages live in a shared library: `<Project>.Contracts` referenced by all services.
- Namespace: `<Project>.Contracts.<Domain>`, e.g., `Acme.Contracts.Orders`.
- Class names: PascalCase, past-tense for events (`OrderShipped`), imperative for commands (`ShipOrder`).
- Properties: PascalCase, primitive types or DTO records.

## Versioning contracts

- Adding optional properties is non-breaking. Removing or changing types is breaking.
- For breaking change: introduce `OrderCreatedV2`, deprecate V1, migrate consumers, then remove V1.
- Never edit a deployed message contract in place.

## Producers

- Inject `IPublishEndpoint` (events) or `ISendEndpointProvider` (commands).
- Publish inside the same transaction as the DB write that produced the event.
  Use Outbox pattern via MassTransit's `AddEntityFrameworkOutbox` to guarantee
  at-least-once delivery.

## Consumers

- One consumer class per message: `OrderCreatedConsumer`.
- Idempotent: receiving the same message twice must produce the same final state.
- Use deduplication via the Inbox pattern when idempotency cannot be guaranteed in the handler.
- Handler MUST be short. Long work → schedule a saga or background job.
- On unhandled exception: MassTransit retries (3 by default), then moves to error queue.

## Sagas

- Use for multi-step workflows that span time and services (order → payment → ship → notify).
- State machine in `<Service>.Application/Sagas/`.
- Persistence via EF Core saga repository.

## Local development

- RabbitMQ container in `docker-compose.yml` with management UI on `localhost:15672`.
- Default credentials: `guest`/`guest`. Override per environment via env vars.

## Observability

- Log message ID, type, and correlation ID at consume start and end.
- Use MassTransit's OpenTelemetry instrumentation to trace across services.
- Set up Grafana dashboards for queue depth, consumer lag, and DLQ size when production-bound.
