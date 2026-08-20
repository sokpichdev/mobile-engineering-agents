---
platform: ios
---

# Skill: Unit Testing

## Overview

Unit tests verify one component in isolation — a use case, ViewModel, mapper, or repository
— with its dependencies replaced by test doubles. They are the **base of the test pyramid**:
fast, deterministic, and numerous. On iOS, prefer the **Swift Testing** framework
(`@Test`/`#expect`) for new code; XCTest remains fine for legacy. Swift Testing requires a
Swift 6 toolchain (Xcode 16 or later) rather than any particular deployment target, so
codebases pinned to older toolchains — common on projects still supporting an iOS 13 or 14
floor — should use XCTest, which remains fully supported. The prerequisite for good unit
tests is testable design: dependency injection through protocols and injectable `Date`/ids.

## Use Cases

- Business logic (use cases), presentation logic (ViewModels), DTO mappers.
- Edge-case and error-path verification.
- Regression tests accompanying bug fixes.

## Best Practices

- Follow **AAA** (Arrange, Act, Assert); keep one behavior per test.
- **Inject** dependencies (clients, clock, ids) so tests are deterministic.
- Name tests by behavior: `method_condition_expectedResult`.
- Cover **errors, empties, and boundaries** first, not just the happy path.
- Use **fakes/stubs** over heavy mocking frameworks; keep doubles simple.

## Anti-Patterns

- ❌ Hitting the real network/disk/clock (flaky, slow).
- ❌ Asserting on private implementation details.
- ❌ One giant test asserting many unrelated things.
- ❌ Non-deterministic data (`Date()`, random ids) in assertions.
- ❌ Only happy-path coverage.

## Checklist

- [ ] Logic covered with isolated, deterministic tests.
- [ ] Dependencies injected and faked.
- [ ] Error/empty/boundary cases tested.
- [ ] Behavior-focused names; one focus per test.
- [ ] No real network/clock/randomness.

## Swift Examples

```swift
import Testing

struct TransferUseCaseTests {
    @Test func execute_withSufficientFunds_succeeds() async throws {
        let repo = StubAccountRepository(balanceCents: 10_000)
        let sut = TransferUseCase(repository: repo)

        let result = try await sut.execute(amountCents: 5_000, to: "acct-2")

        #expect(result.remainingCents == 5_000)
    }

    @Test func execute_withInsufficientFunds_throwsInsufficientFunds() async {
        let repo = StubAccountRepository(balanceCents: 1_000)
        let sut = TransferUseCase(repository: repo)

        await #expect(throws: TransferError.insufficientFunds) {
            try await sut.execute(amountCents: 5_000, to: "acct-2")
        }
    }
}

// Simple fake — no mocking framework needed
final class StubAccountRepository: AccountRepository {
    var balanceCents: Int
    init(balanceCents: Int) { self.balanceCents = balanceCents }
    func balance() async throws -> Int { balanceCents }
}
```

## Testing Presenters (UIKit)

A UIKit MVP presenter test needs two doubles: a **spy view** that conforms to the view
protocol and records what the presenter called on it (loading shown/hidden, reload, error
handling), and a **stub repository** that conforms to the Domain-layer repository protocol
and returns a fixed `Result` instead of hitting the network. Because the presenter hops off
the calling thread into `Task { }` for its repository call, its state does not update
synchronously — assertions must wait on an `XCTestExpectation` fulfilled from a view
callback (e.g. `onReloadList`) rather than reading `sut.items` immediately after calling
into the presenter, which would race the `Task` and make the test flaky.

The doubles below are copied verbatim from the UIKit MVP screen template's presenter test
file — see
[`../../../templates/ios/uikit_mvp_screen/`](../../../templates/ios/uikit_mvp_screen/) for
the full suite, including the failure-path and refresh tests, and
[`../../architecture/ios/mvp.md`](../../architecture/ios/mvp.md) for the MVP layering these
tests assume. `ArticleRepository` is the Domain-layer protocol the stub implements; it is
declared once in
[`../../architecture/ios/repository_pattern.md`](../../architecture/ios/repository_pattern.md)
and is never redeclared in test code.

```swift
import XCTest

@MainActor
final class ArticleListPresenterTests: XCTestCase {

    func test_onViewDidLoad_populatesItemsAndReloadsTheList() {
        let view = ArticleListViewSpy()
        let sut = ArticleListPresenter(
            view: view,
            articles: ArticleRepositoryStub(result: .success([Article.fixture()]))
        )

        let reloaded = expectation(description: "list reloaded")
        view.onReloadList = { reloaded.fulfill() }

        sut.onViewDidLoad()

        wait(for: [reloaded], timeout: 1.0)
        XCTAssertEqual(sut.items.count, 1)
        XCTAssertEqual(view.loadingShownCount, 1)
        XCTAssertEqual(view.loadingHiddenCount, 1)
    }
}

// MARK: - Test doubles

@MainActor
private final class ArticleRepositoryStub: ArticleRepository {
    let result: Result<[Article], Error>
    private(set) var receivedRefreshFlags: [Bool] = []

    init(result: Result<[Article], Error>) { self.result = result }

    func latest(refresh: Bool) async throws -> [Article] {
        receivedRefreshFlags.append(refresh)
        return try result.get()
    }
}

@MainActor
private final class ArticleListViewSpy: ArticleListViewProtocol {
    private(set) var loadingShownCount = 0
    private(set) var loadingHiddenCount = 0
    var onReloadList: (() -> Void)?
    var onHandleApiError: ((Error) -> Void)?

    func showLoading() { loadingShownCount += 1 }
    func hideLoading() { loadingHiddenCount += 1 }
    func reloadList() { onReloadList?() }
    func handleApiError(error: Error) { onHandleApiError?(error) }
}
```

The template's file also defines `ArticleListTestError`, a screen-scoped error enum used by
its failure-path test, and marks all three doubles `private` — the norm for doubles scoped
to a single test file.

## Common Interview Questions

- What makes a good unit test (FIRST principles)?
- How do you make time-dependent code testable?
- Stub vs mock vs fake vs spy?
- Why avoid asserting on private internals?
- Swift Testing vs XCTest?

## AI Implementation Notes

- Generate unit tests alongside any non-trivial logic; inject `Date`/ids.
- Prefer Swift Testing `@Test`/`#expect` where the toolchain supports it; on older
  toolchains or legacy targets use XCTest — see
  [Testing Presenters (UIKit)](#testing-presenters-uikit). Use simple fakes.
- Always include at least one error-path test.
- Related: [`integration_testing.md`](integration_testing.md),
  [`../../../standards/testing_standards.md`](../../../standards/testing_standards.md),
  [`../../../templates/ios/unit_test_template/`](../../../templates/ios/unit_test_template/).
