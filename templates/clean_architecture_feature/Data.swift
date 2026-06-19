//  Data.swift
//  Clean Architecture Feature template — Data layer.
//  DTO + mapper + repository implementation. DTOs never leak past this layer.

import Foundation

// MARK: - DTO (mirrors the wire format; decoded by the shared APIClient decoder)

struct ArticleDTO: Decodable {
    let id: String
    let title: String
    let author: String
    let publishedAt: Date          // shared decoder uses .iso8601 + convertFromSnakeCase
}

// MARK: - Mapper (pure, total, unit-tested)

enum ArticleMapper {
    static func toDomain(_ dto: ArticleDTO) -> Article {
        Article(id: dto.id, title: dto.title, author: dto.author, publishedAt: dto.publishedAt)
    }
}

// MARK: - Repository implementation

public final class RemoteArticleRepository: ArticleRepository {
    private let client: APIClient

    public init(client: APIClient) {
        self.client = client
    }

    public func latest(refresh: Bool) async throws -> [Article] {
        do {
            let dtos: [ArticleDTO] = try await client.send(Endpoint(path: "/articles"))
            return dtos.map(ArticleMapper.toDomain)
        } catch let error as NetworkError {
            throw Self.map(error)
        }
    }

    private static func map(_ error: NetworkError) -> DomainError {
        switch error {
        case .http(404): return .notFound
        case .http, .transport, .invalidResponse: return .network
        case .decoding, .graphQL: return .unexpected
        }
    }
}
