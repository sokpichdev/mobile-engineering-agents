# Standard: Testing Standards

Rules for tests. Enforced by the [Testing Expert](../agents/testing_expert.md). See the
[testing skills](../skills/testing/).

## Pyramid

- **Many** fast unit tests (logic), **some** integration tests (collaboration), **few** UI
  tests (critical journeys). Don't invert the pyramid.

## Principles (FIRST)

- **Fast** — milliseconds; no real network/disk/sleep.
- **Isolated** — no shared state or test ordering dependencies.
- **Repeatable** — deterministic; inject `Date`, ids, randomness, and clients.
- **Self-validating** — clear pass/fail; no manual inspection.
- **Timely** — written with (or before) the code.

## Structure & Naming

- **AAA**: Arrange, Act, Assert. One behavior focus per test.
- Name by behavior: `method_condition_expectedResult`.
- Prefer **Swift Testing** (`@Test`/`#expect`) for new code; XCTest acceptable for legacy.

```swift
@Test func transfer_withInsufficientFunds_throws() async {
    let sut = TransferUseCase(repository: StubAccountRepository(balanceCents: 0))
    await #expect(throws: TransferError.insufficientFunds) {
        try await sut.execute(amountCents: 100, to: "x")
    }
}
```

## Coverage Expectations

- Use cases, ViewModels, mappers, and repositories: cover **success and error/empty/boundary** paths.
- Every bug fix ships with a **failing-first regression test**.
- Aim for meaningful coverage of business logic; don't chase a coverage % with trivial tests.

## Test Doubles

- Prefer simple **fakes/stubs** over heavy mocking frameworks.
- Doubles live in a `TestSupport`/`Mocks` target; fixtures stored as files.

## Async & Concurrency

- Use `await`; **never** `sleep` to wait — use expectations/polling.
- Test cancellation behavior for async APIs.

## UI Tests

- Cover only critical journeys; query by **accessibility identifier**; wait with
  `waitForExistence`; stub the backend via launch arguments.

## CI

- Tests run on every PR and must pass to merge (see [`git_standards.md`](git_standards.md)).
