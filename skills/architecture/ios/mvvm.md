---
platform: ios
---

# Skill: MVVM (Model-View-ViewModel)

## Overview

MVVM separates UI (`View`) from presentation logic (`ViewModel`) and domain data (`Model`).
The `ViewModel` exposes render-ready, observable state and handles user intent by calling
use cases; the `View` is a declarative function of that state. In SwiftUI, MVVM pairs
naturally with the Observation framework (`@Observable`) and Clean Architecture: ViewModels
live in the Presentation layer and depend on Domain use cases, never on networking or
persistence directly.

## Use Cases

- Any screen with non-trivial state (loading/error/content, forms, lists).
- Screens that need to be unit-tested without launching the UI.
- Decoupling UI from data sources so the same logic survives a UI redesign.

## Best Practices

- Model screen state as a **single enum** (`idle/loading/loaded(Data)/error(Message)`).
- Keep the `ViewModel` `@MainActor` and free of UIKit/SwiftUI imports beyond `Observation`.
- Inject dependencies (use cases) through the initializer via protocols.
- Keep the `View` thin: bind to state, send intents (`await vm.load()`), render.
- Make ViewModels reusable and testable — no global singletons inside them.

## Anti-Patterns

- ❌ "Massive ViewModel" doing networking, persistence, and mapping itself.
- ❌ Business logic in the `View` body or in `onAppear`.
- ❌ Scattered booleans (`isLoading`, `hasError`) instead of one state enum.
- ❌ ViewModel referencing concrete repositories/`URLSession` instead of use cases/protocols.
- ❌ Two sources of truth (model data duplicated into local `@State`).

## Checklist

- [ ] State is a single observable enum or struct.
- [ ] ViewModel is `@MainActor`, depends only on injected protocols.
- [ ] No networking/persistence in the View or ViewModel directly.
- [ ] Loading/error/empty/content all represented.
- [ ] ViewModel is unit-tested without the UI.

## Swift Examples

```swift
import Observation

enum ViewState<T> {
    case idle, loading, loaded(T), failed(String)
}

@MainActor
@Observable
final class AccountsViewModel {
    private(set) var state: ViewState<[Account]> = .idle
    private let fetchAccounts: FetchAccountsUseCase

    init(fetchAccounts: FetchAccountsUseCase) {
        self.fetchAccounts = fetchAccounts
    }

    func load() async {
        state = .loading
        do {
            let accounts = try await fetchAccounts.execute()
            state = accounts.isEmpty ? .loaded([]) : .loaded(accounts)
        } catch {
            state = .failed("Couldn't load accounts. Pull to retry.")
        }
    }
}
```

```swift
struct AccountsView: View {
    @State private var viewModel: AccountsViewModel

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading: ProgressView()
            case .loaded(let accounts): AccountList(accounts: accounts)
            case .failed(let message): ErrorView(message: message) { Task { await viewModel.load() } }
            }
        }
        .task { await viewModel.load() }
    }
}
```

## Common Interview Questions

- How does MVVM differ from MVC and MVP?
- Where does navigation logic belong in MVVM? (Coordinator/router, not the View.)
- How do you keep a ViewModel testable? (DI via protocols, no singletons, inject `Date`.)
- Why model state as an enum rather than booleans?
- How does `@Observable` differ from `ObservableObject`/`@Published`?

## AI Implementation Notes

- Default new ViewModels to `@MainActor @Observable`. Inject use cases through the init.
- Always generate the state enum and handle every case in the View.
- Never call `URLSession`/repositories from the ViewModel — go through a use case protocol.
- Generate a unit test alongside the ViewModel covering success and failure paths.
- Related: [`clean_architecture.md`](clean_architecture.md),
  [`dependency_injection.md`](dependency_injection.md),
  [`../../../standards/swiftui_standards.md`](../../../standards/swiftui_standards.md).
