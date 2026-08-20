//  ArticleListContract.swift
//  UIKit MVP screen template — the Contract file. Holds the view and presenter protocols
//  and nothing else, per ../../../standards/uikit_standards.md.
//
//  `ApiProtocol` and `PresenterProtocol` are assumed to already exist in the host app (they
//  are shared across every MVP screen, not just this one) and are referenced here, never
//  redeclared. `ArticleListCoordinatorDelegate` is implemented by a coordinator per
//  ../../../skills/architecture/ios/coordinator_navigation.md — this screen depends on the
//  delegate protocol only, never on a concrete coordinator type.

@MainActor protocol ArticleListViewProtocol: ApiProtocol {
    func reloadList()
}

@MainActor protocol ArticleListPresenterProtocol: PresenterProtocol {
    var items: [Article] { get }
    func onViewDidLoad()
    func refresh()
}

protocol ArticleListCoordinatorDelegate: AnyObject {
    func articleListDidSelect(_ article: Article)
}
