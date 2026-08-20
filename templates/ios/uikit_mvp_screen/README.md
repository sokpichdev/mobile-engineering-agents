# Template: UIKit MVP Screen

A programmatic UIKit screen built on the four-file MVP convention — Contract, View, View
Controller, Presenter — plus a complete presenter test file. This is the corrected pattern:
every dependency is injected through an initializer, and no work happens in `init`. See
[`../../../skills/architecture/ios/mvp.md`](../../../skills/architecture/ios/mvp.md).

## Folder Structure

```text
uikit_mvp_screen/
├── ArticleListContract.swift        // view + presenter protocols, and the coordinator delegate
├── ArticleListView.swift            // UIView subclass owning all layout and subviews
├── ArticleListViewController.swift  // lifecycle, presenter wiring, navigation triggers
├── ArticleListPresenter.swift       // all presentation logic and state; no `import UIKit`
└── ArticleListPresenterTests.swift  // presenter tests: spy view + stub repository
```

> The files use a sample `Article` / `ArticleList` feature. Rename `Article`/`ArticleList` to
> your real domain entity and screen name when you copy this bundle into your codebase.

## How the pieces connect

```text
ArticleListCoordinator → ArticleListViewController.make(articles:delegate:)
                              │
                    ArticleListView (layout)   ArticleListPresenter (logic)
                              │                          │
                              └──── ArticleListViewProtocol / ArticleListPresenterProtocol ────┘
                                                          │
                                                  ArticleRepository (protocol)
```

`ArticleListViewController.make(articles:delegate:)` is the only supported construction
path: it builds the view controller, then builds the presenter with a reference to that view
controller, then returns the fully wired screen. A coordinator is the only caller of `make`
and the only conformer of `ArticleListCoordinatorDelegate` — see
[`../../../skills/architecture/ios/coordinator_navigation.md`](../../../skills/architecture/ios/coordinator_navigation.md).

## Conventions Demonstrated

- **Contract** declares `ArticleListViewProtocol`, `ArticleListPresenterProtocol`, and
  `ArticleListCoordinatorDelegate` — protocols only, no implementation.
- **View** (`ArticleListView`) owns every subview and every constraint, built once with
  UIKit's own layout anchors (no third-party layout library) — see
  [`../../../skills/ui/ios/uikit_view_layer.md`](../../../skills/ui/ios/uikit_view_layer.md).
- **View Controller** owns lifecycle, presenter wiring, and navigation triggers only, and
  uses a plain `UITableViewDataSource` conformance (not a diffable data source, since this
  toolkit's `Article` entity is not `Hashable`).
- **Presenter** is `@MainActor final`, holds the view `weak`, takes every dependency through
  `init` as a protocol, and does no work in `init` — loading starts from the explicit
  `onViewDidLoad()` entry point, and `refresh()` is a behaviorally distinct entry point that
  forwards `refresh: true` to the repository.
- **Tests** cover the success path, the failure path, and the `refresh()`/`onViewDidLoad()`
  distinction, using a spy view and a stub repository — no real network, no
  `UIApplication.shared`.

## Assumptions

- `ApiProtocol` (`showLoading()`, `hideLoading()`, `handleApiError(error:)`) and
  `PresenterProtocol` (empty, `@MainActor`) are assumed to already exist in the host app and
  are shared across every MVP screen — this bundle references them but does not declare
  them.
- `ArticleRepository` (`func latest(refresh: Bool) async throws -> [Article]`) is the Domain
  protocol defined in
  [`../../../skills/architecture/ios/repository_pattern.md`](../../../skills/architecture/ios/repository_pattern.md)
  — it is referenced here, never redeclared.
- `Article.fixture()` in the test file is expected from the host app's own test helpers.

## Usage

1. Copy the five files into your feature module.
2. Rename `Article`/`ArticleList` throughout to your real domain entity and screen name.
3. Point the injected `ArticleRepository` at your real Data-layer implementation.
4. Wire a coordinator that conforms to `ArticleListCoordinatorDelegate` and calls
   `ArticleListViewController.make(articles:delegate:)` — see
   [`../../../skills/architecture/ios/coordinator_navigation.md`](../../../skills/architecture/ios/coordinator_navigation.md).
5. Run `ArticleListPresenterTests.swift` as-is once `Article.fixture()` resolves in your test
   target, and extend it with coverage for your screen's own presentation rules.

> These `.swift` files are illustrative, not part of a compiled package — this folder is not
> an Xcode/SwiftPM target. Cross-file symbols (`Article`, `ApiProtocol`, `PresenterProtocol`,
> `Article.fixture()`) will not resolve if you try to build this folder in isolation; they
> resolve once the files are copied into a host app that already supplies those types.

## See also

- [`../../../skills/architecture/ios/mvp.md`](../../../skills/architecture/ios/mvp.md)
- [`../../../standards/uikit_standards.md`](../../../standards/uikit_standards.md)
- [`../../../checklists/uikit_review.md`](../../../checklists/uikit_review.md)
- [`../../../skills/architecture/ios/coordinator_navigation.md`](../../../skills/architecture/ios/coordinator_navigation.md)
- [`../../../skills/ui/ios/uikit_view_layer.md`](../../../skills/ui/ios/uikit_view_layer.md)
- [`../clean_architecture_feature/`](../clean_architecture_feature/)
