# Workflow: Implement Authentication

## Objective

Implement secure authentication: OAuth2 Authorization Code + PKCE (or login API), Keychain
token storage, single-flight refresh, biometric app-lock (optional), and clean logout.

## Inputs

- Identity provider / auth API details (endpoints, scopes, redirect URI, token lifetimes).
- Whether biometric app-lock is required.

## Outputs

- Auth module: login flow, token storage, refresh, session state, logout, tests.

## Step-by-Step Process

1. **Architect** ([iOS Architect](../agents/ios_architect.md)) — define `AuthService`,
   `Session`, `TokenManager`, and how features read auth state.
2. **Login flow** ([Security Expert](../agents/security_expert.md)) — OAuth2 Code + PKCE via
   `ASWebAuthenticationSession`, validate `state` (see [`skills/security/ios/oauth2.md`](../skills/security/ios/oauth2.md)).
3. **Token storage** — Keychain with correct accessibility
   (see [`skills/security/ios/keychain.md`](../skills/security/ios/keychain.md)); never `UserDefaults`.
4. **Refresh** — single-flight via an actor; parse `exp`; rotate refresh tokens
   (see [`skills/security/ios/jwt.md`](../skills/security/ios/jwt.md)).
5. **Networking** ([Networking Expert](../agents/networking_expert.md)) — inject bearer header;
   on 401, refresh once and retry.
6. **Biometric lock** (optional) — gate via Keychain `SecAccessControl`
   (see [`skills/security/ios/biometric_auth.md`](../skills/security/ios/biometric_auth.md)).
7. **Logout** — clear Keychain + caches; reset session state.
8. **Test + review** — cover login/refresh/expiry/logout;
   [`checklists/security_review.md`](../checklists/security_review.md).

## Validation Steps

- PKCE used; no implicit flow / embedded secret; `state` validated.
- Tokens in Keychain; cleared on logout; not logged.
- Concurrent requests trigger only one refresh; expiry handled with skew.

## Failure Scenarios

- **Refresh token expired/revoked** → force re-login; clear session.
- **Concurrent refresh race** → single-flight actor must serialize.
- **Biometric unavailable/locked out** → passcode fallback.
- **401 loop** → cap retries; surface a re-auth prompt.

## AI Agent Instructions

- Enforce OAuth2 Code + PKCE; refuse implicit flow / embedded secrets.
- Store tokens only in Keychain; implement single-flight refresh with an actor.
- Clear all credentials/caches on logout.
- Treat any security finding as blocking.

## Acceptance Criteria

- [ ] OAuth2 Code + PKCE via system browser; `state` validated.
- [ ] Tokens in Keychain; single-flight refresh; cleared on logout.
- [ ] 401 → refresh-once-and-retry implemented.
- [ ] Optional biometric lock via `SecAccessControl`.
- [ ] `checklists/security_review.md` passes.
