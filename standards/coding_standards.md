# Standard: Swift Coding Standards

Baseline rules for all Swift code. Enforced by [`.swiftlint.yml`](../.swiftlint.yml) where
possible. These are **law** — generated code must conform.

## Naming

- Types `UpperCamelCase`; methods, properties, cases `lowerCamelCase`.
- Booleans read as assertions: `isEnabled`, `hasLoaded`, `canSubmit`.
- Methods are verb phrases (`fetchAccounts()`); avoid `get` prefixes for accessors.
- Avoid abbreviations except well-known ones (`id`, `url`, `min`). No Hungarian notation.
- Protocols describe capability (`-able`/`-ing`) or role (`AccountRepository`).

```swift
// ✅                                   // ❌
struct AccountSummary {}               struct acct_summary {}
func loadTransactions() async {}       func getTxns() {}
var isAuthenticated: Bool              var auth: Bool
```

## Types & Immutability

- Prefer **value types** (`struct`/`enum`); use `class`/`actor` when reference semantics or
  isolation is required.
- Prefer `let` over `var`; minimize mutable state.
- Use `enum` for finite states instead of loose booleans/strings.
- Mark classes `final` unless designed for inheritance.

## Optionals & Safety

- **No force-unwrap (`!`), force-try (`try!`), or force-cast (`as!`)** on data that can be
  absent or untrusted. Use `guard let`/`if let`/`??`.
- Use `guard` for early exit; keep the happy path unindented.

```swift
// ✅
guard let user = session.user else { return }
// ❌
let user = session.user!
```

## Error Handling

- Use typed `Error` enums per domain; map errors at layer boundaries.
- Never silently swallow errors with `try?` unless the absence is genuinely fine (comment why).
- No empty `catch {}` blocks.

## Concurrency

- Use Swift Concurrency (`async/await`, `Task`, actors); avoid `DispatchQueue` for new code.
- UI types are `@MainActor`. Protect shared mutable state with actors.
- Always honor cancellation; cancel tasks in `deinit`/teardown.

## Functions & Files

- Functions do one thing; respect SwiftLint `function_body_length` / `cyclomatic_complexity`.
- One primary type per file (plus tightly-coupled helpers). Respect `file_length`.
- Order within a type: stored properties → init → public → private; group with `// MARK:`.

## Logging

- Use `os.Logger` with privacy redaction; **never log secrets/PII**.
- No `print()` in committed code.

```swift
import os
let log = Logger(subsystem: "com.app.networking", category: "http")
log.debug("Request \(endpoint.path, privacy: .public) user=\(userID, privacy: .private)")
```

## Documentation

- Document public APIs and non-obvious logic with `///` doc comments.
- Comments explain **why**, not what the code already says.

## Dependencies

- Prefer Swift Package Manager; pin versions. Justify each third-party dependency.
- Wrap third-party SDKs behind your own protocol to limit blast radius.
