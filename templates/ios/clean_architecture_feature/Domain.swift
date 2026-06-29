//  Domain.swift
//  Clean Architecture Feature template — Domain layer (pure Swift, no framework imports).
//  Replace `Article`/`article` with your entity. Split into per-type files in real modules.

import Foundation

// MARK: - Entity

public struct Article: Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let author: String
    public let publishedAt: Date

    public init(id: String, title: String, author: String, publishedAt: Date) {
        self.id = id
        self.title = title
        self.author = author
        self.publishedAt = publishedAt
    }
}

// MARK: - Repository protocol (implemented in the Data layer)

public protocol ArticleRepository: Sendable {
    func latest(refresh: Bool) async throws -> [Article]
}

// MARK: - Domain error (mapped from transport errors in the Data layer)

public enum DomainError: Error, Equatable {
    case network
    case notFound
    case unexpected
}

// MARK: - Use case (one application operation)

public struct FetchArticlesUseCase: Sendable {
    private let repository: ArticleRepository

    public init(repository: ArticleRepository) {
        self.repository = repository
    }

    /// Returns the latest articles, newest first.
    public func execute(refresh: Bool = false) async throws -> [Article] {
        try await repository.latest(refresh: refresh)
            .sorted { $0.publishedAt > $1.publishedAt }
    }
}
