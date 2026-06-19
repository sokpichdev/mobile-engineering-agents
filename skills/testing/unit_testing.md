# Skill: Unit Testing

## Overview

Unit tests verify one component in isolation — a use case, ViewModel, mapper, or repository
— with its dependencies replaced by test doubles. They are the **base of the test pyramid**:
fast, deterministic, and numerous. On iOS, prefer the **Swift Testing** framework
(`@Test`/`#expect`) for new code; XCTest remains fine for legacy. The prerequisite for good
unit tests is testable design: dependency injection through protocols and injectable `Date`/ids.

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

## Common Interview Questions

- What makes a good unit test (FIRST principles)?
- How do you make time-dependent code testable?
- Stub vs mock vs fake vs spy?
- Why avoid asserting on private internals?
- Swift Testing vs XCTest?

## AI Implementation Notes

- Generate unit tests alongside any non-trivial logic; inject `Date`/ids.
- Prefer Swift Testing `@Test`/`#expect`; use simple fakes.
- Always include at least one error-path test.
- Related: [`integration_testing.md`](integration_testing.md),
  [`../../standards/testing_standards.md`](../../standards/testing_standards.md),
  [`../../templates/unit_test_template/`](../../templates/unit_test_template/).
