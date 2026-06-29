# Template: Networking Layer

A reusable, testable network client. See
[`skills/networking/ios/rest_api.md`](../../../skills/networking/ios/rest_api.md) and
[`architecture/networking_architecture.md`](../../../architecture/networking_architecture.md).

## Folder Structure

```text
CoreNetworking/
├── APIClient.swift          // protocol + LiveAPIClient
├── Endpoint.swift
├── NetworkError.swift
├── JSONDecoder+API.swift
└── AuthInterceptor.swift
Tests/
└── APIClientTests.swift     // URLProtocol-stubbed
```

## Endpoint & Error

```swift
struct Endpoint<Response: Decodable> {
    let path: String
    var method = "GET"
    var query: [URLQueryItem] = []
    var body: Data?
    var headers: [String: String] = [:]
}

enum NetworkError: Error, Equatable {
    case invalidResponse
    case http(Int)
    case decoding
    case transport
    case graphQL([String])
}
```

## Client

```swift
protocol APIClient {
    func send<R: Decodable>(_ endpoint: Endpoint<R>) async throws -> R
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
        endpoint.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let data: Data, response: URLResponse
        do { (data, response) = try await session.data(for: request) }
        catch { throw NetworkError.transport }

        guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw NetworkError.http(http.statusCode) }
        do { return try decoder.decode(R.self, from: data) } catch { throw NetworkError.decoding }
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

## Conventions

- **DI:** inject `APIClient` into repositories; features never touch `URLSession`.
- **Errors:** typed `NetworkError`; validate status before decoding.
- **Retries:** add a retry wrapper only for idempotent requests (backoff + jitter).
- **Testing:** stub via `URLProtocol` (see [unit_test_template](../unit_test_template/) and
  [`skills/testing/ios/integration_testing.md`](../../../skills/testing/ios/integration_testing.md)).
