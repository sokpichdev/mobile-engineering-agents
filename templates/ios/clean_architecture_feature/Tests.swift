//  Tests.swift
//  Clean Architecture Feature template — representative tests (Swift Testing).
//  Deterministic: simple stubs, no real network/clock.

import Testing
import Foundation

// MARK: - Use case

struct FetchArticlesUseCaseTests {

    @Test func execute_sortsByPublishedDateDescending() async throws {
        let older = Article(id: "1", title: "Old", author: "A",
                            publishedAt: Date(timeIntervalSince1970: 0))
        let newer = Article(id: "2", title: "New", author: "B",
                            publishedAt: Date(timeIntervalSince1970: 1_000))
        let sut = FetchArticlesUseCase(repository: StubRepo(.success([older, newer])))

        let result = try await sut.execute()

        #expect(result.map(\.id) == ["2", "1"])
    }

    @Test func execute_propagatesDomainError() async {
        let sut = FetchArticlesUseCase(repository: StubRepo(.failure(.network)))

        await #expect(throws: DomainError.network) {
            try await sut.execute()
        }
    }
}

// MARK: - ViewModel

@MainActor
struct ArticlesViewModelTests {

    @Test func load_success_setsLoaded() async {
        let article = Article(id: "1", title: "T", author: "A", publishedAt: .now)
        let vm = ArticlesViewModel(fetch: FetchArticlesUseCase(repository: StubRepo(.success([article]))))

        await vm.load()

        #expect(vm.state == .loaded([article]))
    }

    @Test func load_failure_setsFailed() async {
        let vm = ArticlesViewModel(fetch: FetchArticlesUseCase(repository: StubRepo(.failure(.network))))

        await vm.load()

        if case .failed = vm.state { /* ok */ } else { Issue.record("expected .failed") }
    }
}

// MARK: - Mapper

struct ArticleMapperTests {
    @Test func toDomain_mapsAllFields() {
        let dto = ArticleDTO(id: "1", title: "T", author: "A",
                             publishedAt: Date(timeIntervalSince1970: 10))
        let entity = ArticleMapper.toDomain(dto)
        #expect(entity == Article(id: "1", title: "T", author: "A",
                                  publishedAt: Date(timeIntervalSince1970: 10)))
    }
}

// MARK: - Test double

private struct StubRepo: ArticleRepository {
    let result: Result<[Article], DomainError>
    init(_ result: Result<[Article], DomainError>) { self.result = result }
    func latest(refresh: Bool) async throws -> [Article] { try result.get() }
}
