---
platform: flutter
---

# Standard: Flutter Standards

Rules for Flutter UI code. Complements [`dart_coding_standards.md`](dart_coding_standards.md).
Enforced in review by the [Flutter Expert](../agents/flutter_expert.md) and
[Accessibility Expert](../agents/accessibility_expert.md), gated by
[`../checklists/flutter_review.md`](../checklists/flutter_review.md).

## Widgets

- A widget is a **function of state** — no networking, persistence, or business logic in `build()`.
- `build()` must be cheap and side-effect free. It can be called many times per second.
- Extract a subwidget when `build` exceeds ~40 lines or repeats.
- One primary widget per file plus its tightly-coupled private subwidgets.
- **`const` wherever it applies** — a `const` widget is skipped on rebuild. This is enforced by
  `prefer_const_constructors`.
- Prefer a `StatelessWidget`/`ConsumerWidget`. Use `StatefulWidget` only for genuinely
  widget-local, ephemeral state (an animation controller, a `TextEditingController`, a focus node)
  — never for screen state.
- Dispose every controller, listener, and subscription you create.

```dart
// ✅ thin widget bound to state
@override
Widget build(BuildContext context, WidgetRef ref) {
  final articles = ref.watch(articlesProvider);
  return switch (articles) {
    AsyncData(:final value) when value.isEmpty => const EmptyView(),
    AsyncData(:final value) => ArticleList(articles: value),
    AsyncError(:final error) => ErrorView(message: '$error'),
    _ => const LoadingView(),
  };
}
```

## State Management

The default is **Riverpod** — `Notifier`/`AsyncNotifier` owning an immutable state value. BLoC/Cubit
is the documented alternative; see
[`../skills/architecture/flutter/state_management.md`](../skills/architecture/flutter/state_management.md).
**A codebase uses one, never both.**

- One **source of truth** per piece of state. Do not copy provider data into local `setState`.
- **State is immutable**; emit a new value (`copyWith`, a new sealed instance). In-place mutation
  will not trigger a rebuild.
- Model every screen as an `AsyncValue` or a **sealed state union**
  (`Idle | Loading | Loaded | Failure`) — never `bool isLoading` plus `String? error`.
- `ref.watch` in `build` and inside providers; `ref.read` in callbacks and notifier methods;
  `ref.listen` for side effects.
- Narrow rebuilds with `select`; scope `Consumer` to the smallest dependent subtree.
- Notifiers hold **presentation logic only** — no `BuildContext`, no `Navigator`, no direct HTTP or
  database access. Business rules live in use cases.
- `autoDispose` is the default; `keepAlive` requires a comment stating the lifetime and why.
- New code uses `Notifier`/`AsyncNotifier`. Do not introduce `StateNotifier` or `ChangeNotifier`.

## Navigation

- Navigation is **declarative and typed** via `go_router`; one route table for the app.
- Routes carry ids and primitives, **never entity objects** — a cold-start deep link has no object.
- Auth gating is a single `redirect` wired to `refreshListenable`, not a check in each screen.
- `go` replaces the stack; `push` stacks. Choose deliberately.
- Never navigate from a notifier. Surface intent as state and navigate from `ref.listen`.
- Never use a `BuildContext` after an `await` without `if (!context.mounted) return;`.

## Async & Errors in the UI

- Every state a screen can be in is rendered: loading, loaded, **empty**, and error.
- Every error state offers a retry or a clear next step; never a dead end.
- Wrap notifier mutations in `AsyncValue.guard` (or set an explicit failure state) so no error
  escapes into the zone.
- Show a distinct treatment for a partial failure (e.g. page 3 of a list failed) — keep the loaded
  content and surface a retry on the tail, not a full-screen error.

## Styling & Theming

- **No hardcoded colors, sizes, or text styles in widgets.** Read from `Theme.of(context)`, a
  `ThemeExtension`, or a design-token class.
- Define light and dark themes together; never assume a brightness.
- Use `Theme.of(context).textTheme` styles rather than raw `TextStyle(fontSize: …)`, so text scaling
  works.
- Spacing comes from a token scale, not scattered magic numbers.

```dart
// ✅                                        // ❌
color: Theme.of(context).colorScheme.primary  color: const Color(0xFF0A84FF)
style: Theme.of(context).textTheme.titleMedium  style: const TextStyle(fontSize: 17)
```

## Accessibility

- Every interactive control has an accessible label — a visible text child, or a `Semantics` label
  for icon-only controls.
- Minimum tap target **48×48dp**; wrap small icons rather than shrinking the target.
- Support text scaling: no fixed-height text containers, no `Text` in a box that cannot grow.
  Verify at the largest system text size.
- Meet contrast guidelines; assert them in widget tests with `meetsGuideline(textContrastGuideline)`.
- Give a `ValueKey` to anything a test or automation drives; treat it as part of the contract.
- Decorative images get `excludeFromSemantics: true`; meaningful ones get a `semanticLabel`.

## Lists & Performance

- Long lists use `ListView.builder`/`SliverList`, never a `Column` in a `SingleChildScrollView`.
- Provide stable keys (`ValueKey(item.id)`) so element identity survives reordering.
- Set `itemExtent`/`prototypeItem` when rows are uniform.
- Decode images at display size (`cacheWidth`/`cacheHeight`).
- Move CPU-bound work to an isolate; never parse a large payload on the UI isolate.
- Full guidance: [`../skills/performance/flutter/rendering_optimization.md`](../skills/performance/flutter/rendering_optimization.md).

## Package Baseline

The toolkit's default choices. Deviating is fine with a stated reason; drifting silently is not.
Reference these by name in prose and verify the current API against the package's own docs before
generating code — the Flutter ecosystem moves faster than any document.

| Concern | Default | Notes |
|---|---|---|
| State + DI | `flutter_riverpod` | `Notifier`/`AsyncNotifier`. `flutter_bloc` is the documented alternative. |
| Navigation | `go_router` | `go_router_builder` for typed routes. `auto_route` is the alternative. |
| HTTP | `dio` | `http` is fine when no interceptors are needed. |
| JSON | `json_serializable` | Or `freezed` when you also want unions and `copyWith`. |
| Local database | `drift` | `sqflite` for raw SQL. `shared_preferences` for small, non-sensitive values only. |
| Secrets | `flutter_secure_storage` | Keychain / Keystore. Never `shared_preferences`. |
| OAuth | `flutter_appauth` | Authorization Code + PKCE, system browser. |
| Realtime | `web_socket_channel` | With an explicit connection state machine. |
| Test doubles | `mocktail` | Prefer hand-written fakes; `mocktail` to verify interactions. |
| E2E | `integration_test` | `patrol` when native dialogs/permissions are involved. |
| Lints | `very_good_analysis` | Or `flutter_lints`. `prefer_const_constructors` must be on. |

## Related

- [`dart_coding_standards.md`](dart_coding_standards.md) — language rules.
- [`architecture_standards.md`](architecture_standards.md) — layers, SOLID, DI.
- [`../checklists/flutter_review.md`](../checklists/flutter_review.md) — the review gate.
- [`../agents/flutter_expert.md`](../agents/flutter_expert.md) — the implementing role.
