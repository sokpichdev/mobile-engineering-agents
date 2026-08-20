//  ArticleListViewController.swift
//  UIKit MVP screen template — the View Controller. Owns lifecycle, presenter wiring, and
//  navigation triggers only; it never builds constraints (that lives in `ArticleListView`,
//  per ../../../skills/ui/ios/uikit_view_layer.md) and never contains business logic (that
//  lives in `ArticleListPresenter`, per ../../../skills/architecture/ios/mvp.md).
//
//  Uses a plain `UITableViewDataSource` conformance rather than a diffable data source: the
//  contract's `reloadList()` method (../../../skills/architecture/ios/mvp.md) is an
//  imperative "reload everything" command, not a diffable snapshot, so this screen has
//  nothing to key a diff on. `Article` is already `Identifiable`, so a screen whose contract
//  instead exposes state suited to diffing can adopt
//  `UITableViewDiffableDataSource<Section, Article.ID>` — see the diffable example in
//  ../../../skills/ui/ios/uikit_view_layer.md.

import UIKit

final class ArticleListViewController: UIViewController, ArticleListViewProtocol {
    private static let cellReuseID = String(describing: UITableViewCell.self)

    private let listView = ArticleListView()

    // `presenter` is an implicitly unwrapped optional solely because the presenter's own
    // initializer requires a reference to this view controller (as `ArticleListViewProtocol`)
    // — the view controller must exist before the presenter can hold that reference, so it
    // cannot be passed into this view controller's own initializer instead. `make` below sets
    // it immediately after construction and is the only supported way to build this screen.
    private var presenter: ArticleListPresenterProtocol!
    private weak var delegate: ArticleListCoordinatorDelegate?

    static func make(articles: ArticleRepository,
                     delegate: ArticleListCoordinatorDelegate?) -> ArticleListViewController {
        let viewController = ArticleListViewController()
        viewController.delegate = delegate
        viewController.presenter = ArticleListPresenter(view: viewController, articles: articles)
        return viewController
    }

    // `private` so `make` is the only way to construct this screen — a bare
    // `ArticleListViewController()` from outside this file would leave `presenter` nil and
    // crash on first use. Still callable from `make` because `private` is file-scoped.
    private override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func loadView() { view = listView }

    override func viewDidLoad() {
        super.viewDidLoad()
        listView.tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellReuseID)
        listView.tableView.dataSource = self
        listView.tableView.delegate = self
        presenter.onViewDidLoad()
    }

    // MARK: - ArticleListViewProtocol (ApiProtocol members + reloadList)

    func showLoading() {
        // A host app typically routes this to a shared loading overlay/spinner component;
        // that mechanism is app-specific and out of scope for this template.
    }

    func hideLoading() {
        // See `showLoading()`.
    }

    func handleApiError(error: Error) {
        let alert = UIAlertController(
            title: "Something went wrong",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func reloadList() { listView.tableView.reloadData() }
}

// MARK: - UITableViewDataSource

extension ArticleListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        presenter.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellReuseID, for: indexPath)
        let article = presenter.items[indexPath.row]
        cell.textLabel?.text = article.title
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ArticleListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate?.articleListDidSelect(presenter.items[indexPath.row])
    }
}
