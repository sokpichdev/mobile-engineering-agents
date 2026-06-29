//  MockURLProtocol.swift
//  Drop-in URLProtocol stub for integration tests. Register it on an ephemeral
//  URLSessionConfiguration and set `requestHandler` per test. No live network.
//
//  Usage:
//    let config = URLSessionConfiguration.ephemeral
//    config.protocolClasses = [MockURLProtocol.self]
//    MockURLProtocol.requestHandler = { request in
//        let data = try Fixture.load("articles_success.json")
//        let response = HTTPURLResponse(url: request.url!, statusCode: 200,
//                                       httpVersion: nil, headerFields: nil)!
//        return (response, data)
//    }
//    let session = URLSession(configuration: config)

import Foundation

final class MockURLProtocol: URLProtocol {
    /// Set per test. Throw to simulate a transport error.
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

/// Loads a JSON fixture from the test bundle's Fixtures directory.
enum Fixture {
    static func load(_ name: String, bundle: Bundle = .main) throws -> Data {
        guard let url = bundle.url(forResource: name, withExtension: nil) else {
            throw NSError(domain: "Fixture", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "Missing fixture \(name)"])
        }
        return try Data(contentsOf: url)
    }
}
