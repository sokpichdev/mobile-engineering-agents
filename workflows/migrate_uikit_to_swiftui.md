# Workflow: Migrate a UIKit Screen to SwiftUI

Strangler-fig procedure for incrementally replacing a UIKit + MVP screen with a SwiftUI + MVVM view layer while leaving UIKit in control of navigation.

## Objective

Replace one leaf screen's view layer with SwiftUI while UIKit retains ownership of navigation, ensuring the app builds, tests pass, and ships after every single step.

## Inputs

- Target UIKit screen (`<Name>Contract.swift`, `<Name>View.swift`, `<Name>ViewController.swift`, `<Name>Presenter.swift`).
- Existing Domain entity and repository protocol (e.g. `ArticleRepository`).
- Legacy data source or singleton reference, if not yet abstracted behind a repository protocol.

## Outputs

- New SwiftUI `View` and `@MainActor` `ObservableObject` view model consuming the existing repository protocol.
- `UIHostingController` factory wrapping the SwiftUI view, matching the old view controller's factory signature.
- Deleted legacy UIKit four-file screen files.
- Unit tests for the new view model covering success and error states.

## Step-by-Step Process

1. **Choose a leaf screen.** The target screen must have no child screens that it pushes directly, or must push only through a coordinator ([Coordinator Navigation](../skills/architecture/ios/coordinator_navigation.md)). Screens that push successors directly must be migrated last or refactored to use a coordinator first.
2. **Extract the repository seam first** if the presenter still calls a singleton or completion-handler API directly. Introduce an `async` repository protocol and adapter per [Bridging PromiseKit and Completion Handlers to async/await](../skills/concurrency/ios/promisekit_to_async.md). Do not skip this step — a SwiftUI view backed by a singleton is no more testable than the view controller it replaced.
3. **Write the SwiftUI view and view model.** Create an `@MainActor` `ObservableObject` view model that consumes the repository protocol (the same protocol used by the MVP presenter, per [MVP Architecture](../skills/architecture/ios/mvp.md)). Build the SwiftUI `View` rendering state from this view model.
4. **Host the SwiftUI view.** Wrap the view inside a `UIHostingController`. Expose a factory method (e.g. `make(articles:delegate:)`) on the hosting controller or a builder that matches the legacy `UIViewController.make(...)` signature, so all existing caller and navigation sites remain untouched.
5. **Delete old UIKit screen files.** Remove the old `<Name>Contract.swift`, `<Name>View.swift`, `<Name>ViewController.swift`, and `<Name>Presenter.swift` files in a dedicated commit once the new view layer is wired and verified.
6. **Leave navigation in UIKit.** The hosting controller continues to be pushed or presented by the host app's existing `UINavigationController` or coordinator. Do not attempt to replace UIKit navigation with `NavigationStack` during view layer migration.

## Validation Steps

- Target screen renders properly inside `UIHostingController`.
- All existing navigation call sites function without modifications outside the target screen factory.
- Unit tests for the new view model pass cleanly.
- Build succeeds with zero warnings or dead legacy file references.
- `markdownlint-cli2` and `markdown-link-check` pass.

## Failure Scenarios

- **Target screen is not a leaf screen** → Stop. Migrate its child screens first or extract navigation into a coordinator before proceeding.
- **Presenter logic is shared by multiple screens** → Extract the shared presentation or domain logic into a domain Use Case or shared service before migrating the view layer.
- **SwiftUI view requires a complex or unavailable UIKit control** → Wrap the legacy control in `UIViewRepresentable` rather than abandoning the migration or forcing a full redesign.

## AI Agent Instructions

- Execute steps sequentially; do not attempt big-bang migrations across navigation and view layers simultaneously.
- Preserve existing factory signatures so call sites outside the target screen remain unchanged.
- Ensure the repository seam is fully async and protocol-oriented before starting the SwiftUI view model.
- Write unit tests for the new view model before removing legacy presenter tests.

## Acceptance Criteria

- [ ] Target screen factory signature matches the original legacy screen factory.
- [ ] No call site outside the target screen factory was modified.
- [ ] Legacy four-file screen assets (`Contract`, `View`, `ViewController`, `Presenter`) are deleted.
- [ ] SwiftUI View Model is `@MainActor`, uses `ObservableObject`, and has unit tests for success and failure paths.
- [ ] Navigation remains owned by UIKit (`UINavigationController` / Coordinator).
