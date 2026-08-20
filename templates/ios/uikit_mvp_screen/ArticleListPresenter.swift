//  ArticleListPresenter.swift
//  UIKit MVP screen template — the Presenter. No `import UIKit`: it belongs to the
//  Presentation layer and depends on Domain protocols only, per
//  ../../../skills/architecture/ios/mvp.md.
//
//  `ArticleRepository` is the Domain protocol from
//  ../../../skills/architecture/ios/repository_pattern.md — it is referenced here, never
//  redeclared.

@MainActor
final class ArticleListPresenter: ArticleListPresenterProtocol {
    private weak var view: ArticleListViewProtocol?
    private let articles: ArticleRepository
    private(set) var items: [Article] = []

    init(view: ArticleListViewProtocol, articles: ArticleRepository) {
        self.view = view
        self.articles = articles
    }

    func onViewDidLoad() { load(refresh: false) }
    func refresh() { load(refresh: true) }

    private func load(refresh: Bool) {
        view?.showLoading()
        Task { [weak self] in
            guard let self else { return }
            defer { self.view?.hideLoading() }
            do {
                self.items = try await self.articles.latest(refresh: refresh)
                self.view?.reloadList()
            } catch {
                self.view?.handleApiError(error: error)
            }
        }
    }
}
