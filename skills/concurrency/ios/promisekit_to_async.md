---
platform: ios
---

# Skill: Bridging PromiseKit and Completion Handlers to async/await

## Overview

A legacy codebase does not need to remove PromiseKit to gain testable presentation logic.
Introducing one thin `async` adapter per data source makes every consumer behind it
injectable and awaitable, while the existing promise-based singleton keeps serving every
call site not yet migrated. That is a per-screen migration with no big-bang step — the only
kind of migration that actually finishes in a codebase of a thousand-plus files. The adapter
conforms to the existing repository protocol; nothing upstream of it changes shape, so a
presenter can be moved onto `async`/`await` and unit-tested without touching the network
layer or any other screen.

## Use Cases

- Making a presenter or view model testable without waiting for a framework removal project.
- Adopting `async`/`await` in new code while PromiseKit still serves the rest of the app.
- Unifying error handling across two async styles (promises and completion handlers) behind
  one `async throws` signature.
- Migrating one screen's data dependency at a time, verified by its own test suite, instead
  of a repository-wide rewrite.

## Best Practices

- Bridge once, at the repository boundary — not at each call site that needs the value.
- Prefer `withCheckedThrowingContinuation` over the unsafe variant; the runtime checks are
  the whole point.
- Resume the continuation on every path through the callback, exactly once.
- Keep the adapter a plain, non-isolated type; let the caller (a `@MainActor` presenter) own
  which actor the awaited value lands on.
- Adapt one data source per task — the one the current change already touches.
- Give the adapter its own unit tests that stub the legacy singleton and assert both the
  success and failure paths resume correctly.

## Anti-Patterns

- ❌ Resuming a continuation twice, or never. `withCheckedThrowingContinuation` traps on a
  double resume and leaks the awaiting task forever on a zero resume. Every path through the
  callback must resume exactly once — a promise chain with both `.done` and `.catch` covers
  every path; a chain with only `.done` does not, because the rejection path never resumes
  and the caller hangs.
- ❌ Reaching for `withUnsafeThrowingContinuation` to silence the checked variant's
  diagnostics. The checked variant exists specifically to catch double- and zero-resume bugs
  in debug builds; swapping to the unsafe one to make a warning go away removes the safety
  net instead of fixing the bug.
- ❌ Bridging at each call site instead of once at the repository boundary. Wrapping the same
  promise call in a continuation inside every presenter that needs it duplicates the resume
  logic — and its bugs — everywhere it's copied.
- ❌ Wrapping a source that can emit more than once. A continuation models exactly one
  resume; a repeating source (progress callbacks, a socket, a value that updates over time)
  needs `AsyncStream`, not a continuation forced to fire early and drop the rest.
- ❌ Assuming callback threads. The adapter is not `@MainActor`; the legacy callback may fire
  on a background queue. Do not read or write UI state inside the continuation's closure —
  let the awaiting `@MainActor` presenter be the place actor isolation is enforced.

## Checklist

- [ ] The adapter conforms to the existing repository protocol; no new protocol is declared.
- [ ] Every path through the legacy callback resumes the continuation exactly once.
- [ ] `withCheckedThrowingContinuation` is used, not the unsafe variant.
- [ ] The bridge lives in one place (the repository implementation), not duplicated at call
      sites.
- [ ] A source that can call back more than once is modeled with `AsyncStream`, not a
      continuation.
- [ ] The adapter does not assume or depend on which thread the legacy callback fires on.
- [ ] A unit test covers both the success and failure paths of the adapter.

## Swift Examples

`ArticleRepository` already exists in this toolkit — see
[`../../architecture/ios/repository_pattern.md`](../../architecture/ios/repository_pattern.md),
which declares `func latest(refresh: Bool) async throws -> [Article]`. It is referenced here,
never redeclared. What follows are the two adapters that conform to it.

```swift
// Data — adapts a PromiseKit source to the existing ArticleRepository protocol
struct ArticleCloudRepository: ArticleRepository {
    func latest(refresh: Bool) async throws -> [Article] {
        try await withCheckedThrowingContinuation { continuation in
            ArticleCloud.shared.getArticles(forceRefresh: refresh)
                .done { continuation.resume(returning: $0) }
                .catch { continuation.resume(throwing: $0) }
        }
    }
}
```

The completion-handler variant, for data sources that never used PromiseKit:

```swift
// Data — completion-handler source
struct LegacyArticleRepository: ArticleRepository {
    func latest(refresh: Bool) async throws -> [Article] {
        try await withCheckedThrowingContinuation { continuation in
            ArticleCloud.shared.getArticles(forceRefresh: refresh) { result in
                continuation.resume(with: result)   // Result<[Article], Error>
            }
        }
    }
}
```

A presenter depends on `ArticleRepository` and is unaware which adapter backs it:

```swift
// Presentation — unaffected by which adapter is injected
@MainActor
final class ArticleListPresenter: ArticleListPresenterProtocol {
    private weak var view: ArticleListViewProtocol?
    private let articles: ArticleRepository
    private(set) var items: [Article] = []

    init(view: ArticleListViewProtocol, articles: ArticleRepository) {
        self.view = view
        self.articles = articles
    }

    func onViewDidLoad() {
        Task { [weak self] in
            guard let self else { return }
            do {
                self.items = try await self.articles.latest(refresh: false)
                self.view?.reloadList()
            } catch {
                self.view?.handleApiError(error: error)
            }
        }
    }
}
```

A test doubles `ArticleRepository` directly and never touches `ArticleCloud` or PromiseKit:

```swift
// Test — no PromiseKit, no ArticleCloud.shared
struct StubArticleRepository: ArticleRepository {
    var result: Result<[Article], Error>
    func latest(refresh: Bool) async throws -> [Article] { try result.get() }
}
```

## Common Interview Questions

- Why does adopting `async`/`await` in a legacy codebase not require removing PromiseKit
  first?
- What happens if a `withCheckedThrowingContinuation` closure resumes twice? What if it never
  resumes?
- Why is `withUnsafeThrowingContinuation` the wrong default choice?
- Where should a promise-to-async bridge live, and why does that location matter for testing?
- Why can't a continuation wrap a source that emits more than one value?
- Why must the adapter avoid assuming which thread the legacy callback runs on?

## AI Implementation Notes

- Introduce an adapter only for the data source a task already touches. Never open a
  migration that rewrites unrelated call sites, presenters, or repositories as a side effect.
- Conform the adapter to the existing repository protocol; do not redeclare or reshape the
  protocol to fit the adapter.
- Default to `withCheckedThrowingContinuation`; only reach for `AsyncStream` when the wrapped
  source can genuinely emit more than once.
- Generate a unit test alongside the adapter covering both the success (`.done` /
  completion-success) and failure (`.catch` / completion-failure) paths.
- Related: [`../../architecture/ios/repository_pattern.md`](../../architecture/ios/repository_pattern.md),
  [`../../architecture/ios/mvp.md`](../../architecture/ios/mvp.md),
  [`../../architecture/ios/dependency_injection.md`](../../architecture/ios/dependency_injection.md).
