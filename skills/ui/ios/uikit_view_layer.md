---
platform: ios
ui: uikit
---

# Skill: UIKit View Layer

## Overview

This codebase's screen convention splits view responsibilities in two: the
`UIViewController` owns lifecycle, presenter wiring, and navigation triggers, while a
separate `UIView` subclass owns every subview and every constraint. The controller never
builds constraints — it installs the view and forwards lifecycle events to the presenter.
This keeps controllers small by construction, since layout code has nowhere to accumulate
inside them, and it makes the view independently previewable and reusable: it can be
instantiated, laid out, and inspected (in a snapshot test or an Xcode preview) with no
presenter, no controller, and no navigation stack involved.

## Use Cases

- Any new programmatic UIKit screen built on the four-file MVP convention.
- Splitting layout out of an existing view controller as the first structural step before
  further decomposition.
- Screens that need a snapshot test of layout alone, independent of presenter state.
- Reusing a screen's visual layer (e.g. embedding it in a container view controller) without
  dragging its presenter or navigation logic along.

## Best Practices

- Name the view type `<Screen>View` (for example `ArticleListView`) and give it a single
  public root: the controller adds exactly one view as a subview of `self.view`, or installs
  it directly via `loadView()`.
- Build every constraint once, in `init(frame:)` or a `setUpConstraints()` called from
  `init(frame:)` — never in `layoutSubviews()`, and never in the controller.
- Set `translatesAutoresizingMaskIntoConstraints = false` on every subview before activating
  constraints against it.
- Expose configuration through plain methods or properties (`func configure(with:)`), not by
  handing the controller direct access to internal subviews it should not touch.
- Register table and collection view cells by type, never by string identifier.
- Prefer `UITableViewDiffableDataSource` / `UICollectionViewDiffableDataSource` (both
  available from iOS 13) over manual `reloadData()` so list updates are diffed and animated
  instead of re-rendering the whole list on every change.
- Give interactive controls an `accessibilityLabel` and Dynamic Type support via
  `UIFont.preferredFont(forTextStyle:)`, per the accessibility rules in
  [`../../../standards/uikit_standards.md`](../../../standards/uikit_standards.md).

## Anti-Patterns

- ❌ Building or re-activating constraints inside `layoutSubviews()` instead of once at
  `init(frame:)` time.
- ❌ Adding subviews inside `viewDidLayoutSubviews()` on the controller instead of in the
  view's own initializer.
- ❌ Dequeuing cells with a string literal identifier instead of registering and dequeuing by
  type.
- ❌ Calling `reloadData()` on every keystroke or state change instead of diffing with a
  diffable data source or targeted row/section updates.
- ❌ Storing per-row state on the cell itself (a cached image, a timer, a selection flag) that
  outlives reuse and leaks into the next row unless `prepareForReuse()` clears it.

## Checklist

- [ ] Layout and subview construction live entirely in the `<Screen>View` type, never in the
      view controller.
- [ ] Constraints are built once, in `init(frame:)`, not in `layoutSubviews()`.
- [ ] Every added subview sets `translatesAutoresizingMaskIntoConstraints = false`.
- [ ] Cells are registered and dequeued by type, not by string identifier.
- [ ] Lists use a diffable data source rather than unconditional `reloadData()`.
- [ ] Cells implement `prepareForReuse()` if they hold any mutable or in-flight state.
- [ ] The view type has no reference to the presenter and no navigation logic.

See also [`../../../standards/uikit_standards.md`](../../../standards/uikit_standards.md) and
[`../../../checklists/uikit_review.md`](../../../checklists/uikit_review.md).

## Swift Examples

A view that owns all of its own layout, built with UIKit's own layout anchors:

```swift
// ArticleListView.swift
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
```

The controller installs that view via `loadView()` instead of building it inside
`viewDidLoad()`, so the view exists before any lifecycle method that might reference it runs:

```swift
// ArticleListViewController.swift
final class ArticleListViewController: UIViewController {
    private let articleListView = ArticleListView(frame: .zero)
    var presenter: ArticleListPresenterProtocol!

    override func loadView() {
        view = articleListView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.onViewDidLoad()
    }
}
```

A diffable data source (iOS 13+) keeps the table in sync with presenter state without manual
`reloadData()` calls:

```swift
// ArticleListView+DataSource.swift
extension ArticleListView {
    enum Section { case main }

    func makeDataSource() -> UITableViewDiffableDataSource<Section, Article> {
        tableView.register(ArticleCell.self, forCellReuseIdentifier: ArticleCell.reuseID)
        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, article in
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ArticleCell.reuseID,
                for: indexPath
            ) as! ArticleCell
            cell.configure(with: article)
            return cell
        }
    }

    func apply(_ articles: [Article], to dataSource: UITableViewDiffableDataSource<Section, Article>) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Article>()
        snapshot.appendSections([.main])
        snapshot.appendItems(articles, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}
```

A host app that uses a layout DSL (such as SnapKit) applies the same structure — one
`UIView` subclass owning all subviews and constraints, built once in `init(frame:)` — with
only the constraint-building syntax differing from the anchor calls shown above.

## Common Interview Questions

- Why does the view own layout instead of the view controller?
- What is the difference between building constraints in `init(frame:)` versus
  `layoutSubviews()`, and why does it matter for performance and correctness?
- Why prefer a diffable data source over `reloadData()`?
- What goes wrong if a cell doesn't implement `prepareForReuse()`?
- How would you snapshot-test this view without a presenter or a running app?

## AI Implementation Notes

- When creating a new UIKit screen, always generate a `<Screen>View: UIView` subclass
  alongside the controller — never inline subview creation or constraints into the
  controller.
- Default to `init(frame:)` for constraint construction; only introduce a separate
  `setUpConstraints()` method when the view has enough subviews that inlining everything in
  `init` would hurt readability.
- Register cells by type and prefer a diffable data source for any list-backed view unless an
  existing screen's convention already uses a different, established pattern.
- Do not introduce a third-party layout library into generated examples; use
  `NSLayoutConstraint.activate` and anchor properties only.
- Related: [`massive_view_controller.md`](massive_view_controller.md),
  [`../../architecture/ios/mvp.md`](../../architecture/ios/mvp.md),
  [`../../../standards/uikit_standards.md`](../../../standards/uikit_standards.md),
  [`../../../checklists/uikit_review.md`](../../../checklists/uikit_review.md).
