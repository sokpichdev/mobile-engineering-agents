---
platform: ios
---

# Skill: REST API Integration

## Overview

REST integration on iOS means building a typed client over `URLSession` with `async/await`:
model endpoints as values, validate HTTP status, decode into DTOs, map errors to a typed
domain error, and expose the result behind a repository. Keep it in the Data layer; features
never touch `URLSession` directly.

## Use Cases

- Standard request/response APIs (the majority of mobile backends).
- CRUD resources, search, and command endpoints.
- Anywhere you need retries, auth headers, and consistent error handling.

## Best Practices

- Define a typed `Endpoint`/`Request` value (path, method, query, body, headers).
- Validate the **status code before decoding**; decode error bodies for non-2xx.
- Centralize decoding with a single configured `JSONDecoder`.
- Map all failures to a **typed `NetworkError`/domain error**.
- Inject the client via a **protocol**; set explicit timeouts; honor cancellation.

## Anti-Patterns

- ❌ One giant `NetworkManager` singleton with hardcoded URLs.
- ❌ `try?` swallowing decode errors.
- ❌ Decoding without checking the status code.
- ❌ Exposing `URLError`/status codes to the UI.
- ❌ Blocking the main thread on a sync request.

## Checklist

- [ ] Endpoints are typed values; no stringly-typed URL building scattered around.
- [ ] Status validated; non-2xx mapped to typed errors.
- [ ] Single shared, configured decoder.
- [ ] Client injected via protocol; testable with stubs.
- [ ] Timeouts set; cancellation honored.

## Swift Examples

```swift
struct Endpoint<Response: Decodable> {
    let path: String
    var method = "GET"
    var query: [URLQueryItem] = []
    var body: Data?
}

enum NetworkError: Error, Equatable {
    case invalidResponse, http(Int), decoding, transport
}

protocol APIClient {
    func send<R>(_ endpoint: Endpoint<R>) async throws -> R
}

final class LiveAPIClient: APIClient {
    private let session: URLSession
    private let baseURL: URL
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, baseURL: URL, decoder: JSONDecoder = .api) {
        self.session = session; self.baseURL = baseURL; self.decoder = decoder
    }

    func send<R: Decodable>(_ endpoint: Endpoint<R>) async throws -> R {
        var comps = URLComponents(url: baseURL.appendingPathComponent(endpoint.path),
                                  resolvingAgainstBaseURL: false)!
        comps.queryItems = endpoint.query.isEmpty ? nil : endpoint.query
        var request = URLRequest(url: comps.url!)
        request.httpMethod = endpoint.method
        request.httpBody = endpoint.body
        request.timeoutInterval = 30

        let (data, response): (Data, URLResponse)
        do { (data, response) = try await session.data(for: request) }
        catch { throw NetworkError.transport }

        guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw NetworkError.http(http.statusCode) }
        do { return try decoder.decode(R.self, from: data) }
        catch { throw NetworkError.decoding }
    }
}

extension JSONDecoder {
    static let api: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
```

## Common Interview Questions

- How do you map HTTP/transport errors to domain errors?
- Why validate the status code before decoding?
- How do you make the network layer testable?
- How do you handle authentication headers and 401 refresh?
- `URLSession` vs Alamofire — trade-offs?

## AI Implementation Notes

- Generate typed endpoints + an injectable `APIClient` protocol; never a singleton.
- Always validate status before decoding and map to a typed error.
- Pair with a repository ([`../../architecture/ios/repository_pattern.md`](../../architecture/ios/repository_pattern.md)).
- Related: [`pagination.md`](pagination.md),
  [`../../../templates/ios/networking_layer/`](../../../templates/ios/networking_layer/),
  [`../../../standards/networking_standards.md`](../../../standards/networking_standards.md).
