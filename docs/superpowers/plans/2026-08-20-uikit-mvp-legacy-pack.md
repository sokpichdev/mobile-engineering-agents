# UIKit + MVP Legacy Pack Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend this toolkit so it gives correct guidance on legacy programmatic-UIKit + MVP iOS codebases, without changing how it behaves for existing SwiftUI projects.

**Architecture:** Add an optional `ui:` front-matter key as a second scoping axis inside iOS (`platform: ios` + `ui: uikit|swiftui`), where omitting the key means "applies to both". New UIKit content is added alongside existing SwiftUI content; no existing content file is rewritten. The five entry-point files stop asserting MVVM universally and instead select the presentation pattern from the detected UI framework.

**Tech Stack:** Markdown documentation toolkit. Validation is `./verify.sh`, `markdownlint-cli2`, and `markdown-link-check`. Swift 5.5+ / iOS 13 code samples inside the docs are illustrative and are not compiled by CI.

**Spec:** `docs/superpowers/specs/2026-08-20-uikit-mvp-legacy-pack-design.md`

---

## How this plan is tested

**Read this before Task 1.** This repository's deliverable is documentation, not a compiled program. There is no unit-test suite to drive, so the classic red-green-refactor loop does not apply and this plan does not pretend otherwise. Substituted in its place, every task runs the same three real gates that CI runs:

```bash
npx --yes markdownlint-cli2 "<file>"                                      # Docs CI, job "lint"
npx --yes markdown-link-check --quiet --config .github/mlc_config.json <file>   # Docs CI, job "links"
./verify.sh                                                              # local structure check
```

Two genuine red-green cycles do exist, and both are used:

1. **Task 12** raises the `verify.sh` file-count floors *before* confirming they pass, so the script fails first and passes after.
2. **Task 11** carries a behavioral acceptance check: before the control plane is wired, asking an agent how to structure a UIKit MVP screen yields SwiftUI/MVVM guidance (wrong); after, it yields MVP guidance (right). Record both answers.

**Known pre-existing lint failure:** `.superpowers/sdd/progress.md` reports `MD022`. It is untracked scratch state, not part of this work. Do not fix it, and do not treat it as a regression.

---

## Global Constraints

Every task's requirements implicitly include this section.

**Repository hygiene**

- This repository is **public**; the reference codebase is a bank's proprietary app. Ship patterns only: no institution name, no absolute filesystem paths, no proprietary flows, no copied source.
- Conventional Commits are gated by commitlint on both commits and PR title. Use `feat(uikit): …` for new capability and `docs(uikit): …` for pure documentation edits.
- Do not edit any existing content file except the fourteen named in Tasks 7 and 10-12.
- Do not commit `node_modules/`, and do not stage the pre-existing unrelated changes in `.claude/agents/*.md`, `AGENTS.md`, `CLAUDE.md`, or `README.md` that were already in the working tree before this plan started. Stage only the exact paths each task lists.

**Front-matter**

- Every new file under `skills/` starts with front-matter: `platform: ios`, plus `ui: uikit` **only** if the content is specific to the UIKit view layer.
- Omitting `ui:` means the file applies to both paradigms. When unsure, omit it.
- Files outside `skills/` (standards, checklists, workflows, agents, templates) carry no front-matter, matching existing convention.

**iOS version floor**

- Deployment target is **iOS 13.0**. Therefore: **XCTest, not Swift Testing**; no `@Observable`; no `NavigationStack`; no `async let` in examples that must run on 13.0. `async`/`await` and `UICollectionViewDiffableDataSource` are both available on iOS 13 and may be used.

**Canonical example vocabulary — use these exact names in every task**

Type consistency across files is a correctness requirement, not a style preference. All Swift samples in all tasks use this one domain:

| Role | Exact name |
|------|-----------|
| Domain entity | `Article` |
| Repository protocol (Domain) | `ArticleRepository`, sole method `func fetch() async throws -> [Article]` |
| Repository implementation (Data) | `ArticleCloudRepository` |
| Legacy PromiseKit singleton | `ArticleCloud.shared.getArticles()` returning `Promise<[Article]>` |
| Screen prefix | `ArticleList` |
| Four screen files | `ArticleListContract.swift`, `ArticleListView.swift`, `ArticleListViewController.swift`, `ArticleListPresenter.swift` |
| View protocol | `ArticleListViewProtocol` |
| Presenter protocol | `ArticleListPresenterProtocol` |
| Test doubles | `ArticleListViewSpy`, `ArticleRepositoryStub` |

Pre-existing host-app base protocols referenced but never redefined: `PresenterProtocol` (marked `@MainActor`, empty) and `ApiProtocol` (supplies `showLoading()`, `hideLoading()`, `handleApiError(error:)`).

**Section conventions — match the existing files exactly**

- Skill files: `# Skill: <Name>` then `## Overview`, `## Use Cases`, `## Best Practices`, `## Anti-Patterns`, `## Checklist`, `## Swift Examples`, `## Common Interview Questions`, `## AI Implementation Notes`.
- Workflow files: `# Workflow: <Name>` then `## Objective`, `## Inputs`, `## Outputs`, `## Step-by-Step Process`, `## Validation Steps`, `## Failure Scenarios`, `## AI Agent Instructions`, `## Acceptance Criteria`.
- Agent files: `# Agent: <Name>` then `## Purpose`, `## Responsibilities`, `## Rules`, `## Coding Standards`, `## Review Checklist`, `## Common Mistakes`, `## Example Tasks`, `## Related`.
- Checklist files: `# Checklist: <Name>` then grouped `##` sections ending with `## Verdict`.

---

## File Structure

**Created (16 files)**

| Path | Responsibility |
|------|----------------|
| `standards/uikit_standards.md` | Rules of the road for programmatic UIKit and the four-file screen convention |
| `checklists/uikit_review.md` | Review gate for UIKit/MVP work |
| `skills/architecture/ios/mvp.md` | The MVP pattern: Contract, View, Presenter, DI, testing |
| `skills/concurrency/ios/promisekit_to_async.md` | Bridging promises and completion handlers to async/await at the data boundary |
| `skills/ui/ios/uikit_view_layer.md` | Programmatic Auto Layout, VC/View split, cell reuse, diffable data sources |
| `skills/ui/ios/massive_view_controller.md` | Decomposition playbook for oversized view controllers |
| `skills/architecture/ios/coordinator_navigation.md` | Lifting navigation out of view controllers |
| `templates/ios/uikit_mvp_screen/README.md` | How to use the template |
| `templates/ios/uikit_mvp_screen/ArticleListContract.swift` | View + presenter protocols |
| `templates/ios/uikit_mvp_screen/ArticleListView.swift` | Programmatic `UIView` subclass |
| `templates/ios/uikit_mvp_screen/ArticleListViewController.swift` | Lifecycle host + factory |
| `templates/ios/uikit_mvp_screen/ArticleListPresenter.swift` | Presenter with injected repository |
| `templates/ios/uikit_mvp_screen/ArticleListPresenterTests.swift` | Spy view + stub repository, XCTest |
| `workflows/migrate_uikit_to_swiftui.md` | Strangler-fig migration procedure |
| `agents/uikit_expert.md` | Tier 2 role definition |
| `.claude/agents/uikit-expert.md` | Claude Code native subagent stub |

**Modified (14 files)**

`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.cursorrules`, `.windsurfrules`, `README.md`, `verify.sh`, `skills/testing/ios/unit_testing.md`, `agents/README.md`, `skills/README.md`, `standards/README.md`, `checklists/README.md`, `workflows/README.md`, `templates/README.md`.

**Ordering rationale:** content files are created before the control plane that links to them, because `markdown-link-check` runs across every Markdown file in the repo and a link to a not-yet-created file fails CI.

---

### Task 1: UIKit standard and review checklist

**Files:**
- Create: `standards/uikit_standards.md`
- Create: `checklists/uikit_review.md`

**Interfaces:**
- Consumes: nothing. This is the root of the dependency chain.
- Produces: `standards/uikit_standards.md` and `checklists/uikit_review.md`, linked by Tasks 2, 4, 5, 9.

- [ ] **Step 1: Create `standards/uikit_standards.md`**

No front-matter (matches `standards/swiftui_standards.md`). Title `# Standard: UIKit Standards`. Sections, in this order, mirroring the shape of `swiftui_standards.md`:

`## Screen Structure` — the four-file convention is mandatory: `<Name>Contract.swift`, `<Name>View.swift`, `<Name>ViewController.swift`, `<Name>Presenter.swift`. Contract holds both protocols and nothing else. View is a `UIView` subclass owning all layout and subviews. ViewController owns lifecycle and forwards to the presenter. Presenter holds no `UIKit` import.

`## Layout` — programmatic only; Interface Builder is permitted for the launch screen and nothing else. Build constraints once in the view's initializer, never in `layoutSubviews`. Set `translatesAutoresizingMaskIntoConstraints = false` on every added subview. Prefer layout guides over magic numbers.

`## View Controller Lifecycle` — one-time setup in `viewDidLoad`; anything that must repeat on re-entry goes in `viewWillAppear`. Never start network work from `init`. Never put business rules in a lifecycle method — forward to the presenter.

`## Cells and Reuse` — register cell classes by type, never by string literal; implement `prepareForReuse` for any cell holding mutable state or an in-flight image load; prefer `UITableViewDiffableDataSource` / `UICollectionViewDiffableDataSource` (available from iOS 13) over manual `reloadData`.

`## Presenters` — mark `@MainActor`; hold the view `weak`; expose state as `private(set)`; accept every dependency through the initializer as a protocol.

`## Accessibility` — set `accessibilityLabel` on every interactive control; set `accessibilityIdentifier` on anything a UI test drives; support Dynamic Type with `UIFont.preferredFont(forTextStyle:)` and `adjustsFontForContentSizeCategory = true`.

Close with a `## Related` section linking `../skills/architecture/ios/mvp.md`, `../skills/ui/ios/uikit_view_layer.md`, and `../checklists/uikit_review.md`.

- [ ] **Step 2: Create `checklists/uikit_review.md`**

Title `# Checklist: UIKit Review`. Sections `## Screen Structure`, `## Presenter (Critical/High)`, `## View Layer`, `## Lifecycle`, `## Accessibility`, `## Tests`, then `## Verdict` — matching `checklists/code_review.md`. Every line is a `- [ ]` item. The `## Presenter (Critical/High)` section must contain these four items verbatim, because they are the findings this whole pack exists to catch:

```markdown
- [ ] Presenter takes every dependency through its initializer as a protocol — no `.shared` singleton access.
- [ ] Presenter's `init` performs no work: no network calls, no timers, no notification registration.
- [ ] Presenter holds the view `weak` and is marked `@MainActor`.
- [ ] Presenter has at least one unit test using a spy view and a stub repository.
```

- [ ] **Step 3: Lint and link-check both files**

```bash
npx --yes markdownlint-cli2 "standards/uikit_standards.md" "checklists/uikit_review.md"
npx --yes markdown-link-check --quiet --config .github/mlc_config.json standards/uikit_standards.md checklists/uikit_review.md
```

Expected: markdownlint reports only the known `.superpowers/sdd/progress.md` MD022 error. Link-check reports **failures** for `../skills/architecture/ios/mvp.md` and `../skills/ui/ios/uikit_view_layer.md`, which do not exist yet — this is expected and is resolved by Tasks 2 and 4. Do not remove those links.

- [ ] **Step 4: Commit**

```bash
git add standards/uikit_standards.md checklists/uikit_review.md
git commit -m "feat(uikit): add UIKit standard and review checklist"
```

---

### Task 2: MVP skill

**Files:**
- Create: `skills/architecture/ios/mvp.md`

**Interfaces:**
- Consumes: `standards/uikit_standards.md` (Task 1), `checklists/uikit_review.md` (Task 1).
- Produces: `skills/architecture/ios/mvp.md`, linked by Tasks 6, 9, 11.

- [ ] **Step 1: Create the file with front-matter and the eight standard sections**

```yaml
---
platform: ios
ui: uikit
---
```

Title `# Skill: MVP (Model-View-Presenter)`.

`## Overview` — MVP splits a screen into a passive View (the `UIViewController` plus its `UIView`), a Presenter holding all presentation logic and state, and a Contract file declaring the two protocols that join them. Unlike MVVM there is no binding mechanism: the presenter calls explicit methods on the view. This makes it a natural fit for UIKit, where there is no built-in observation of state. State the layering explicitly: the Presenter belongs to the Presentation layer and depends on Domain protocols only — it must never import UIKit.

`## Use Cases` — legacy or greenfield UIKit screens; teams standardizing an existing UIKit codebase; incrementally making untestable view controllers testable.

`## Best Practices` — Contract file declares both protocols and nothing else; presenter is `@MainActor` and `final`; view reference is `weak`; every dependency injected via initializer as a protocol; no work in `init`, with an explicit `onViewDidLoad()` entry point instead; state exposed `private(set)`; view protocol methods are imperative commands (`reloadList()`), not state setters.

`## Anti-Patterns` — calling `.shared` from a presenter; firing network calls from `init`; importing UIKit into a presenter; a "view protocol" that just exposes the whole view controller; presenters that reach into `UserDefaults` or `Date()` directly instead of receiving them.

`## Checklist` — mirror the four Critical/High items from `checklists/uikit_review.md`, plus contract/state/lifecycle items.

- [ ] **Step 2: Write the `## Swift Examples` section**

Three code blocks in this order. The contract:

```swift
// ArticleListContract.swift
@MainActor protocol ArticleListViewProtocol: ApiProtocol {
    func reloadList()
}

@MainActor protocol ArticleListPresenterProtocol: PresenterProtocol {
    var items: [Article] { get }
    func onViewDidLoad()
    func refresh()
}
```

The anti-pattern, labelled clearly as what **not** to write:

```swift
// ANTI-PATTERN — unconstructible in a test
class ArticleListPresenter: ArticleListPresenterProtocol {
    weak private var view: ArticleListViewProtocol?
    private(set) var items: [Article] = []

    init(with view: ArticleListViewProtocol) {
        self.view = view
        loadArticles()                  // side effect in init
    }

    func loadArticles() {
        ArticleCloud.shared.getArticles()   // concrete singleton
            .done { self.items = $0 }
    }
}
```

The corrected presenter:

```swift
// ArticleListPresenter.swift
@MainActor
final class ArticleListPresenter: ArticleListPresenterProtocol {
    private weak var view: ArticleListViewProtocol?
    private let articles: ArticleRepository
    private(set) var items: [Article] = []

    init(view: ArticleListViewProtocol, articles: ArticleRepository) {
        self.view = view
        self.articles = articles
    }

    func onViewDidLoad() { load() }
    func refresh() { load() }

    private func load() {
        view?.showLoading()
        Task { [weak self] in
            guard let self else { return }
            defer { self.view?.hideLoading() }
            do {
                self.items = try await self.articles.fetch()
                self.view?.reloadList()
            } catch {
                self.view?.handleApiError(error: error)
            }
        }
    }
}
```

- [ ] **Step 3: Write `## Common Interview Questions` and `## AI Implementation Notes`**

Questions: how does MVP differ from MVVM and MVC; why is the view reference weak; where does navigation belong (a coordinator or the view controller, never the presenter); how do you test a presenter without a running UI; why must the presenter not import UIKit.

`## AI Implementation Notes` must state the rule that governs agent behavior on legacy code: **do not convert existing MVP screens to MVVM.** When editing a UIKit screen, follow the surrounding MVP convention. Introduce the injected-repository seam only for screens you are already modifying.

- [ ] **Step 4: Lint and link-check**

```bash
npx --yes markdownlint-cli2 "skills/architecture/ios/mvp.md"
npx --yes markdown-link-check --quiet --config .github/mlc_config.json skills/architecture/ios/mvp.md
```

Expected: clean apart from the known pre-existing error.

- [ ] **Step 5: Commit**

```bash
git add skills/architecture/ios/mvp.md
git commit -m "feat(uikit): add MVP architecture skill"
```

---

### Task 3: PromiseKit-to-async bridging skill

**Files:**
- Create: `skills/concurrency/ios/promisekit_to_async.md`

**Interfaces:**
- Consumes: the `ArticleRepository` protocol shape defined in Task 2.
- Produces: `skills/concurrency/ios/promisekit_to_async.md`, linked by Tasks 2 (optional back-link not required), 9, 11, 12.

This creates the new `skills/concurrency/` topic directory.

- [ ] **Step 1: Create the file with front-matter**

```yaml
---
platform: ios
---
```

**No `ui:` key.** This is a data-boundary concern and applies to both paradigms. Getting this wrong is the single most likely mistake in this task.

Title `# Skill: Bridging PromiseKit and Completion Handlers to async/await`.

- [ ] **Step 2: Write `## Overview` and `## Use Cases`**

The central argument, which must be stated plainly: a legacy codebase does **not** need to remove PromiseKit to gain testable presentation logic. Introducing one thin `async` adapter per data source makes every consumer behind it injectable and awaitable, while the existing promise-based singleton keeps serving every call site not yet migrated. This yields a per-screen migration with no big-bang step — the only kind that finishes in a codebase of a thousand-plus files.

Use cases: making a presenter or view model testable; adopting `async`/`await` in new code without a framework removal project; unifying error handling across two async styles.

- [ ] **Step 3: Write `## Swift Examples`**

The domain protocol:

```swift
// Domain
protocol ArticleRepository {
    func fetch() async throws -> [Article]
}
```

The promise adapter:

```swift
// Data
struct ArticleCloudRepository: ArticleRepository {
    func fetch() async throws -> [Article] {
        try await withCheckedThrowingContinuation { continuation in
            ArticleCloud.shared.getArticles()
                .done { continuation.resume(returning: $0) }
                .catch { continuation.resume(throwing: $0) }
        }
    }
}
```

The completion-handler variant, for data sources that never used PromiseKit:

```swift
// Data — completion-handler source
struct LegacyArticleRepository: ArticleRepository {
    func fetch() async throws -> [Article] {
        try await withCheckedThrowingContinuation { continuation in
            ArticleCloud.shared.getArticles { result in
                continuation.resume(with: result)   // Result<[Article], Error>
            }
        }
    }
}
```

- [ ] **Step 4: Write `## Anti-Patterns` — the correctness section**

This section carries the highest risk content in the pack and must call out each item explicitly:

- **Resuming a continuation twice, or never.** `withCheckedThrowingContinuation` traps on double-resume and leaks the task forever on zero-resume. Every path through the callback must resume exactly once. A promise with both `.done` and `.catch` covers this; a promise with only `.done` does not.
- **Using `withUnsafeThrowingContinuation` to silence the check.** Use the checked variant; it exists to catch precisely this bug.
- **Bridging at the call site instead of the boundary.** Wrap once inside the repository, not repeatedly in every presenter.
- **Wrapping a promise that can resolve more than once.** Continuations model a single value; a repeating source needs `AsyncStream`.
- **Hopping actors implicitly.** The adapter is not `@MainActor`; the presenter is. Do not assume callback threads.

- [ ] **Step 5: Write `## Best Practices`, `## Checklist`, `## Common Interview Questions`, `## AI Implementation Notes`**

`## AI Implementation Notes`: introduce an adapter only for the data source a task already touches. Never open a migration that rewrites unrelated call sites.

- [ ] **Step 6: Lint, link-check, commit**

```bash
npx --yes markdownlint-cli2 "skills/concurrency/ios/promisekit_to_async.md"
npx --yes markdown-link-check --quiet --config .github/mlc_config.json skills/concurrency/ios/promisekit_to_async.md
git add skills/concurrency/ios/promisekit_to_async.md
git commit -m "feat(uikit): add PromiseKit to async/await bridging skill"
```

---

### Task 4: UIKit view-layer skills

**Files:**
- Create: `skills/ui/ios/uikit_view_layer.md`
- Create: `skills/ui/ios/massive_view_controller.md`

**Interfaces:**
- Consumes: `standards/uikit_standards.md` (Task 1).
- Produces: both files, linked by Tasks 9 and 11. `massive_view_controller.md` is additionally linked from the Refactoring Expert routing row in Task 11.

This creates the new `skills/ui/` topic directory. Both files carry `platform: ios` and `ui: uikit`.

- [ ] **Step 1: Create `skills/ui/ios/uikit_view_layer.md`**

Title `# Skill: UIKit View Layer`. Standard eight sections.

`## Overview` — the split this codebase convention relies on: the `UIViewController` owns lifecycle, presenter wiring, and navigation triggers; a separate `UIView` subclass owns every subview and every constraint. The controller never builds constraints. This keeps controllers small by construction and makes the view independently previewable and reusable.

`## Swift Examples` must contain a programmatic view using only UIKit's own layout anchors — **no third-party layout library**, since the toolkit is public and must not assume a dependency:

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

Add a second example showing `loadView()` used to install the view, and a third showing a diffable data source (iOS 13+). Add a note that if a host app uses a layout DSL such as SnapKit, the same structure applies — only the constraint syntax changes.

`## Anti-Patterns` — building constraints in `layoutSubviews`; subviews added in `viewDidLayoutSubviews`; dequeuing cells with string literals; `reloadData` on every keystroke; storing state on the cell.

- [ ] **Step 2: Create `skills/ui/ios/massive_view_controller.md`**

Title `# Skill: Decomposing Massive View Controllers`. Standard eight sections.

`## Overview` — an ordered, behavior-preserving playbook, each step independently shippable. State the ordering rule up front: **extract in dependency order, lowest-risk first**, and land each extraction as its own commit so a regression bisects cleanly.

`## Best Practices` — the playbook itself, in this exact order:

1. Add a characterization test around the current behavior if any seam allows it; if none does, proceed to step 2 first, which creates one.
2. Extract the data source and delegate conformances into a separate type owned by the controller.
3. Move layout and subview construction into a `UIView` subclass per `uikit_view_layer.md`.
4. Introduce the Contract protocols and an empty presenter; move state onto it, still calling the existing singletons.
5. Introduce the repository protocol and inject it, per `../../concurrency/ios/promisekit_to_async.md`.
6. Move navigation into a coordinator, per `../../architecture/ios/coordinator_navigation.md`.
7. Delete now-dead controller code.

`## Anti-Patterns` — doing all seven steps in one pull request; rewriting to SwiftUI while decomposing (two risky changes at once); "improving" behavior mid-extraction so the diff can no longer be reviewed as behavior-preserving.

- [ ] **Step 3: Lint and link-check both**

```bash
npx --yes markdownlint-cli2 "skills/ui/ios/uikit_view_layer.md" "skills/ui/ios/massive_view_controller.md"
npx --yes markdown-link-check --quiet --config .github/mlc_config.json skills/ui/ios/uikit_view_layer.md skills/ui/ios/massive_view_controller.md
```

Expected: `../../architecture/ios/coordinator_navigation.md` fails until Task 5. Leave the link.

- [ ] **Step 4: Commit**

```bash
git add skills/ui/ios/uikit_view_layer.md skills/ui/ios/massive_view_controller.md
git commit -m "feat(uikit): add UIKit view layer and massive view controller skills"
```

---

### Task 5: Coordinator navigation skill

**Files:**
- Create: `skills/architecture/ios/coordinator_navigation.md`

**Interfaces:**
- Consumes: `skills/architecture/ios/mvp.md` (Task 2).
- Produces: `skills/architecture/ios/coordinator_navigation.md`. Resolves the dangling link left by Task 4.

Front-matter: `platform: ios`, `ui: uikit`.

- [ ] **Step 1: Write the file**

Title `# Skill: Coordinator Navigation`. Standard eight sections.

`## Overview` — in UIKit, navigation is imperative and view controllers push each other directly, which couples every screen to its neighbors and makes flows untestable. A coordinator owns a `UINavigationController` and decides what comes next; screens report events upward and know nothing about their successors.

`## Swift Examples`:

```swift
protocol ArticleListCoordinatorDelegate: AnyObject {
    func articleListDidSelect(_ article: Article)
}

final class ArticleListCoordinator: ArticleListCoordinatorDelegate {
    private let navigationController: UINavigationController
    private let articles: ArticleRepository

    init(navigationController: UINavigationController, articles: ArticleRepository) {
        self.navigationController = navigationController
        self.articles = articles
    }

    func start() {
        let viewController = ArticleListViewController.make(articles: articles, delegate: self)
        navigationController.pushViewController(viewController, animated: false)
    }

    func articleListDidSelect(_ article: Article) {
        // push the detail screen
    }
}
```

`ArticleListCoordinatorDelegate` is declared in `ArticleListContract.swift` (Task 6 Step 1), and `ArticleListViewController.make(articles:delegate:)` is the factory from Task 6 Step 4. Both signatures must match Task 6 exactly.

`## Anti-Patterns` — a presenter that imports UIKit to push a controller; a singleton "Router" that every screen reaches into; retrofitting coordinators across an entire legacy app at once.

`## AI Implementation Notes` — **apply to new flows and to flows already being substantially modified. Do not retrofit coordinators across existing screens as a standalone change.**

- [ ] **Step 2: Lint and link-check**

```bash
npx --yes markdownlint-cli2 "skills/architecture/ios/coordinator_navigation.md"
npx --yes markdown-link-check --quiet --config .github/mlc_config.json skills/architecture/ios/coordinator_navigation.md skills/ui/ios/massive_view_controller.md
```

Expected: both files now clean.

- [ ] **Step 3: Commit**

```bash
git add skills/architecture/ios/coordinator_navigation.md
git commit -m "feat(uikit): add coordinator navigation skill"
```

---

### Task 6: UIKit MVP screen template

**Files:**
- Create: `templates/ios/uikit_mvp_screen/README.md`
- Create: `templates/ios/uikit_mvp_screen/ArticleListContract.swift`
- Create: `templates/ios/uikit_mvp_screen/ArticleListView.swift`
- Create: `templates/ios/uikit_mvp_screen/ArticleListViewController.swift`
- Create: `templates/ios/uikit_mvp_screen/ArticleListPresenter.swift`
- Create: `templates/ios/uikit_mvp_screen/ArticleListPresenterTests.swift`

**Interfaces:**
- Consumes: the contract and presenter from Task 2, the view style from Task 4, the repository protocol from Task 3.
- Produces: `ArticleListCoordinatorDelegate` and `ArticleListViewController.make(articles:delegate:)`, both consumed by Task 5's example. **These signatures must match Task 5 exactly.**

This is the highest-value deliverable in the plan: it is what engineers copy. It ships the corrected pattern, not a transcription of existing practice.

- [ ] **Step 1: Create `ArticleListContract.swift`**

Reproduce the contract from Task 2 Step 2 verbatim, then add the coordinator delegate below it so the template folder is self-contained:

```swift
protocol ArticleListCoordinatorDelegate: AnyObject {
    func articleListDidSelect(_ article: Article)
}
```

Add a file header comment explaining that `ApiProtocol` and `PresenterProtocol` are expected to already exist in the host app, and that `ArticleListCoordinatorDelegate` is implemented by a coordinator per `../../../skills/architecture/ios/coordinator_navigation.md`.

- [ ] **Step 2: Create `ArticleListPresenter.swift`**

Reproduce the corrected presenter from Task 2 Step 2 verbatim.

- [ ] **Step 3: Create `ArticleListView.swift`**

Reproduce the view from Task 4 Step 1 verbatim.

- [ ] **Step 4: Create `ArticleListViewController.swift`**

```swift
final class ArticleListViewController: UIViewController, ArticleListViewProtocol {
    private let listView = ArticleListView()
    private var presenter: ArticleListPresenterProtocol!
    private weak var delegate: ArticleListCoordinatorDelegate?

    static func make(articles: ArticleRepository,
                     delegate: ArticleListCoordinatorDelegate?) -> ArticleListViewController {
        let viewController = ArticleListViewController()
        viewController.delegate = delegate
        viewController.presenter = ArticleListPresenter(view: viewController, articles: articles)
        return viewController
    }

    override func loadView() { view = listView }

    override func viewDidLoad() {
        super.viewDidLoad()
        listView.tableView.dataSource = self
        presenter.onViewDidLoad()
    }

    func reloadList() { listView.tableView.reloadData() }
}
```

Add a brief `UITableViewDataSource` conformance in an extension so the file compiles conceptually. Note in a comment that `presenter` is an implicitly unwrapped optional solely because the view controller must exist before the presenter can hold a reference to it, and that `make` is the only supported construction path.

- [ ] **Step 5: Create `ArticleListPresenterTests.swift`**

This file is the point of the template — it must be complete and runnable, not sketched:

```swift
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
}

// MARK: - Test doubles

enum TestError: Error { case any }

struct ArticleRepositoryStub: ArticleRepository {
    let result: Result<[Article], Error>
    func fetch() async throws -> [Article] { try result.get() }
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
```

Note in a header comment that `Article.fixture()` is expected from the host app's test helpers, and that `ArticleListViewSpy` implements only the `ApiProtocol` members this screen uses.

- [ ] **Step 6: Create `templates/ios/uikit_mvp_screen/README.md`**

Follow the shape of `templates/ios/clean_architecture_feature/README.md`. Must state: rename `Article`/`ArticleList` to the real domain; the Swift here is illustrative and not part of a compiled package, so cross-file symbols will not resolve in isolation; `ApiProtocol` and `PresenterProtocol` are assumed to exist in the host app. Link to `../../../skills/architecture/ios/mvp.md`, `../../../standards/uikit_standards.md`, and `../../../checklists/uikit_review.md`.

- [ ] **Step 7: Verify type consistency across the template**

Read all five Swift files together and confirm: `ArticleRepository.fetch()` signature identical in all uses; `ArticleListViewProtocol` members match exactly between the contract, the view controller, and the spy; `ArticleListCoordinatorDelegate` is declared exactly once, in the contract; `make(articles:delegate:)` matches Task 5's call site exactly.

- [ ] **Step 8: Lint, link-check, commit**

```bash
npx --yes markdownlint-cli2 "templates/ios/uikit_mvp_screen/README.md"
npx --yes markdown-link-check --quiet --config .github/mlc_config.json templates/ios/uikit_mvp_screen/README.md
git add templates/ios/uikit_mvp_screen/
git commit -m "feat(uikit): add UIKit MVP screen template with presenter tests"
```

---

### Task 7: Presenter testing section in the iOS unit testing skill

**Files:**
- Modify: `skills/testing/ios/unit_testing.md`

**Interfaces:**
- Consumes: the test doubles from Task 6 Step 5.
- Produces: a `## Testing Presenters (UIKit)` section referenced by Task 9's agent file.

- [ ] **Step 1: Read the existing file**

```bash
sed -n '1,120p' skills/testing/ios/unit_testing.md
```

Note that its `## Overview` currently recommends Swift Testing (`@Test`/`#expect`) for new code.

- [ ] **Step 2: Add an iOS-version caveat to `## Overview`**

Add one sentence: Swift Testing requires iOS 16 tooling and a Swift 6 toolchain; on codebases with an iOS 13 or 14 deployment target, use XCTest, which remains fully supported.

- [ ] **Step 3: Insert a `## Testing Presenters (UIKit)` section immediately after `## Swift Examples`**

Explain the two doubles a presenter test needs — a spy view capturing calls, and a stub repository returning a fixed `Result` — and that the presenter's `Task { }` hop means assertions must wait on an `XCTestExpectation` rather than reading state immediately. Include the `ArticleRepositoryStub` and `ArticleListViewSpy` code from Task 6 Step 5 verbatim, plus the success-case test.

Do **not** add a `ui:` key to this file. It covers both paradigms.

- [ ] **Step 4: Lint, link-check, commit**

```bash
npx --yes markdownlint-cli2 "skills/testing/ios/unit_testing.md"
npx --yes markdown-link-check --quiet --config .github/mlc_config.json skills/testing/ios/unit_testing.md
git add skills/testing/ios/unit_testing.md
git commit -m "docs(uikit): add presenter testing guidance to iOS unit testing skill"
```

---

### Task 8: UIKit-to-SwiftUI migration workflow

**Files:**
- Create: `workflows/migrate_uikit_to_swiftui.md`

**Interfaces:**
- Consumes: `skills/architecture/ios/mvp.md` (Task 2), `skills/concurrency/ios/promisekit_to_async.md` (Task 3).
- Produces: `workflows/migrate_uikit_to_swiftui.md`, referenced by the routing table in Task 11.

- [ ] **Step 1: Write the file using the workflow section convention**

Title `# Workflow: Migrate a UIKit Screen to SwiftUI`. Sections: `## Objective`, `## Inputs`, `## Outputs`, `## Step-by-Step Process`, `## Validation Steps`, `## Failure Scenarios`, `## AI Agent Instructions`, `## Acceptance Criteria`.

`## Objective` — replace one leaf screen's view layer with SwiftUI while UIKit retains ownership of navigation, so the app ships after every step.

`## Step-by-Step Process` — ordered and explicit:

1. **Choose a leaf screen.** It must have no children it pushes, or push only through a coordinator. Screens that push directly are migrated last.
2. **Extract the repository seam first** if the presenter still calls a singleton, per `../skills/concurrency/ios/promisekit_to_async.md`. Do not skip this — a SwiftUI view backed by a singleton is no more testable than the controller it replaced.
3. **Write the SwiftUI view and an `@MainActor` `ObservableObject` view model** consuming the same repository protocol the presenter used.
4. **Host it** from a `UIHostingController`, returned by the same factory signature the old view controller exposed, so every existing call site is unchanged.
5. **Delete the old Contract, View, ViewController, and Presenter** in a separate commit.
6. **Leave navigation in UIKit.** The hosting controller is still pushed by the existing navigation controller or coordinator.

`## Failure Scenarios` — the screen turns out not to be a leaf (stop; migrate its children first); the presenter is shared by two screens (extract the shared logic into a use case before migrating either); the SwiftUI view needs a UIKit-only control (wrap it in `UIViewRepresentable` rather than abandoning the migration).

`## Acceptance Criteria` — the factory signature is unchanged; no call site outside the screen was edited; the old four files are deleted; the view model has at least one unit test.

- [ ] **Step 2: Lint, link-check, commit**

```bash
npx --yes markdownlint-cli2 "workflows/migrate_uikit_to_swiftui.md"
npx --yes markdown-link-check --quiet --config .github/mlc_config.json workflows/migrate_uikit_to_swiftui.md
git add workflows/migrate_uikit_to_swiftui.md
git commit -m "feat(uikit): add UIKit to SwiftUI migration workflow"
```

---

### Task 9: UIKit Expert agent

**Files:**
- Create: `agents/uikit_expert.md`
- Create: `.claude/agents/uikit-expert.md`

**Interfaces:**
- Consumes: Tasks 1-8. Every link target must already exist.
- Produces: the agent role referenced by the routing table in Task 11.

- [ ] **Step 1: Read the peer role file to match its shape exactly**

```bash
cat agents/swiftui_expert.md
cat .claude/agents/swiftui-expert.md
```

- [ ] **Step 2: Create `agents/uikit_expert.md`**

Title `# Agent: UIKit Expert`, subtitle blockquote `> Tier 2 — Implementation. Owns programmatic UIKit views, MVP contracts, presenters, and navigation.` Then the eight sections in the same order as `swiftui_expert.md`.

`## Rules` — these are the load-bearing ones and must appear:

```markdown
- **The presenter owns state; the view renders it.** No business logic in a view controller.
- **Never import UIKit into a presenter.**
- **Inject every dependency through the initializer as a protocol.** No `.shared` access.
- **`init` does no work.** Use an explicit `onViewDidLoad()` entry point.
- **Hold the view `weak`; mark presenters `@MainActor` and `final`.**
- **Layout lives in a `UIView` subclass**, never in the view controller.
- **Follow the surrounding convention.** Do not convert existing MVP screens to MVVM.
```

`## Related` links: `../standards/uikit_standards.md`, `../skills/architecture/ios/mvp.md`, `../skills/ui/ios/uikit_view_layer.md`, `../skills/ui/ios/massive_view_controller.md`, `../skills/architecture/ios/coordinator_navigation.md`, `../skills/concurrency/ios/promisekit_to_async.md`, `../templates/ios/uikit_mvp_screen/`, `../checklists/uikit_review.md`, `../workflows/migrate_uikit_to_swiftui.md`.

- [ ] **Step 3: Create `.claude/agents/uikit-expert.md`**

Match the peer stub exactly, changing only the role:

```markdown
---
name: uikit-expert
description: Tier 2 — Implementation. Owns programmatic UIKit views, MVP contracts, presenters, and navigation. Use for building or modifying UIKit screens, presenters, view controllers, and navigation flows in legacy or UIKit-first codebases.
---

You are the **UIKit Expert** from this repo's agent toolkit.

First read `agents/uikit_expert.md` and adopt it fully — purpose, responsibilities, rules,
and coding standards. Honor the operating principles in `AGENTS.md`, conform to `standards/`,
and self-review against `checklists/uikit_review.md` before finishing.
```

- [ ] **Step 4: Lint, link-check, commit**

```bash
npx --yes markdownlint-cli2 "agents/uikit_expert.md" ".claude/agents/uikit-expert.md"
npx --yes markdown-link-check --quiet --config .github/mlc_config.json agents/uikit_expert.md
```

Expected: fully clean. Every link target now exists.

```bash
git add agents/uikit_expert.md .claude/agents/uikit-expert.md
git commit -m "feat(uikit): add UIKit Expert agent"
```

---

### Task 10: Presentation-pattern default across all five entry points

**Files:**
- Modify: `AGENTS.md:15`, `AGENTS.md:20`
- Modify: `CLAUDE.md:34`, `CLAUDE.md:38`
- Modify: `GEMINI.md:18`
- Modify: `.cursorrules:17`
- Modify: `.windsurfrules:17`

**Interfaces:**
- Consumes: nothing.
- Produces: the reworded defaults that Task 11's routing table depends on.

Every AI platform's entry file carries its own copy of the MVVM assertion. **All five must change in one commit**, or a Cursor user receives different architecture guidance than a Claude user. That consistency is the entire point of this task.

- [ ] **Step 1: Confirm the current state of all five lines**

```bash
grep -n "MVVM" AGENTS.md CLAUDE.md GEMINI.md .cursorrules .windsurfrules
```

Expected: exactly five hits, at `AGENTS.md:15`, `CLAUDE.md:34`, `GEMINI.md:18`, `.cursorrules:17`, `.windsurfrules:17`. If the count differs, stop and re-read the files — line numbers may have drifted.

- [ ] **Step 2: Replace the MVVM assertion in all five**

Each file phrases its surrounding sentence slightly differently, so preserve each one's existing prefix and punctuation and change only the pattern clause to:

> the presentation pattern that matches the UI framework — MVVM for SwiftUI, MVP for UIKit

For example `CLAUDE.md:34` becomes:

```markdown
- Clean Architecture (Domain / Data / Presentation) + the presentation pattern that matches
  the UI framework — MVVM for SwiftUI, MVP for UIKit; respect SOLID.
```

- [ ] **Step 3: Add the legacy clause to the two Swift Concurrency lines**

`AGENTS.md:20` and `CLAUDE.md:38` keep Swift Concurrency as the default for new code. Append:

> On legacy targets, bridge existing promise and completion-handler APIs at the data boundary rather than rewriting call sites.

- [ ] **Step 4: Verify no MVVM assertion survives**

```bash
grep -n "MVVM" AGENTS.md CLAUDE.md GEMINI.md .cursorrules .windsurfrules
```

Expected: five hits, each now inside the "MVVM for SwiftUI, MVP for UIKit" clause. Zero unconditional assertions.

- [ ] **Step 5: Lint and commit**

```bash
npx --yes markdownlint-cli2 "AGENTS.md" "CLAUDE.md" "GEMINI.md"
git add AGENTS.md CLAUDE.md GEMINI.md .cursorrules .windsurfrules
git commit -m "feat(uikit): select presentation pattern from UI framework across all entry points"
```

**Note:** `AGENTS.md`, `CLAUDE.md`, and `README.md` had unrelated uncommitted modifications before this plan began. Stage them deliberately or stash them first — do not sweep them into this commit.

---

### Task 11: Paradigm detection, routing, and README

**Files:**
- Modify: `AGENTS.md` — scoping section at line 29, shared-layer claim at line 51, routing table at line 115, Tier 2 mermaid graph
- Modify: `CLAUDE.md:15` — detection step
- Modify: `README.md` — lines 38, 127, 278, and the mermaid graph at line 331

**Interfaces:**
- Consumes: `agents/uikit_expert.md` (Task 9), `workflows/migrate_uikit_to_swiftui.md` (Task 8), `skills/ui/ios/massive_view_controller.md` (Task 4).
- Produces: the wired control plane. This is the task that makes everything else reachable.

- [ ] **Step 1: Record the "before" behavioral answer**

Before editing, ask a fresh agent session: *"This iOS app uses programmatic UIKit with presenters. How should I structure a new list screen?"* Save the answer. It should recommend SwiftUI and MVVM — the wrong answer this pack exists to fix.

- [ ] **Step 2: Rename and extend the scoping section in `AGENTS.md:29`**

Rename `## Platform Scoping` to `## Platform & Paradigm Scoping`. After the existing platform detection table, add the paradigm subsection, applied only once `platform: ios` is established:

```markdown
| Signal | Paradigm |
|--------|----------|
| `@main struct …: App` | `swiftui` |
| `AppDelegate` + `SceneDelegate`, no `App` struct | `uikit` |
| `UIViewController` subclasses dominate the UI tree | `uikit` |
| Both present, plus `UIHostingController` | `mixed` |
```

Then state, in prose, all four rules from spec sections 3.2 to 3.4:

- **New projects default to `swiftui`.** With no existing UI tree to inspect, the paradigm is a choice rather than a discovery, and SwiftUI remains the toolkit's primary focus. UIKit is chosen for greenfield work only when the user asks.
- **Existing codebases with conflicting signals: ask.** Never guess at a codebase's architecture silently.
- **Mixed resolves to a dominant and a secondary paradigm.** Dominant holds the majority of the UI tree. Existing code is read and modified under the dominant paradigm's rules. New screens may use the secondary, but only via `workflows/migrate_uikit_to_swiftui.md` — never ad hoc.
- **Loading rule.** Load files where `platform:` matches and (`ui:` is absent or matches the detected paradigm). In mixed mode, load both.

Document the front-matter key itself with an example, and state that omitting `ui:` means the file applies to both paradigms.

- [ ] **Step 3: Correct the shared-layer claim at `AGENTS.md:51`**

It currently says `standards/` is "shared (always in scope, never forked per platform)". `swiftui_standards.md` has always been paradigm-specific, so the claim was already inaccurate. Reword to note that `standards/` is shared across platforms but contains paradigm-specific files selected by the same `ui:` rule.

- [ ] **Step 4: Update the routing table at `AGENTS.md:115`**

Replace the single "New screen / UI change" row with two, and add two more rows:

```markdown
| New screen / UI change (SwiftUI) | SwiftUI Expert | SwiftUI → Accessibility → Testing → Reviewer |
| New screen / UI change (UIKit) | UIKit Expert | UIKit → Accessibility → Testing → Reviewer |
| Massive view controller / legacy cleanup | Refactoring Expert | Refactoring → UIKit → Testing → Reviewer |
| UIKit → SwiftUI migration | iOS Architect | Architect → UIKit → SwiftUI → Testing → Reviewer |
```

Add a sentence directly beneath: the UI row is selected by the paradigm detected in Platform & Paradigm Scoping, not by user preference.

- [ ] **Step 5: Add the UIKit node to both mermaid graphs**

In the `AGENTS.md` Tier 2 subgraph, add `UIK[UIKit Expert]` beside `UI[SwiftUI Expert]` and include it in the `ARCH -->` and `--> SEC & TEST` edges. Mirror the same change in `README.md:331`.

- [ ] **Step 6: Update `CLAUDE.md:15`**

Extend detection step 1: after the platform is identified as `ios`, detect the UI paradigm per the table in `AGENTS.md`, and load only that paradigm's files. Note that new projects default to SwiftUI.

- [ ] **Step 7: Update `README.md`**

- Line 38: keep "Primary focus: **iOS / Swift / SwiftUI**" and add that legacy **UIKit + MVP** codebases are supported as a first-class paradigm.
- Line 127: add `- [UIKit Expert](agents/uikit_expert.md) — programmatic views, MVP contracts, presenters, navigation` directly beneath the SwiftUI Expert entry.
- Line 278, the "Multi-platform by design" paragraph: add that within iOS the agent also detects the UI paradigm and loads only its files, and that omitting the key means content applies to both.

- [ ] **Step 8: Record the "after" behavioral answer**

Ask a fresh agent session the same question from Step 1. Expected: MVP guidance, the four-file Contract convention, an injected repository protocol, and no suggestion to rewrite in SwiftUI. **If it still recommends MVVM, this task is not done** — re-check that all five entry points from Task 10 were actually saved.

- [ ] **Step 9: Lint, link-check, commit**

```bash
npx --yes markdownlint-cli2 "AGENTS.md" "CLAUDE.md" "README.md"
npx --yes markdown-link-check --quiet --config .github/mlc_config.json AGENTS.md CLAUDE.md README.md
git add AGENTS.md CLAUDE.md README.md
git commit -m "feat(uikit): add UI paradigm detection, routing, and docs"
```

---

### Task 12: Directory indexes, verify thresholds, and full validation

**Files:**
- Modify: `verify.sh`
- Modify: `agents/README.md`, `skills/README.md`, `standards/README.md`, `checklists/README.md`, `workflows/README.md`, `templates/README.md`

**Interfaces:**
- Consumes: every file created in Tasks 1-9.
- Produces: a repository that passes all three CI gates.

- [ ] **Step 1: Raise the `verify.sh` thresholds — the failing test**

Edit the five `check` lines, raising each floor by the number of files this plan adds:

```bash
check "agents/ (≥15 files)"    "[ \$(ls agents/*.md 2>/dev/null | wc -l) -ge 15 ]"
check "skills/ (≥36 files)"    "[ \$(find skills -name '*.md' 2>/dev/null | wc -l) -ge 36 ]"
check "workflows/ (≥13 files)" "[ \$(ls workflows/*.md 2>/dev/null | wc -l) -ge 13 ]"
check "checklists/ (≥9 files)" "[ \$(ls checklists/*.md 2>/dev/null | wc -l) -ge 9 ]"
check "standards/ (≥8 files)"  "[ \$(ls standards/*.md 2>/dev/null | wc -l) -ge 8 ]"
```

These remain floors below the true counts, matching the existing convention in that script.

- [ ] **Step 2: Run `verify.sh` and confirm it passes**

```bash
./verify.sh
```

Expected: all checks pass. If any fails, a file from Tasks 1-9 is missing — find it before continuing. To see the red state this guards against, `git stash` the new files and re-run; the corresponding check fails.

- [ ] **Step 3: Update the six directory index files**

Each is a plain list; add one entry per new file, matching the surrounding format exactly.

- `agents/README.md` — UIKit Expert, in the Tier 2 group beside the SwiftUI Expert.
- `standards/README.md` — `uikit_standards.md`.
- `checklists/README.md` — `uikit_review.md`.
- `workflows/README.md` — `migrate_uikit_to_swiftui.md`.
- `templates/README.md` — `- [uikit_mvp_screen/](ios/uikit_mvp_screen/) — MVP screen with injected repository and presenter tests`.
- `skills/README.md` — the five new skills, the two new topic directories (`ui/`, `concurrency/`), **and** an explicit note that `skills/ui/` currently holds UIKit files only because SwiftUI's equivalent guidance lives in `standards/swiftui_standards.md` and `agents/swiftui_expert.md`. Record it as a known gap so it does not read as an oversight.

- [ ] **Step 4: Run the full CI gate set exactly as CI does**

```bash
npx --yes markdownlint-cli2 "**/*.md" "#node_modules"
npx --yes markdown-link-check --quiet --config .github/mlc_config.json \
  $(find . -name '*.md' -not -path './node_modules/*')
./verify.sh
```

Expected: link-check fully clean; `verify.sh` all green; markdownlint reporting **only** the known pre-existing `.superpowers/sdd/progress.md` MD022 error.

- [ ] **Step 5: Confirm the front-matter axis is correct across all new skills**

```bash
head -5 skills/architecture/ios/mvp.md skills/architecture/ios/coordinator_navigation.md \
        skills/ui/ios/uikit_view_layer.md skills/ui/ios/massive_view_controller.md \
        skills/concurrency/ios/promisekit_to_async.md
```

Expected: `ui: uikit` on the first four; **absent** on `promisekit_to_async.md`.

- [ ] **Step 6: Confirm no proprietary content leaked**

```bash
grep -rin "phillip\|bakong\|regula\|ipification\|/Users/" \
  --include='*.md' --include='*.swift' --exclude-dir=node_modules --exclude-dir=.git \
  agents/ skills/ standards/ checklists/ workflows/ templates/ .claude/
```

Expected: **zero matches.** Any hit is a blocker — remove it before committing.

- [ ] **Step 7: Commit**

```bash
git add verify.sh agents/README.md skills/README.md standards/README.md \
        checklists/README.md workflows/README.md templates/README.md
git commit -m "feat(uikit): update directory indexes and verification thresholds"
```

---

## Done criteria

- [ ] `./verify.sh` passes with the raised thresholds.
- [ ] `markdown-link-check` is clean across every Markdown file.
- [ ] `markdownlint-cli2` reports only the known pre-existing `.superpowers/sdd/progress.md` error.
- [ ] The Task 11 Step 8 behavioral check returns MVP guidance, not MVVM.
- [ ] The Task 12 Step 6 proprietary-content grep returns zero matches.
- [ ] No existing content file was edited except the fourteen listed in the File Structure section.
