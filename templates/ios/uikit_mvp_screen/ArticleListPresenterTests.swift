//  ArticleListPresenterTests.swift
//  UIKit MVP screen template — presenter tests. Complete and runnable as-is once dropped
//  into a host app/test target: uses a spy view and a stub repository, no real network and
//  no `UIApplication.shared`, per ../../../skills/architecture/ios/mvp.md.
//
//  `Article.fixture()` is expected from the host app's own test helpers (every screen's
//  tests share one fixture factory per entity; this template does not redefine it).
//  `ArticleListViewSpy` implements only the `ApiProtocol` members this screen's contract
//  actually uses (`showLoading`, `hideLoading`, `handleApiError(error:)`) plus
//  `reloadList()` from `ArticleListViewProtocol` — it is not a full `ApiProtocol` mock.
//
//  The presenter hops through `Task { }` for its repository call, so every assertion below
//  waits on an `XCTestExpectation` fulfilled from the relevant view callback rather than
//  reading state immediately after calling into the presenter — reading synchronously would
//  race the `Task` and make the test flaky.

import XCTest

@MainActor
final class ArticleListPresenterTests: XCTestCase {

    func test_onViewDidLoad_populatesItemsAndReloadsTheList() {
        let view = ArticleListViewSpy()
        let sut = ArticleListPresenter(
            view: view,
            articles: ArticleRepositoryStub(result: .success([Article.fixture()]))
        )

        let reloaded = expectation(description: "list reloaded")
        view.onReloadList = { reloaded.fulfill() }

        sut.onViewDidLoad()

        wait(for: [reloaded], timeout: 1.0)
        XCTAssertEqual(sut.items.count, 1)
        XCTAssertEqual(view.loadingShownCount, 1)
        XCTAssertEqual(view.loadingHiddenCount, 1)
    }

    func test_onViewDidLoad_forwardsRepositoryFailureToTheView() {
        let view = ArticleListViewSpy()
        let sut = ArticleListPresenter(
            view: view,
            articles: ArticleRepositoryStub(result: .failure(TestError.any))
        )

        let handled = expectation(description: "error handled")
        view.onHandleApiError = { _ in handled.fulfill() }

        sut.onViewDidLoad()

        wait(for: [handled], timeout: 1.0)
        XCTAssertTrue(sut.items.isEmpty)
        XCTAssertEqual(view.loadingHiddenCount, 1)
    }

    func test_refresh_forwardsRefreshTrueToTheRepository() {
        let view = ArticleListViewSpy()
        let repository = ArticleRepositoryStub(result: .success([Article.fixture()]))
        let sut = ArticleListPresenter(view: view, articles: repository)

        let reloaded = expectation(description: "list reloaded")
        view.onReloadList = { reloaded.fulfill() }

        sut.refresh()

        wait(for: [reloaded], timeout: 1.0)
        XCTAssertEqual(repository.receivedRefreshFlags, [true])
    }
}

// MARK: - Test doubles

enum TestError: Error { case any }

final class ArticleRepositoryStub: ArticleRepository {
    let result: Result<[Article], Error>
    private(set) var receivedRefreshFlags: [Bool] = []

    init(result: Result<[Article], Error>) { self.result = result }

    func latest(refresh: Bool) async throws -> [Article] {
        receivedRefreshFlags.append(refresh)
        return try result.get()
    }
}

@MainActor
final class ArticleListViewSpy: ArticleListViewProtocol {
    private(set) var loadingShownCount = 0
    private(set) var loadingHiddenCount = 0
    var onReloadList: (() -> Void)?
    var onHandleApiError: ((Error) -> Void)?

    func showLoading() { loadingShownCount += 1 }
    func hideLoading() { loadingHiddenCount += 1 }
    func reloadList() { onReloadList?() }
    func handleApiError(error: Error) { onHandleApiError?(error) }
}
