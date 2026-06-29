---
platform: ios
---

# Skill: Dependency Injection

## Overview

Dependency Injection (DI) provides a type's collaborators from the outside (via
initializers or properties) instead of constructing them internally. It is the mechanism
that makes Clean Architecture testable: by depending on **protocols** and injecting
concrete implementations at a **composition root**, you can swap real services for test
doubles. Prefer **constructor injection**; reserve `@Environment` for SwiftUI-scoped values.

## Use Cases

- Making ViewModels/use cases/repositories unit-testable with stubs.
- Swapping implementations per environment (prod vs mock vs preview).
- Breaking hidden coupling to singletons.

## Best Practices

- **Constructor injection by default.** Dependencies are explicit init parameters.
- Depend on **protocols**, not concrete types.
- Wire everything in a single **composition root** (e.g. an app-level factory/container).
- Use SwiftUI `@Environment`/`EnvironmentObject` only for genuinely view-scoped dependencies.
- Provide **preview/test factories** that inject fakes.

## Anti-Patterns

- ❌ Service Locator / global singletons accessed deep inside types (hidden dependencies).
- ❌ Constructing `URLSession`/repositories inside a ViewModel.
- ❌ Heavyweight DI frameworks for a small app when initializers suffice.
- ❌ Optional injected dependencies with `nil` defaults that hide wiring mistakes.

## Checklist

- [ ] Dependencies are injected via init, not constructed internally.
- [ ] Types depend on protocols, not concretes.
- [ ] A single composition root wires the graph.
- [ ] Test/preview factories provide fakes.
- [ ] No global singletons reached from business logic.

## Swift Examples

```swift
// Manual constructor injection + a small composition root
protocol AuthService { func login(_ email: String, _ password: String) async throws -> Session }

@MainActor @Observable
final class LoginViewModel {
    private let auth: AuthService
    init(auth: AuthService) { self.auth = auth }   // injected
}

enum AppContainer {                                 // composition root
    static func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(auth: LiveAuthService(client: .live))
    }
    #if DEBUG
    static func previewLoginViewModel() -> LoginViewModel {
        LoginViewModel(auth: StubAuthService())
    }
    #endif
}
```

```swift
// SwiftUI environment injection for view-scoped values
private struct ThemeKey: EnvironmentKey { static let defaultValue = Theme.system }
extension EnvironmentValues { var theme: Theme {
    get { self[ThemeKey.self] } set { self[ThemeKey.self] = newValue } } }
```

## Common Interview Questions

- Constructor vs property vs method injection — when to use each?
- Why is Service Locator considered an anti-pattern?
- How does DI enable unit testing?
- What is a composition root?
- When (if ever) is a DI framework worth it on iOS?

## AI Implementation Notes

- Default to constructor injection with protocols; avoid singletons in generated code.
- Generate a composition root and a `#if DEBUG` preview/test factory with stubs.
- When generating a ViewModel, never `new` up its dependencies inside it.
- Related: [`mvvm.md`](mvvm.md), [`clean_architecture.md`](clean_architecture.md),
  [`repository_pattern.md`](repository_pattern.md).
