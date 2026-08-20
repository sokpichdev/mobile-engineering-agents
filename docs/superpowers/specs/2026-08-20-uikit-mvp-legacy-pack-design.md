# Design: UIKit + MVP Legacy Pack

- **Date:** 2026-08-20
- **Status:** Approved, pending implementation plan
- **Scope:** Extend the toolkit to serve legacy enterprise iOS codebases built on
  programmatic UIKit with MVP, without disrupting existing SwiftUI/MVVM support.

---

## 1. Problem

The toolkit currently assumes one iOS presentation stack: SwiftUI with MVVM. That
assumption is asserted as non-negotiable in five separate entry-point files, and the only
Tier 2 UI agent is the SwiftUI Expert, whose rules (`the view is a function of state`,
`@Observable`, `NavigationStack`) are actively wrong guidance for a UIKit codebase.

Pointed at a large legacy UIKit app today, the toolkit gives confidently incorrect advice.

### Reference codebase

The design is calibrated against a real production app: a ~1,600-file legacy retail banking
client. Characteristics measured directly from the source:

| Dimension | Measurement |
|-----------|-------------|
| Swift files | ~1,598 |
| Objective-C | 0 files |
| Interface Builder | 1 storyboard (launch screen only), 0 xibs |
| Layout | 100% programmatic, SnapKit |
| Presentation pattern | MVP with a Contract file; ~645 files reference `Presenter` |
| Async | PromiseKit, plus ~149 files already using `async`/`await` |
| Reactive frameworks | None (no RxSwift; Combine in 2 files) |
| SwiftUI | 42 files, 2 `UIHostingController` call sites |
| Navigation | No coordinators; view controllers push directly |
| Deployment target | iOS 13.0 (extensions at 15/16) |
| Test files | 5 total, 3 of which are utility tests |

Two findings drive the design.

**The per-screen convention is stable and worth preserving.** Every screen is four files:
`XContract.swift`, `XView.swift`, `XViewController.swift`, `XPresenter.swift`, with shared
base protocols (`PresenterProtocol`, marked `@MainActor`; `ApiProtocol`, supplying
`showLoading`/`hideLoading`/`handleApiError`). Guidance that asked this team to restructure
645 files would be ignored on sight.

**The real legacy problem is testability, not UIKit.** A representative presenter:

```swift
class RequestLoanPresenter: RequestLoanPresenterProtocol {
    weak private var view: RequestLoanViewProtocol?
    private(set) var items: [Loan] = []

    init(with view: RequestLoanViewProtocol) {
        self.view = view
        getLoan()                       // network call fired from init
    }

    func getLoan() {
        self.view?.showLoading()
        LoanCloud.shared.getLoans()     // singleton, no injected protocol
            .done { ... }
    }
}
```

Concrete singleton access plus a side effect in `init` makes the presenter unconstructible
in a test. That conflicts directly with Operating Principle 3 in `AGENTS.md` — *"Inject
dependencies through protocols. No hidden singletons in business logic."* — and explains the
5-file test suite. A UIKit pack that taught layout and navigation while ignoring this would
miss the point.

---

## 2. Goals and non-goals

### Goals

1. Support UIKit + MVP as a first-class iOS presentation stack alongside SwiftUI + MVVM.
2. Give legacy codebases an incremental path to testable presentation logic that does not
   require removing PromiseKit or restructuring existing screens.
3. Support mixed codebases mid-migration to SwiftUI as a first-class mode, not a fallback.
4. Change zero existing content files. Existing single-paradigm users must notice nothing.

### Non-goals

- Porting the pack to Android, Flutter, or React Native.
- A DI container. The reference codebase has none and does not need one for this benefit.
- Mandating a use-case layer for every screen.
- A PromiseKit removal project.
- Retrofitting coordinators across existing flows.

---

## 3. Architecture: the UI-paradigm axis

The toolkit has exactly one scoping axis today — platform — expressed as
`skills/<topic>/<platform>/`, `templates/<platform>/`, and a `platform:` front-matter key.
UIKit is not a platform; it is a second, orthogonal axis inside iOS.

### 3.1 Mechanism

Front-matter gains one **optional** key, reusing the mechanism `platform:` already uses:

```yaml
---
platform: ios
ui: uikit          # uikit | swiftui — OMIT for paradigm-neutral content
---
```

Omitting `ui:` means the file applies to both paradigms. This is the correct default for the
majority of existing content — `networking/`, `security/`, `storage/`, `clean_architecture.md`
do not depend on the view layer — which is why no existing file needs editing.

Two rejected alternatives:

- **Nested subtrees** (`skills/<topic>/ios/uikit/`) — physically cleaner, but forces
  relocating existing iOS files, breaks every cross-link in the repo, and leaves
  paradigm-neutral skills needing an awkward third bucket. High churn, low gain.
- **An `ios_legacy` pseudo-platform** — total isolation, but duplicates all
  paradigm-neutral content and makes the platform detection table dishonest, since the
  platform is still iOS.

### 3.2 Detection

Added to the `AGENTS.md` scoping section (renamed *Platform & Paradigm Scoping*), applied
only after `platform: ios` is established:

| Signal | Paradigm |
|--------|----------|
| `@main struct …: App` | `swiftui` |
| `AppDelegate` + `SceneDelegate`, no `App` struct | `uikit` |
| `UIViewController` subclasses dominate the UI tree | `uikit` |
| Both present, plus `UIHostingController` | `mixed` |

When signals conflict or are absent, **ask** — consistent with how the existing platform
detection already handles ambiguity. Never guess at a codebase's architecture silently.

### 3.3 Mixed mode

Mixed is the primary supported mode, because it is the common real-world state — the
reference codebase is 42 SwiftUI files against roughly 1,550 UIKit ones. Mixed resolves to a
**primary** and a **secondary** paradigm:

- Primary is whichever paradigm holds the majority of the UI tree.
- **Existing code** is read and modified under the primary's rules.
- **New screens** may use the secondary, but only via the migration workflow — never ad hoc.

This rule is load-bearing in both directions. It prevents an agent from rewriting a working
presenter into SwiftUI + MVVM because an entry file declared MVVM non-negotiable, and it
prevents the opposite failure of refusing SwiftUI in a codebase that has deliberately begun
adopting it.

### 3.4 Loading rule

Load files where `platform:` matches **and** (`ui:` is absent **or** matches the detected
paradigm). In mixed mode, load both paradigms.

---

## 4. Prescribed pattern

Guiding rule: **keep the convention, fix the seam.** The four-file Contract layout is
adopted as-is.

### 4.1 Contract

Existing shape, with explicit lifecycle and read-only state added:

```swift
@MainActor protocol ArticleListViewProtocol: ApiProtocol {
    func reloadList()
}

@MainActor protocol ArticleListPresenterProtocol: PresenterProtocol {
    var items: [Article] { get }
    func onViewDidLoad()
    func refresh()
}
```

### 4.2 Presenter

Exactly two changes from the current pattern — an injected protocol dependency, and no work
in `init`. The `weak` view reference, `@MainActor` isolation, `PresenterProtocol` conformance,
and `ApiProtocol` error handling are all preserved.

```swift
@MainActor
final class ArticleListPresenter: ArticleListPresenterProtocol {
    private weak var view: ArticleListViewProtocol?
    private let articles: ArticleRepository          // 1. protocol, injected
    private(set) var items: [Article] = []

    init(view: ArticleListViewProtocol, articles: ArticleRepository) {
        self.view = view
        self.articles = articles                     // 2. no work in init
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

### 4.3 The migration wedge

The mechanism that makes the above adoptable rather than aspirational:

```swift
protocol ArticleRepository {                          // Domain
    func fetch() async throws -> [Article]
}

struct ArticleCloudRepository: ArticleRepository {    // Data
    func fetch() async throws -> [Article] {
        try await withCheckedThrowingContinuation { continuation in
            ArticleCloud.shared.getArticles()
                .done { continuation.resume(returning: $0) }
                .catch { continuation.resume(throwing: $0) }
        }
    }
}
```

**PromiseKit does not have to be removed for presenters to become testable.** One thin
adapter per data source makes every presenter behind it injectable, awaitable, and
unit-testable, while the existing singleton keeps working untouched for every screen not yet
migrated. This yields a per-screen migration with no big-bang step, which is the only kind
that completes in a codebase of this size — and it turns Operating Principle 3 from an
unreachable ideal into a one-file-at-a-time task.

### 4.4 Testing

Spy view plus stub repository, on **XCTest** — the iOS 13 deployment target rules out Swift
Testing, which `skills/testing/ios/unit_testing.md` currently recommends by default. The test
case is `@MainActor`; the async hop is bridged with `XCTestExpectation`.

Working spy and stub files ship inside the template, so the first presenter test in a
codebase is a copy-paste rather than a research project. Against a 5-test baseline, lowering
that activation cost matters more than the written guidance.

### 4.5 Composition

A per-feature factory function (`ArticleListViewController.make()`). No container.

---

## 5. Deliverables

16 new files (six of them inside the template) and 14 edited files.

### 5.1 New — agent

- `agents/uikit_expert.md` — Tier 2, direct peer of the SwiftUI Expert. Same eight-section
  shape as existing role files (Purpose / Responsibilities / Rules / Coding Standards /
  Review Checklist / Common Mistakes / Example Tasks / Related). Owns view controller
  lifecycle, programmatic layout, MVP contracts, presenters, cell reuse, navigation.
- `.claude/agents/uikit-expert.md` — matching native subagent stub.

No second agent. The massive-view-controller work belongs to the existing Refactoring Expert
(Tier 3, "safe, incremental code improvement"), delivered as a skill it loads. A separate
legacy-modernization role would overlap it for no gain.

### 5.2 New — standard

- `standards/uikit_standards.md`, beside `swiftui_standards.md`. Covers the four-file
  Contract convention, programmatic Auto Layout, view controller lifecycle discipline, cell
  reuse and registration, accessibility identifiers, and `@MainActor` presenter isolation.

### 5.3 New — skills

| File | `ui:` | Covers |
|------|-------|--------|
| `skills/architecture/ios/mvp.md` | `uikit` | Contract/View/Presenter roles, weak view reference, DI, state modelling, presenter testing |
| `skills/architecture/ios/coordinator_navigation.md` | `uikit` | Lifting navigation out of view controllers |
| `skills/ui/ios/uikit_view_layer.md` | `uikit` | Programmatic Auto Layout, the view controller / view split, cell reuse, diffable data sources |
| `skills/ui/ios/massive_view_controller.md` | `uikit` | Decomposition playbook |
| `skills/concurrency/ios/promisekit_to_async.md` | *(none)* | Bridging promises and completion handlers to `async`/`await` at the data boundary |

Two new topic directories, `ui/` and `concurrency/`. `promisekit_to_async.md` carries no
`ui:` key deliberately — it is a data-boundary concern, useful regardless of view layer.

### 5.4 New — template

`templates/ios/uikit_mvp_screen/` containing `Contract.swift`, `View.swift`,
`ViewController.swift`, `Presenter.swift`, `PresenterTests.swift`, and `README.md`.

This carries the most weight of any deliverable, so it ships the **corrected** pattern from
section 4 rather than a transcription of current practice: repository protocol injected
through the initializer, no side effects in `init`, explicit state, and a spy-view test
proving it. It should read as familiar enough to adopt immediately, and different enough
that the improvement is self-evident.

Sample types follow the existing `templates/README.md` convention of neutral illustrative
names.

### 5.5 New — workflow and checklist

- `workflows/migrate_uikit_to_swiftui.md` — strangler fig via `UIHostingController`, leaf
  screens first, UIKit retaining ownership of navigation.
- `checklists/uikit_review.md`.

### 5.6 Edited — entry points

The MVVM assertion is duplicated across all five entry-point files. All five change
together, or a Cursor user receives different architecture guidance than a Claude user.

| File | Line | Current text |
|------|------|--------------|
| `AGENTS.md` | 15 | "with MVVM in the Presentation layer" |
| `CLAUDE.md` | 34 | "Clean Architecture (Domain / Data / Presentation) + MVVM" |
| `GEMINI.md` | 18 | same |
| `.cursorrules` | 17 | same |
| `.windsurfrules` | 17 | same |

New wording:

> Clean Architecture (Domain / Data / Presentation) + the presentation pattern that matches
> the UI framework — MVVM for SwiftUI, MVP for UIKit. Respect SOLID.

The Swift Concurrency defaults (`AGENTS.md:20`, `CLAUDE.md:38`) remain the default for new
code, with a clause added: on legacy targets, bridge existing promise and completion-handler
APIs at the data boundary rather than rewriting call sites.

### 5.7 Edited — routing and docs

- `AGENTS.md:29` — section renamed *Platform & Paradigm Scoping*, gains the detection table
  from section 3.2 and the mixed-mode rules from 3.3.
- `AGENTS.md:51` — the claim that `standards/` is "never forked per platform" is corrected.
  `swiftui_standards.md` has always been paradigm-specific; the wording was already
  inaccurate and is tightened rather than excepted.
- `AGENTS.md:115` — the "New screen / UI change" routing row splits by detected paradigm
  (SwiftUI Expert / UIKit Expert). Two rows added: *Massive view controller / legacy
  cleanup* to the Refactoring Expert, and *UIKit to SwiftUI migration* to the iOS Architect
  then UIKit Expert.
- Tier 2 mermaid graphs in `AGENTS.md` and `README.md:331` gain the UIKit node.
- `CLAUDE.md:15` — detection step 1 gains the paradigm sub-step.
- `README.md` lines 38, 127, and 278 — positioning, agent list, and the "Multi-platform by
  design" paragraph.
- `verify.sh` thresholds, each raised by the number of files added: agents 14 to 15, skills
  31 to 36, standards 7 to 8, checklists 8 to 9, workflows 12 to 13. These remain floors
  below the true counts, matching the existing convention in that script.
- `skills/testing/ios/unit_testing.md` — a presenter-with-spy-view section on XCTest, per
  section 4.4. The file currently recommends Swift Testing by default, which an iOS 13
  target cannot use.
- Directory index files: `agents/README.md`, `skills/README.md`, `standards/README.md`,
  `checklists/README.md`, `workflows/README.md`, `templates/README.md`.

---

## 6. Validation

1. `./verify.sh` passes with updated thresholds.
2. `npx markdownlint-cli2 "**/*.md" "#node_modules"` clean, per the Docs CI workflow.
3. `npx markdown-link-check` clean — CI checks every relative link in every Markdown file,
   so all new cross-links must resolve.
4. Commits follow Conventional Commits (`feat(uikit): …`); commitlint gates both individual
   commits and the pull request title.

---

## 7. Risks

**Public repository, private source codebase.** This toolkit is public; the reference app is
a bank's proprietary product. The pack ships patterns only — no institution name, no
absolute paths, no proprietary flows, no copied source. Template sample types are neutral.
This spec describes the reference codebase generically for the same reason.

**Asymmetric `skills/ui/`.** The directory starts UIKit-only, because SwiftUI's equivalent
guidance currently lives in its standard and agent file rather than in `skills/`. This is a
pre-existing gap, not one introduced here. It is recorded explicitly in `skills/README.md`
so it reads as a known gap rather than an oversight.

**Axis confusion for existing users.** Fully mitigated by the omit-means-both default: a
SwiftUI-only project sees no behavioral change.

**Detection misfire on mixed codebases.** Mitigated by the explicit primary/secondary
resolution in 3.3 and by the instruction to ask when signals conflict.

---

## 8. Next step

Produce an implementation plan from this spec via the writing-plans skill.
