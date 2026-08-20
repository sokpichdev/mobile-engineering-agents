---
platform: ios
ui: uikit
---

# Skill: Decomposing Massive View Controllers

## Overview

A massive view controller — one that owns layout, data source and delegate conformances,
presentation state, networking, and navigation all in one file — is decomposed by an
ordered, behavior-preserving playbook, not by a rewrite. Each step in the playbook is
independently shippable: it changes structure without changing observable behavior, so it
can be reviewed, merged, and verified on its own. The ordering rule is fixed: **extract in
dependency order, lowest-risk first**, and land each extraction as its own commit, so that if
a regression appears later, `git bisect` lands on the one small commit that caused it instead
of on a single sprawling rewrite that touched everything at once.

## Use Cases

- A legacy `UIViewController` subclass that has accumulated layout code, `UITableView`
  data source/delegate methods, networking calls, and navigation logic in one file.
- Preparing a screen for its first unit test, where the current controller cannot be
  instantiated or driven without a live `UIApplication`.
- Bringing an existing screen into line with the four-file MVP convention in
  [`../../../standards/uikit_standards.md`](../../../standards/uikit_standards.md) without
  a behavior-changing rewrite.
- Reducing review risk on a screen nobody wants to touch because its size makes every change
  hard to reason about.

## Best Practices

The playbook, in this exact order:

1. Add a characterization test around the current behavior if any seam allows it; if none
   does, proceed to step 2 first, which creates one.
2. Extract the data source and delegate conformances into a separate type owned by the
   controller.
3. Move layout and subview construction into a `UIView` subclass, per
   [`uikit_view_layer.md`](uikit_view_layer.md).
4. Introduce the Contract protocols and an empty presenter; move state onto it, still calling
   the existing singletons.
5. Introduce the repository protocol and inject it, per
   [`../../concurrency/ios/promisekit_to_async.md`](../../concurrency/ios/promisekit_to_async.md).
6. Move navigation into a coordinator, per
   [`../../architecture/ios/coordinator_navigation.md`](../../architecture/ios/coordinator_navigation.md).
7. Delete now-dead controller code.

Supporting practices around the playbook:

- Treat each numbered step as its own pull request and its own commit — never batch two
  steps into one diff.
- Re-run the characterization test (or the existing test suite, if one already covered the
  screen) after every single step, not just at the end.
- Stop and ship what has landed so far if priorities shift mid-playbook; a controller that
  has completed steps 1 through 3 is strictly better off than before and does not need steps
  4 through 7 to justify having done 1 through 3.
- When a step's extraction reveals a second, unrelated problem (a bug, a naming
  inconsistency), note it and fix it in a separate follow-up commit — not inside the
  extraction step.

## Anti-Patterns

- ❌ Doing all seven steps in one pull request. A seven-step diff cannot be reviewed as
  behavior-preserving, and a regression it introduces cannot be isolated to one step.
- ❌ Rewriting to SwiftUI while decomposing. Changing the UI framework and decomposing the
  controller are two risky changes at once; either one alone is hard enough to verify as
  behavior-preserving.
- ❌ "Improving" behavior mid-extraction — fixing a bug, changing copy, adjusting a threshold
  — so the diff can no longer be reviewed as behavior-preserving and a regression can no
  longer be told apart from an intentional change.
- ❌ Skipping the characterization test in step 1 because "the screen is simple." A screen
  judged simple enough to skip verification is exactly the screen where a silent regression
  goes unnoticed the longest.
- ❌ Reordering the playbook — for example moving navigation into a coordinator (step 6)
  before extracting the presenter (step 4) — which extracts a higher-risk seam before the
  lower-risk seams it depends on have been proven safe.

## Checklist

- [ ] A characterization test (or an existing test suite) covers the screen's current
      behavior before any extraction begins.
- [ ] Each of the seven steps landed as its own commit, in the stated order.
- [ ] The test suite passed after every individual step, not only at the end.
- [ ] No step changed observable behavior — only structure.
- [ ] No step introduced a second framework change (for example a SwiftUI rewrite)
      alongside the extraction.
- [ ] The final controller has no data source/delegate conformances, no layout code, no
      direct networking, and no navigation logic left in it.
- [ ] Dead code the extractions made unreachable was deleted in step 7, not left in place.

See also [`../../../checklists/uikit_review.md`](../../../checklists/uikit_review.md) and
[`../../../standards/uikit_standards.md`](../../../standards/uikit_standards.md).

## Swift Examples

Before: a controller owning layout, data source, and networking together.

```swift
// ANTI-PATTERN — everything in one file
final class ArticleListViewController: UIViewController, UITableViewDataSource {
    let tableView = UITableView()
    var articles: [Article] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)                 // layout in the controller
        tableView.frame = view.bounds
        tableView.dataSource = self
        ArticleCloud.shared.getArticles(forceRefresh: false)   // networking in the controller
            .done { self.articles = $0; self.tableView.reloadData() }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        articles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!  // string literal
        cell.textLabel?.text = articles[indexPath.row].title
        return cell
    }
}
```

After step 2: the data source conformance moves out of the controller into its own type,
with no other behavior changed.

```swift
// ArticleListDataSource.swift
final class ArticleListDataSource: NSObject, UITableViewDataSource {
    private(set) var articles: [Article] = []

    func update(_ articles: [Article]) { self.articles = articles }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        articles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ArticleCell.reuseID,
            for: indexPath
        ) as! ArticleCell
        cell.configure(with: articles[indexPath.row])
        return cell
    }
}
```

After all seven steps, the controller is left holding only lifecycle, presenter wiring, and
the view it installs — matching the split described in
[`uikit_view_layer.md`](uikit_view_layer.md) and the presenter shape in
[`../../architecture/ios/mvp.md`](../../architecture/ios/mvp.md):

```swift
// ArticleListViewController.swift
final class ArticleListViewController: UIViewController {
    private let articleListView = ArticleListView(frame: .zero)
    var presenter: ArticleListPresenterProtocol!

    override func loadView() { view = articleListView }

    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.onViewDidLoad()
    }
}
```

## Common Interview Questions

- Why extract the data source before the presenter, rather than the other way around?
- What makes a characterization test different from a regular unit test, and why write one
  first when no test exists yet?
- Why must SwiftUI adoption and massive-view-controller decomposition happen as two separate
  efforts rather than one?
- How does landing each step as its own commit help when a regression surfaces two weeks
  later?
- What is left in the controller once all seven steps are complete?

## AI Implementation Notes

- When asked to "clean up" or "break apart" a large view controller, propose this seven-step
  order explicitly rather than jumping straight to a full rewrite.
- Generate exactly one step's diff per turn/commit; do not combine steps 2 and 3, or 4 and 5,
  into a single change even when it looks like a small combined diff.
- If the screen already has no test coverage, treat step 1 as blocking — produce the
  characterization test before touching any production code in the controller.
- Never introduce a SwiftUI rewrite as part of answering a "decompose this controller"
  request; if the user wants both, sequence them as two separate efforts and say so.
- Related: [`uikit_view_layer.md`](uikit_view_layer.md),
  [`../../architecture/ios/mvp.md`](../../architecture/ios/mvp.md),
  [`../../concurrency/ios/promisekit_to_async.md`](../../concurrency/ios/promisekit_to_async.md),
  [`../../architecture/ios/coordinator_navigation.md`](../../architecture/ios/coordinator_navigation.md),
  [`../../../standards/uikit_standards.md`](../../../standards/uikit_standards.md).
