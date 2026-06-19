# Skill: OAuth2 (Authorization Code + PKCE)

## Overview

OAuth2 is the standard for delegated authorization. Native mobile apps are **public
clients** (they can't keep a secret), so they must use the **Authorization Code flow with
PKCE** — never the deprecated implicit flow and never an embedded client secret. The user
authenticates in a system browser (`ASWebAuthenticationSession`), the app receives an
authorization code via a redirect, and exchanges it (with the PKCE verifier) for tokens
stored in the Keychain.

## Use Cases

- "Sign in with" a third-party or your own identity provider.
- Any API requiring delegated access tokens with refresh.

## Best Practices

- **Authorization Code + PKCE** (S256 challenge). Generate a high-entropy `code_verifier`.
- Authenticate in **`ASWebAuthenticationSession`** (system browser), not an in-app `WKWebView`.
- Validate the **`state`** parameter to prevent CSRF; use a one-time random value.
- Store **access + refresh tokens in Keychain**; never in `UserDefaults`.
- **Refresh proactively/once** with single-flight to avoid concurrent refresh races; rotate
  refresh tokens if the server supports it.

## Anti-Patterns

- ❌ Implicit flow or embedding a client secret in the app.
- ❌ Using `WKWebView` for login (credential phishing risk, no SSO).
- ❌ Skipping `state` validation (CSRF).
- ❌ Storing tokens in `UserDefaults`/plist.
- ❌ Multiple concurrent refresh calls causing token invalidation.

## Checklist

- [ ] Authorization Code + PKCE (S256); no implicit flow, no embedded secret.
- [ ] Login via `ASWebAuthenticationSession`.
- [ ] `state` generated and validated.
- [ ] Tokens stored in Keychain; cleared on logout.
- [ ] Single-flight token refresh; refresh-token rotation handled.

## Swift Examples

```swift
import AuthenticationServices
import CryptoKit

func makePKCE() -> (verifier: String, challenge: String) {
    var bytes = [UInt8](repeating: 0, count: 32)
    _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
    let verifier = Data(bytes).base64URLEncodedString()
    let challenge = Data(SHA256.hash(data: Data(verifier.utf8))).base64URLEncodedString()
    return (verifier, challenge)
}

func authorize(authURL: URL, callbackScheme: String) async throws -> URL {
    try await withCheckedThrowingContinuation { continuation in
        let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackScheme) {
            url, error in
            if let url { continuation.resume(returning: url) }
            else { continuation.resume(throwing: error ?? AuthError.cancelled) }
        }
        session.prefersEphemeralWebBrowserSession = false
        session.presentationContextProvider = ContextProvider.shared
        session.start()
    }
}
```

```swift
// Single-flight refresh to avoid concurrent refreshes
actor TokenManager {
    private var refreshTask: Task<Session, Error>?
    func validSession() async throws -> Session {
        if let current = try? load(), !current.isExpired { return current }
        if let task = refreshTask { return try await task.value }
        let task = Task { try await performRefresh() }
        refreshTask = task
        defer { refreshTask = nil }
        return try await task.value
    }
}
```

## Common Interview Questions

- Why must native apps use PKCE?
- Why `ASWebAuthenticationSession` over `WKWebView`?
- What attack does the `state` parameter prevent?
- How do you avoid concurrent refresh races?
- What is refresh-token rotation?

## AI Implementation Notes

- Always generate Authorization Code + PKCE; refuse implicit flow / embedded secrets.
- Use `ASWebAuthenticationSession`; validate `state`; store tokens via the Keychain skill.
- Implement single-flight refresh with an actor.
- Related: [`jwt.md`](jwt.md), [`keychain.md`](keychain.md),
  [`../../workflows/implement_authentication.md`](../../workflows/implement_authentication.md).
