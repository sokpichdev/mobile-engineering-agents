# Skill: Integration Testing

## Overview

Integration tests verify that components **collaborate** correctly — e.g. repository +
decoder + `APIClient`, or use case + repository + cache. They sit in the **middle of the
test pyramid**: fewer than unit tests, broader in scope. The key technique is to stub the
**network boundary** (via `URLProtocol` or an injected fake client) and feed real JSON
fixtures, so you exercise real mapping/decoding/error handling without hitting a live server.

## Use Cases

- Verifying DTO decoding + mapping against real API fixtures.
- Repository behavior across cache + network (cache-then-network, fallbacks).
- Error mapping from HTTP status to domain errors end-to-end within the app.

## Best Practices

- Stub the **network at `URLProtocol`** (or inject a fake `APIClient`) — no real servers.
- Drive decoding with **real captured JSON fixtures**, including error/empty payloads.
- Test the **seams that unit tests skip**: decode → map → cache → return.
- Keep them **deterministic** (fixed fixtures, injected clock) and reasonably fast.
- Assert on **observable outcomes** (returned entities, stored state), not internals.

## Anti-Patterns

- ❌ Hitting the real backend (flaky, slow, environment-dependent).
- ❌ Re-testing pure logic already covered by unit tests.
- ❌ Hand-written JSON strings instead of representative fixtures.
- ❌ Non-deterministic fixtures (timestamps, ordering) leaking into assertions.
- ❌ Over-broad tests that fail for unrelated reasons.

## Checklist

- [ ] Network stubbed via `URLProtocol`/fake client; no live servers.
- [ ] Real JSON fixtures incl. error/empty cases.
- [ ] Cross-component seams exercised (decode→map→cache).
- [ ] Deterministic and reasonably fast.
- [ ] Asserts on outcomes, not internals.

## Swift Examples

```swift
import Testing
@testable import App

final class MockURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for r: URLRequest) -> URLRequest { r }
    override func startLoading() {
        guard let handler = Self.handler else { return }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }
    override func stopLoading() {}
}

struct AccountRepositoryIntegrationTests {
    @Test func accounts_decodesAndMapsFixture() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        MockURLProtocol.handler = { request in
            let json = try Fixture.load("accounts_success.json")
            return (HTTPURLResponse(url: request.url!, statusCode: 200,
                                    httpVersion: nil, headerFields: nil)!, json)
        }
        let client = LiveAPIClient(session: URLSession(configuration: config),
                                   baseURL: URL(string: "https://example.com")!)
        let repo = RemoteAccountRepository(client: client)

        let accounts = try await repo.accounts()

        #expect(accounts.count == 2)
        #expect(accounts.first?.name == "Checking")
    }
}
```

## Common Interview Questions

- How do you stub the network without a live server?
- What's the difference between unit and integration tests?
- Why use real JSON fixtures?
- How do you test error-status mapping end-to-end?
- How many integration tests vs unit tests (the pyramid)?

## AI Implementation Notes

- Use `URLProtocol` stubbing or an injected fake client; load JSON fixtures from files.
- Cover success, error-status, and malformed/empty payloads.
- Keep them deterministic; assert on returned domain entities.
- Related: [`unit_testing.md`](unit_testing.md), [`ui_testing.md`](ui_testing.md).
