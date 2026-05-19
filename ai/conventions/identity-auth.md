# Identity and auth conventions

How authentication and authorization work in s3lab projects.

## Identity provider

- External identity server (Keycloak or IdentityServer) issues JWT access tokens.
- Each service validates tokens locally using the identity server's JWKS endpoint.
- No service stores user passwords. No service issues tokens. Identity provider is the single source of truth.

## Token validation in .NET

- Use `Microsoft.AspNetCore.Authentication.JwtBearer`.
- Validate: issuer, audience, signature, lifetime.
- Cache JWKS for a short period; refresh on signature failures.

## Endpoint protection

- `[Authorize]` is the default. Add explicit `[AllowAnonymous]` for public endpoints.
- For role-based: `[Authorize(Roles = "Admin")]`.
- For claim-based: `[Authorize(Policy = "CanExportOrders")]` with policy registered in `Program.cs`.
- For resource-based (e.g., user can only edit own orders): authorization handler implementing
  `IAuthorizationHandler` against an `IAuthorizationRequirement`.

## Token usage in frontend

- Tokens stored in memory + httpOnly refresh cookie (NEVER `localStorage` or `sessionStorage`).
- HTTP interceptor attaches `Authorization: Bearer <token>` to API calls.
- 401 response → attempt silent refresh → on failure, redirect to login.
- Logout → call identity server's end-session endpoint, then clear local state.

## User identity in code

- Never trust the user-id from the request body. Always read it from the validated JWT.
- In .NET: `User.FindFirstValue(ClaimTypes.NameIdentifier)` or a typed helper.
- Pass user identity through service layers as a typed `CurrentUser` object, not raw `ClaimsPrincipal`.

## Service-to-service auth

- For internal calls: client-credentials grant against identity server.
- Each service has its own OAuth client with scoped permissions.
- Never share user tokens between services. Each service requests its own.

## Secrets

- Client secrets in env vars: `IDENTITY__CLIENT_SECRET`.
- Never commit secrets. `.env` gitignored, `.env.example` committed with placeholder values.
- Production secrets: in a vault (HashiCorp Vault, AWS Secrets Manager, or VPS-level encrypted env).

## What never to do

- Issue your own tokens.
- Validate tokens with a shared secret across services (always use asymmetric, JWKS-based).
- Pass tokens in URL query strings.
- Log tokens, even at trace level.
- Implement your own password hashing or session management.
