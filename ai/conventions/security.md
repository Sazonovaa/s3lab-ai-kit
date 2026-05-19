# Security baseline

Minimum security practices for s3lab projects. Everything here is non-negotiable.

## Secrets

- **Never commit secrets.** Not in code, not in tests, not in fixtures, not in CI logs.
- `.env` is gitignored. `.env.example` committed with placeholder values.
- Production secrets in a vault or platform secret store; injected as env vars.
- If a secret leaks: rotate immediately, then investigate.

## Input validation

- Validate all input at the API boundary using `FluentValidation` (backend) or typed forms (frontend).
- Reject by default; allow-list known fields.
- Never trust client-provided IDs for authorization. Always check ownership server-side.

## Output encoding

- HTML output: use the framework's encoding (Razor, Angular bindings). Never `[innerHTML]` with user content.
- JSON output: no raw HTML strings in JSON fields that will be rendered as HTML.
- SQL: parameterized queries only. EF Core does this; raw SQL must use parameters.

## Authentication

- See `identity-auth.md` for details.
- All endpoints require `[Authorize]` unless explicitly marked `[AllowAnonymous]`.
- No custom auth schemes. Use the identity server.

## Authorization

- Authorization happens server-side. Frontend hides UI for unauthorized actions, but
  the server is the gate.
- Resource ownership checks on every mutation: "is this user allowed to modify this order?"
- Role and policy checks via `[Authorize(...)]`, not ad-hoc if-statements in handlers.

## Transport

- HTTPS everywhere. HSTS enabled in production.
- TLS 1.2 minimum, prefer 1.3.
- HTTP redirects to HTTPS at the load balancer.

## CORS

- CORS allow-list: only the frontend's origin. No wildcards in production.
- Credentialed CORS requires explicit allow-listing per origin.

## Rate limiting

- Anonymous endpoints (login, registration, password reset): aggressive rate limit per IP.
- Authenticated endpoints: per-user rate limit.
- Implementation: `Microsoft.AspNetCore.RateLimiting` or reverse proxy (nginx, Caddy).

## Logging

- Never log secrets, tokens, passwords, PII without redaction.
- Log authentication events (success, failure, lockout).
- Logs to a centralized store with access controls.

## Dependencies

- `dotnet list package --vulnerable` and `npm audit` in CI on every PR.
- Critical and high vulnerabilities fail the build.
- Major version bumps reviewed before merge.

## Data handling

- PII encrypted at rest in the database (column-level or full-disk).
- PII never logged in plain text.
- Data export endpoints require explicit authorization and audit logging.

## What never to do

- Disable HTTPS for "convenience" in any environment that touches real data.
- Roll your own crypto.
- Hash passwords with anything other than the framework's password hasher (Argon2id, bcrypt).
- Trust `Origin` or `Referer` headers as the only auth signal.
- Pass tokens or PII in URL query strings.
