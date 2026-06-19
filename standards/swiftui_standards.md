# Standard: SwiftUI Standards

Rules for SwiftUI UI code. Complements [`coding_standards.md`](coding_standards.md). Enforced
in review by the [SwiftUI Expert](../agents/swiftui_expert.md) and
[Accessibility Expert](../agents/accessibility_expert.md).

## Views

- The `View` is a **function of state** — no networking, persistence, or business logic in `body`.
- Extract a subview when `body` exceeds ~40 lines or repeats.
- One primary `View` per file plus its tightly-coupled subviews.
- Side effects via `.task {}`/`.onChange`, delegated to the ViewModel.

```swift
// ✅ thin view bound to state
var body: some View {
    switch viewModel.state {
    case .loading: ProgressView()
    case .loaded(let items): List(items) { ItemRow($0) }
    case .failed(let msg): ErrorView(message: msg) { Task { await viewModel.load() } }
    case .idle: Color.clear.task { await viewModel.load() }
    }
}
```

## State Management

- One **source of truth** per piece of state; don't duplicate model data into local `@State`.
- New code uses **Observation** (`@Observable` ViewModels, `@State` to own them).
- `@State` for view-local value state; `@Binding` for two-way child state; `@Environment` for
  dependency/context.
- Model screen state as a **single enum** (`idle/loading/loaded/failed`), not scattered booleans.
- ViewModels are `@MainActor`.

## Navigation

- Use `NavigationStack` with **value-based** destinations (`navigationDestination(for:)`).
- Centralize routing (router/coordinator); don't scatter navigation booleans across views.

## Styling

- Use semantic colors and `Font` text styles; **no hardcoded font sizes** (Dynamic Type).
- Centralize design tokens (spacing, colors, typography) in a design system.
- Support light/dark mode; verify both.

## Performance

- `LazyVStack`/`List` for large collections; stable `id` in `ForEach`.
- Keep expensive work out of `body`; memoize derived values.
- Avoid unnecessary `AnyView`; prefer `@ViewBuilder`.

## Accessibility (required, not optional)

- Every interactive element has a label + correct trait.
- Layout survives the largest Dynamic Type size.
- Color is never the only signal; touch targets ≥ 44×44 pt.
- Add accessibility identifiers for UI testing. (Full gate:
  [`checklists/accessibility_review.md`](../checklists/accessibility_review.md).)

## Previews

- Provide previews with injected **stub** dependencies and multiple states (loading/error/loaded),
  plus a large-Dynamic-Type variant for key screens.
