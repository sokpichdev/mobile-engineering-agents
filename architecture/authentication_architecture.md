# Architecture: Authentication Architecture

Structure for secure auth: OAuth2 + PKCE, Keychain storage, single-flight refresh, and
authorized networking. See [`skills/security/oauth2.md`](../skills/security/oauth2.md) and
[`workflows/implement_authentication.md`](../workflows/implement_authentication.md).

## Overview

```mermaid
graph TD
    UI[Login View] --> VM[LoginViewModel]
    VM --> AS[AuthService]
    AS --> ASWeb[ASWebAuthenticationSession]
    AS --> TM[TokenManager actor]
    TM --> KC[Keychain SecureStore]
    NET[APIClient AuthInterceptor] --> TM
    NET --> API((Resource Server))
    AS --> IDP((Authorization Server))
```

`TokenManager` (an actor) is the single owner of session tokens; both the login flow and the
networking interceptor go through it, which is what makes refresh race-free.

## Login Flow (Authorization Code + PKCE)

```mermaid
sequenceDiagram
    participant VM as LoginViewModel
    participant AS as AuthService
    participant B as ASWebAuthenticationSession
    participant IDP as Auth Server
    participant TM as TokenManager
    participant KC as Keychain
    VM->>AS: login()
    AS->>AS: generate code_verifier + S256 challenge + state
    AS->>B: open authorize URL (challenge, state)
    B->>IDP: user authenticates
    IDP-->>B: redirect ?code & state
    AS->>AS: validate state
    AS->>IDP: exchange code + verifier → tokens
    IDP-->>AS: access + refresh (+ exp)
    AS->>TM: store(session)
    TM->>KC: save tokens (ThisDeviceOnly)
```

## Authorized Request + Single-Flight Refresh

```mermaid
sequenceDiagram
    participant N as AuthInterceptor
    participant TM as TokenManager (actor)
    participant API as Resource Server
    N->>TM: validSession()
    alt access valid
        TM-->>N: access token
    else expired
        TM->>TM: single-flight refresh (one Task)
        TM->>API: refresh token grant
        API-->>TM: new tokens
        TM-->>N: access token
    end
    N->>API: request + Bearer
    API-->>N: 401?
    N->>TM: forceRefresh() once, then retry
```

## Components

- **AuthService** — runs the PKCE login flow via `ASWebAuthenticationSession`.
- **TokenManager (actor)** — owns tokens; `validSession()` returns a fresh access token,
  serializing refresh so concurrent callers share one refresh.
- **Keychain SecureStore** — persists tokens (`...ThisDeviceOnly`), optionally biometric-gated.
- **AuthInterceptor** — injects the bearer header; handles 401 with one forced refresh + retry.
- **Logout** — clears Keychain + caches; resets session state.

## Security Invariants

- Authorization Code + PKCE only; no implicit flow / embedded secret; `state` validated.
- Tokens in Keychain only; never logged; cleared on logout.
- Exactly one in-flight refresh; JWT `exp` enforced with skew.

## Related

- [networking_architecture.md](networking_architecture.md)
- [`templates/authentication_layer/`](../templates/authentication_layer/)
- [`checklists/security_review.md`](../checklists/security_review.md)
