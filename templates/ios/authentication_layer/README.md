# Template: Authentication Layer

OAuth2 + PKCE login, Keychain token storage, and single-flight refresh. See
[`architecture/authentication_architecture.md`](../../../architecture/authentication_architecture.md)
and [`workflows/implement_authentication.md`](../../../workflows/implement_authentication.md).

## Folder Structure

```text
Auth/
├── Session.swift
├── AuthService.swift            // PKCE login via ASWebAuthenticationSession
├── TokenManager.swift           // actor: validSession() + single-flight refresh
├── KeychainStore.swift          // SecureStore impl (see skills/security/ios/keychain.md)
├── AuthInterceptor.swift        // injects bearer; 401 → refresh once + retry
└── AuthError.swift
Tests/
├── TokenManagerTests.swift
└── AuthInterceptorTests.swift
```

## Session & Errors

```swift
struct Session: Codable {
    let accessToken: String
    let refreshToken: String
    let expiry: Date
    var isExpired: Bool { Date() >= expiry.addingTimeInterval(-60) }   // 60s skew
}

enum AuthError: Error { case cancelled, invalidState, refreshFailed, notAuthenticated }
```

## TokenManager (single-flight refresh)

```swift
actor TokenManager {
    private let store: SecureStore
    private let refresh: (String) async throws -> Session
    private var refreshTask: Task<Session, Error>?

    init(store: SecureStore, refresh: @escaping (String) async throws -> Session) {
        self.store = store; self.refresh = refresh
    }

    func validSession() async throws -> Session {
        let current = try loadSession()
        guard let current else { throw AuthError.notAuthenticated }
        if !current.isExpired { return current }
        if let task = refreshTask { return try await task.value }      // share in-flight refresh
        let task = Task { () throws -> Session in
            let new = try await refresh(current.refreshToken)
            try save(new)
            return new
        }
        refreshTask = task
        defer { refreshTask = nil }
        return try await task.value
    }

    func logout() throws { try store.remove("session") }

    private func loadSession() throws -> Session? {
        guard let data = try store.get("session") else { return nil }
        return try JSONDecoder().decode(Session.self, from: data)
    }
    private func save(_ session: Session) throws {
        try store.set(JSONEncoder().encode(session), for: "session")
    }
}
```

## Conventions

- **PKCE only** (no implicit flow / embedded secret); login via `ASWebAuthenticationSession`;
  validate `state` (see [`skills/security/ios/oauth2.md`](../../../skills/security/ios/oauth2.md)).
- **Tokens in Keychain** via `SecureStore` (`...ThisDeviceOnly`); cleared on logout.
- **Single-flight refresh** through the actor; `AuthInterceptor` retries 401 once.
- **Testing:** fake `SecureStore` + a stub `refresh`; assert one refresh under concurrency.
