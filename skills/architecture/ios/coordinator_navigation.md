---
platform: ios
ui: uikit
---

# Skill: Coordinator Navigation

## Overview

In UIKit, navigation is imperative and view controllers push each other directly, which
couples every screen to its neighbors and makes flows untestable. A coordinator owns a
`UINavigationController` and decides what comes next; screens report events upward through a
delegate and know nothing about their successors. The view controller stays focused on
presenting its own state; the coordinator stays focused on sequencing screens.

## Use Cases

- A new UIKit flow with more than one screen, where the entry screen needs to decide what
  comes next without importing the next screen's dependencies directly.
- A flow already being substantially modified, where extracting navigation is part of the
  work already underway.
- Flows that branch (different next screens depending on a result) or that need to be
  started from more than one place (deep link, tab bar, push notification).
- Making a screen's "what happens next" logic unit-testable without driving a real
  `UINavigationController`.

## Best Practices

- The coordinator owns the `UINavigationController` it pushes onto; it never owns a
  navigation controller that a parent coordinator also owns.
- A screen depends on a small, screen-specific delegate protocol (for example
  `ArticleListCoordinatorDelegate`), not on the coordinator's concrete type.
- Delegate protocols are constrained to `AnyObject` and stored `weak` by the conforming
  screen, mirroring the `weak` view reference in
  [`mvp.md`](mvp.md) — without `weak`, the screen retains the coordinator, the coordinator
  retains the navigation controller, and the pair never deallocates after the flow ends.
- A parent coordinator holds its child coordinators in an array (or dictionary) and removes a
  child once its flow reports completion; the child never holds a strong reference back to
  its parent.
- `start()` is the single entry point that builds and pushes the flow's first screen; no
  other method builds view controllers.
- The coordinator injects a repository (or other Domain protocol) into the screen's factory,
  the same dependency it received through its own initializer — it does not reach for a
  singleton.

## Anti-Patterns

- ❌ A presenter that imports UIKit to push a view controller directly, bypassing the
  coordinator entirely.
- ❌ A singleton "Router" that every screen reaches into to navigate, recreating the same
  global-access problem `.shared` creates in a presenter.
- ❌ Retrofitting coordinators across an entire legacy app at once as a standalone change.
- ❌ A child coordinator holding a strong reference to its parent, or a parent forgetting to
  release a finished child — both leak the flow's entire view controller stack.
- ❌ A coordinator delegate protocol that is not constrained to `AnyObject`, which forces the
  conforming screen to hold it strongly and blocks the `weak` reference that prevents the
  retain cycle above.

## Checklist

- [ ] The coordinator, not the view controller or presenter, owns the `UINavigationController`
      and calls `pushViewController`.
- [ ] The screen depends on a small delegate protocol constrained to `AnyObject`, held `weak`.
- [ ] `start()` is the coordinator's only entry point for building its first screen.
- [ ] A parent coordinator holds child coordinators in a collection and removes a child when
      its flow finishes; no child holds a strong reference to its parent.
- [ ] Dependencies (repositories, other Domain protocols) are injected into the coordinator's
      initializer and passed on to the screen's factory — no `.shared` singleton access.
- [ ] This coordinator was introduced for a new flow, or for a flow already being
      substantially modified — not as a standalone retrofit of an existing flow.

See also [`mvp.md`](mvp.md), [`../../../checklists/uikit_review.md`](../../../checklists/uikit_review.md)
and [`../../../standards/uikit_standards.md`](../../../standards/uikit_standards.md).

## Swift Examples

```swift
protocol ArticleListCoordinatorDelegate: AnyObject {
    func articleListDidSelect(_ article: Article)
}

final class ArticleListCoordinator: ArticleListCoordinatorDelegate {
    private let navigationController: UINavigationController
    private let articles: ArticleRepository

    init(navigationController: UINavigationController, articles: ArticleRepository) {
        self.navigationController = navigationController
        self.articles = articles
    }

    func start() {
        let viewController = ArticleListViewController.make(articles: articles, delegate: self)
        navigationController.pushViewController(viewController, animated: false)
    }

    func articleListDidSelect(_ article: Article) {
        // push the detail screen
    }
}
```

`ArticleListCoordinatorDelegate` is the same protocol the screen's Contract file declares and
`ArticleListViewController.make(articles:delegate:)` is the same factory the screen exposes —
the coordinator is the delegate's only conformer and the factory's only caller, which is what
lets the screen stay ignorant of what comes after it. `ArticleRepository` is the Domain
protocol from [`repository_pattern.md`](repository_pattern.md); it is referenced here, never
redeclared, and passed straight through from the coordinator's initializer to the factory
call.

## Common Interview Questions

- What problem does a coordinator solve that pushing view controllers directly does not?
- Why does a screen depend on a small delegate protocol instead of the coordinator's
  concrete type?
- How do parent and child coordinators avoid retaining each other after a child flow
  finishes?
- Where does dependency injection happen in a coordinator-based flow?
- When would you *not* introduce a coordinator for a screen you are touching?

## AI Implementation Notes

- Coordinators apply to **new flows** and to flows **already being substantially modified**.
  Do **not** retrofit coordinators across existing screens as a standalone change — a legacy
  codebase can have hundreds of screens that already push view controllers directly, and
  converting them all "to fix it" is not a request anyone made; it turns an unrelated task
  into an app-wide rewrite with no test coverage guarding it.
- When a flow already has a coordinator and you are adding a screen to that flow, extend the
  existing coordinator rather than having the new screen push directly.
- Default new coordinator delegate protocols to `AnyObject`-constrained, and hold them `weak`
  on the conforming screen — this is the mechanism that prevents the screen/coordinator
  retain cycle.
- Inject dependencies into the coordinator's initializer and forward them to the screen's
  factory; never have the coordinator or the screen reach for a `.shared` singleton.
- Related: [`mvp.md`](mvp.md), [`repository_pattern.md`](repository_pattern.md),
  [`dependency_injection.md`](dependency_injection.md),
  [`../../../standards/uikit_standards.md`](../../../standards/uikit_standards.md),
  [`../../../checklists/uikit_review.md`](../../../checklists/uikit_review.md).
