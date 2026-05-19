# PostgreSQL conventions

How services interact with PostgreSQL in s3lab projects.

## Database per service

- Each microservice owns its own database (or schema in a shared cluster).
- No cross-service queries. Cross-service data → events on RabbitMQ or REST call.

## Naming

- Tables: plural, snake_case: `orders`, `order_items`.
- Columns: snake_case: `created_at`, `user_id`.
- Primary keys: `id`, type `uuid` (generated via `uuid_generate_v7()` for time-ordered),
  or `bigint identity` for high-write internal tables.
- Foreign keys: `<table_singular>_id`: `order_id`, `user_id`.
- Indexes: `idx_<table>_<columns>`: `idx_orders_user_id_created_at`.

## Schema rules

- `created_at timestamptz NOT NULL DEFAULT now()` on every table.
- `updated_at timestamptz` on tables that mutate (with trigger or app-set).
- Soft deletes only when business requires it; prefer hard deletes + audit log.
- Money: `numeric(19,4)` with explicit currency column. Never `float` or `double`.
- Enums: PostgreSQL enum type for fixed small sets, string check constraint for larger or evolving sets.

## Migrations

- All schema changes via EF Core migrations (or Flyway for non-.NET services).
- Migrations named in PascalCase: `AddOrderExportStatusColumn`.
- One logical change per migration.
- Backward-compatible migrations preferred (add column nullable → backfill → make non-null in a follow-up).
- Never edit an applied migration. Roll forward.

## Queries

- Use parameterized queries always. Never string concatenation with user input.
- EF Core for typical CRUD. Raw SQL only for perf-critical or set-based operations.
- For complex reporting queries, create a database view and map it in EF as a keyless entity.

## Performance

- Add indexes for columns in WHERE, JOIN, ORDER BY of hot queries — but profile first.
- `EXPLAIN ANALYZE` to verify index usage when adding indexes.
- Connection pool sized to ~2× CPU cores of the service host; not infinite.
- Use `AsNoTracking()` for read-only queries in EF.

## Backups & maintenance

- `pg_dump` nightly to off-host storage, retain 30 days minimum.
- Test restore procedure quarterly.
- Vacuum and analyze run automatically; monitor for bloat.
