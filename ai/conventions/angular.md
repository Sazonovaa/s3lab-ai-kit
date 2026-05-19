# Angular conventions

Conventions for Angular frontends in s3lab projects.

## Project layout

```
frontend/
├── src/
│   ├── app/
│   │   ├── core/           # singleton services, interceptors, guards
│   │   ├── shared/         # shared components, pipes, directives
│   │   ├── features/       # feature modules (lazy-loaded routes)
│   │   │   └── <feature>/
│   │   │       ├── pages/
│   │   │       ├── components/
│   │   │       └── services/
│   │   ├── api/
│   │   │   └── generated/  # ng-openapi-gen output — NEVER edit by hand
│   │   └── app.config.ts
│   ├── assets/
│   │   └── i18n/           # translation keys
│   └── styles/             # global styles, design tokens
└── package.json
```

## Components

- **Standalone components only** for new code. No NgModules.
- One component per file. File name matches component name in kebab-case.
- Smart vs presentational split: pages are smart (inject services), components are presentational (inputs/outputs only).
- Use `OnPush` change detection by default.

## State management

- **Signals** for component-local and feature-level state.
- **RxJS** for HTTP, debounced inputs, websocket streams.
- Avoid mixing Signals and RxJS for the same piece of state — pick one per concern.
- For cross-feature state, use a service with Signals or `signalStore` (ngrx/signals).

## HTTP and API

- **All API calls go through generated clients** in `src/app/api/generated/`.
- Never write `HttpClient.get/post` directly for project endpoints.
- If a needed endpoint is missing from the generated client: STOP, the backend
  contract is incomplete. Invoke `api-contract` Mode B before proceeding.
- Interceptors: auth token attachment, error normalization, retry for idempotent calls.

## Forms

- Reactive forms with typed `FormGroup<T>`.
- Validators co-located with the form definition.
- Async validators must include `debounceTime` and `distinctUntilChanged`.

## Routing

- All feature routes lazy-loaded: `loadChildren: () => import('./features/orders/orders.routes')`.
- Route guards as functional guards (Angular 16+), not class-based.
- Resolvers only for data that MUST be present before the route activates.

## Styling

- Angular Material first; custom components only when Material doesn't fit.
- Design tokens in `src/styles/tokens.scss`.
- BEM-style class names for custom components: `.order-card`, `.order-card__title`.
- No inline `style` attributes except for dynamic values.

## i18n

- All user-facing strings in `src/assets/i18n/<locale>.json`.
- Never hardcode strings in templates. Use `{{ 'order.title' | translate }}`.
- Keys hierarchical: `<feature>.<element>.<state>`.

## Testing

- Unit tests for services and pipes via Jasmine + Karma.
- Component tests with `TestBed` for non-trivial logic.
- e2e tests in `e2e/` via Playwright for critical user paths.
- Test names describe behavior, not implementation.

## Build & run

- `npm install`, then `npm start` for dev server (port 4200 by default).
- `npm test -- --watch=false` for one-shot unit tests.
- `npx playwright test` for e2e.
- `npm run generate:api` to regenerate TypeScript client from OpenAPI.
- `npm run build` must succeed without warnings before opening PR.
