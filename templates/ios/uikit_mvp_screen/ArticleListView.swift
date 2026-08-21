//  ArticleListView.swift
//  UIKit MVP screen template — the View. A `UIView` subclass owning every subview and every
//  constraint; the view controller never builds constraints, per
//  ../../../skills/ui/ios/uikit_view_layer.md.
//
//  Built with UIKit's own layout anchors only — no third-party layout library, since this
//  template ships in a public toolkit and must not assume a dependency. A host app that uses
//  a layout DSL (such as SnapKit) can apply the same structure with only the
//  constraint-building syntax differing.

import UIKit

final class ArticleListView: UIView {
    let tableView = UITableView(frame: .zero, style: .plain)

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
}
