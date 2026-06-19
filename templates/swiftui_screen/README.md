# Template: SwiftUI Screen

A screen with a ViewModel, single state enum, and full state handling. See
[`standards/swiftui_standards.md`](../../standards/swiftui_standards.md) and
[`skills/architecture/mvvm.md`](../../skills/architecture/mvvm.md).

## Folder Structure

```text
Presentation/
├── {{Screen}}View.swift
├── {{Screen}}ViewModel.swift
├── ViewState.swift            // shared generic state enum
└── Subviews/
    ├── {{Screen}}Content.swift
    └── ErrorView.swift
```

## State

```swift
enum ViewState<T: Equatable>: Equatable {
    case idle, loading, loaded(T), failed(String)
}
```

## ViewModel

```swift
import Observation

@MainActor
@Observable
final class {{Screen}}ViewModel {
    private(set) var state: ViewState<[{{Item}}]> = .idle
    private let fetch: Fetch{{Item}}UseCase

    init(fetch: Fetch{{Item}}UseCase) { self.fetch = fetch }

    func load() async {
        state = .loading
        do {
            let items = try await fetch.execute()
            state = .loaded(items)
        } catch {
            state = .failed("Something went wrong. Pull to retry.")
        }
    }
}
```

## View

```swift
import SwiftUI

struct {{Screen}}View: View {
    @State private var viewModel: {{Screen}}ViewModel

    init(viewModel: {{Screen}}ViewModel) { _viewModel = State(initialValue: viewModel) }

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView().accessibilityLabel("Loading")
            case .loaded(let items) where items.isEmpty:
                ContentUnavailableView("Nothing here yet", systemImage: "tray")
            case .loaded(let items):
                {{Screen}}Content(items: items)
            case .failed(let message):
                ErrorView(message: message) { Task { await viewModel.load() } }
            }
        }
        .navigationTitle("{{Screen}}")
        .task { await viewModel.load() }
    }
}
```

## Conventions

- **Thin view**, logic in the ViewModel; side effects in `.task`.
- **Single state enum** covering idle/loading/loaded/empty/error.
- **DI** via init; previews inject a stub use case for each state.
- **Accessibility:** labels + traits; semantic fonts; identifiers for tests.
- **Testing:** ViewModel unit-tested (success + error); see [unit_test_template](../unit_test_template/).

## Preview

```swift
#Preview("Loaded") {
    {{Screen}}View(viewModel: .init(fetch: Stub{{Item}}UseCase(result: .success(.sample))))
}
```
