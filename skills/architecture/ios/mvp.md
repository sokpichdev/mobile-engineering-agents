---
platform: ios
ui: uikit
---

# Skill: MVP (Model-View-Presenter)

## Overview

MVP splits a screen into a passive View (the `UIViewController` plus its `UIView`), a
Presenter holding all presentation logic and state, and a Contract file declaring the two
protocols that join them. Unlike MVVM there is no binding mechanism: the presenter calls
explicit methods on the view. This makes it a natural fit for UIKit, where there is no
built-in observation of state. The Presenter belongs to the Presentation layer and depends
on Domain protocols only — it must never import UIKit.

## Use Cases

- Legacy UIKit screens that predate MVVM/Observation and are not being rewritten.
- Greenfield UIKit screens in a codebase that has standardized on MVP.
- Teams standardizing an existing UIKit codebase on a single, consistent pattern.
- Incrementally making untestable view controllers testable, one screen at a time.

## Best Practices

- The Contract file declares both protocols and nothing else — no implementation.
- The presenter is `@MainActor` and `final`.
- The view reference is `weak`.
- Every dependency is injected via the initializer as a protocol.
- No work happens in `init`; an explicit `onViewDidLoad()` entry point starts loading instead.
- State is exposed `private(set)` so only the presenter can mutate it.
- View protocol methods are imperative commands (`reloadList()`), never state setters.

## Anti-Patterns

- Calling `.shared` from a presenter instead of receiving a protocol through `init`.
- Firing network calls from `init` rather than from an explicit lifecycle entry point.
- Importing UIKit into a presenter.
- A "view protocol" that just exposes the whole view controller instead of focused commands.
- Presenters that reach into `UserDefaults` or `Date()` directly instead of receiving them
  as injected dependencies.

## Checklist

- [ ] Presenter takes every dependency through its initializer as a protocol — no `.shared`
      singleton access.
- [ ] Presenter's `init` performs no work: no network calls, no timers, no notification
      registration.
- [ ] Presenter holds the view `weak` and is marked `@MainActor`.
- [ ] Presenter has at least one unit test using a spy view and a stub repository.
- [ ] Contract file declares only the view and presenter protocols — no implementation.
- [ ] Presenter state is exposed `private(set)`.
- [ ] Loading starts from an explicit `onViewDidLoad()` (or equivalent) call, not from `init`
      or an unconditional `viewWillAppear`.

See also [`../../../checklists/uikit_review.md`](../../../checklists/uikit_review.md) and
[`../../../standards/uikit_standards.md`](../../../standards/uikit_standards.md).

## Swift Examples

```swift
// ArticleListContract.swift
@MainActor protocol ArticleListViewProtocol: ApiProtocol {
    func reloadList()
}

@MainActor protocol ArticleListPresenterProtocol: PresenterProtocol {
    var items: [Article] { get }
    func onViewDidLoad()
    func refresh()
}
```

```swift
// ANTI-PATTERN — unconstructible in a test
class ArticleListPresenter: ArticleListPresenterProtocol {
    weak private var view: ArticleListViewProtocol?
    private(set) var items: [Article] = []

    init(with view: ArticleListViewProtocol) {
        self.view = view
        loadArticles()                  // side effect in init
    }

    func loadArticles() {
        ArticleCloud.shared.getArticles(forceRefresh: false)   // concrete singleton
            .done { self.items = $0 }
    }
}
```

`ArticleRepository` lives in the Domain layer and is defined in
[`repository_pattern.md`](repository_pattern.md) — it is referenced here, never redeclared,
the same way `ApiProtocol` and `PresenterProtocol` are referenced without being restated.

```swift
// ArticleListPresenter.swift
@MainActor
final class ArticleListPresenter: ArticleListPresenterProtocol {
    private weak var view: ArticleListViewProtocol?
    private let articles: ArticleRepository
    private(set) var items: [Article] = []

    init(view: ArticleListViewProtocol, articles: ArticleRepository) {
        self.view = view
        self.articles = articles
    }

    func onViewDidLoad() { load(refresh: false) }
    func refresh() { load(refresh: true) }

    private func load(refresh: Bool) {
        view?.showLoading()
        Task { [weak self] in
            guard let self else { return }
            defer { self.view?.hideLoading() }
            do {
                self.items = try await self.articles.latest(refresh: refresh)
                self.view?.reloadList()
            } catch {
                self.view?.handleApiError(error: error)
            }
        }
    }
}
```

## Common Interview Questions

- How does MVP differ from MVVM and MVC?
- Why is the view reference held `weak`?
- Where does navigation belong? (A coordinator or the view controller — never the presenter.)
- How do you test a presenter without a running UI? (A spy conforming to the view protocol
  and a stub conforming to the repository protocol, with no real `UIApplication`.)
- Why must the presenter not import UIKit?

## AI Implementation Notes

- Do **not** convert existing MVP screens to MVVM. A working screen that already follows the
  four-file MVP convention stays MVP.
- When editing a UIKit screen, follow the surrounding MVP convention rather than introducing
  a different pattern for that one screen.
- Introduce the injected-repository seam (an `ArticleRepository`-style protocol replacing a
  `.shared` singleton call) only for screens you are already modifying — do not sweep the
  rest of the codebase to "fix" it as a side effect.
- Default new presenters to `@MainActor final`, with the view held `weak` and every
  dependency injected through `init` as a protocol.
- Never put loading logic in `init`; always expose an explicit `onViewDidLoad()` (or
  equivalent) entry point instead.
- Generate a unit test alongside the presenter covering success and failure paths, using a
  spy view and a stub repository.
- Related: [`mvvm.md`](mvvm.md), [`repository_pattern.md`](repository_pattern.md),
  [`dependency_injection.md`](dependency_injection.md),
  [`../../../standards/uikit_standards.md`](../../../standards/uikit_standards.md),
  [`../../../checklists/uikit_review.md`](../../../checklists/uikit_review.md).
