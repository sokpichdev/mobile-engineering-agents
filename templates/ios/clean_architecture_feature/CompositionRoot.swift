//  CompositionRoot.swift
//  Clean Architecture Feature template — wires the dependency graph in one place.
//  Production factory + a DEBUG preview/test factory injecting stubs.

import Foundation

public enum ArticlesComposition {

    /// Production wiring: real client -> repository -> use case -> ViewModel.
    @MainActor
    public static func makeViewModel(client: APIClient) -> ArticlesViewModel {
        let repository = RemoteArticleRepository(client: client)
        let useCase = FetchArticlesUseCase(repository: repository)
        return ArticlesViewModel(fetch: useCase)
    }

    #if DEBUG
    /// Preview/test wiring: in-memory stub repository, no network.
    @MainActor
    public static func makePreviewViewModel(
        result: Result<[Article], DomainError> = .success(Article.samples)
    ) -> ArticlesViewModel {
        let repository = StubArticleRepository(result: result)
        return ArticlesViewModel(fetch: FetchArticlesUseCase(repository: repository))
    }
    #endif
}

#if DEBUG
/// Simple stub used by previews and tests — no mocking framework required.
final class StubArticleRepository: ArticleRepository {
    private let result: Result<[Article], DomainError>
    init(result: Result<[Article], DomainError>) { self.result = result }

    func latest(refresh: Bool) async throws -> [Article] {
        try result.get()
    }
}

extension Article {
    static let samples: [Article] = [
        Article(id: "1", title: "Clean Architecture on iOS", author: "Ada", publishedAt: .now),
        Article(id: "2", title: "Swift Concurrency in Practice", author: "Linus",
                publishedAt: .now.addingTimeInterval(-3600))
    ]
}
#endif
