# Stack

Default stack for s3lab projects. Unless the project's `.ai/project-context.md`
overrides specific items, assume:

## Backend
- **.NET 10** (LTS preview as of 2026)
- **EF Core** for ORM, PostgreSQL provider
- **MassTransit** with RabbitMQ transport for async messaging
- **MediatR** for CQRS use cases (when project complexity warrants)
- **FluentValidation** for input validation
- **Swashbuckle** for OpenAPI generation
- **xUnit + FluentAssertions + NSubstitute** for tests
- **Testcontainers** for integration tests against real PostgreSQL/RabbitMQ

## Frontend
- **Angular 18+** with standalone components
- **Signals** for reactive state; RxJS for HTTP and streams
- **Angular Material** as the component library (until proven insufficient)
- **ng-openapi-gen** generates TypeScript API clients from backend OpenAPI
- **Jasmine + Karma** for unit tests; **Playwright** for e2e
- **ESLint + Prettier** for linting and formatting

## Infrastructure
- **Docker Compose** for local development and VPS deployment
- **VPS** (typical Linux host) as deployment target
- **GitHub Actions** for CI/CD
- **PostgreSQL 16+** as primary datastore
- **RabbitMQ 3.13+** for async messaging
- **Keycloak** or **IdentityServer** as identity provider, issuing JWT tokens

## Tooling
- **GitHub Issues** for task tracking
- **Pull Requests** with required review before merge
- **Conventional Commits** for commit messages
- **ADRs** (Architecture Decision Records) in `docs/adr/`
