# Template: Unit Test

Patterns and ready-to-copy scaffolding for deterministic unit + integration tests. See
[`standards/testing_standards.md`](../../standards/testing_standards.md) and the
[testing skills](../../skills/testing/).

## Folder Structure

```text
Tests/
├── {{Type}}Tests.swift          // behavior tests (AAA)
├── Mocks/
│   ├── Stub{{Dependency}}.swift  // simple fakes
│   └── MockURLProtocol.swift     // network stubbing for integration tests
└── Fixtures/
    ├── {{resource}}_success.json
    └── {{resource}}_error.json
```

## Files in this bundle

- `ExampleTests.swift` — Swift Testing unit tests (AAA, success + error paths) with a fake.
- `MockURLProtocol.swift` — drop-in `URLProtocol` stub for integration tests.

## Conventions

- **Swift Testing** (`@Test`/`#expect`) for new code; XCTest only for legacy.
- **AAA** structure; names read as `method_condition_expectedResult`.
- **Deterministic:** inject `Date`/ids/clients; no real network/disk/`sleep`.
- **Simple fakes** over heavy mocking frameworks; fixtures stored as JSON files.
- **Coverage:** success + error + empty + boundary; bug fixes get a failing-first regression test.

## Quick reference

```swift
@Test func methodName_condition_expectedResult() async throws {
    // Arrange
    let sut = SystemUnderTest(dependency: StubDependency(result: .success(.sample)))
    // Act
    let result = try await sut.run()
    // Assert
    #expect(result == .expected)
}
```
