---
platform: flutter
---

# Skill: State Management

## Overview

This toolkit's default Flutter presentation pattern is **Riverpod**: a `Notifier`/`AsyncNotifier`
owns an immutable state value, widgets `ref.watch` it, and the framework rebuilds only the
widgets that read what changed. It is the Flutter analogue of the toolkit's iOS MVVM rule —
notifier ≈ ViewModel, `AsyncValue`/sealed state ≈ the state enum. Riverpod is also the DI graph
(see [`dependency_injection.md`](dependency_injection.md)), so one mechanism covers both state and
wiring. **BLoC/Cubit is a supported alternative** — see the section below — but a codebase picks
one and does not mix.

## Use Cases

- Screen state that has real loading/error/empty branches (anything backed by I/O).
- State shared across routes (session, cart, feature flags) without passing it down the tree.
- Derived state that must recompute when an input changes (`ref.watch` another provider).
- Anything you want to unit-test without pumping a widget.

## Best Practices

- **State is immutable.** Never mutate in place; assign a new value (`state = state.copyWith(…)`).
  Riverpod compares by identity, so an in-place mutation simply will not rebuild.
- **Model async screens with `AsyncValue`** via `AsyncNotifier` — it encodes loading/data/error in
  one type and gives you `when`/`switch` exhaustiveness for free. Use a hand-written **sealed
  state class** when a screen has states `AsyncValue` cannot express (e.g. `Loaded` plus
  `RefreshingWithStaleData`).
- **Never scatter `bool isLoading` / `String? error` flags.** They permit impossible combinations;
  a sealed union does not.
- `ref.watch` in `build()`; `ref.read` inside callbacks and notifier methods; `ref.listen` for
  side effects (snackbars, navigation) — never navigate from `build()`.
- **Scope rebuilds with `select`**: `ref.watch(cartProvider.select((c) => c.itemCount))` rebuilds
  on count changes only.
- Use `AsyncNotifier.build()` for the initial load — do not kick off loading from `initState`.
  Wrap mutations in `AsyncValue.guard` so errors land in state instead of the zone.
- Prefer `autoDispose` (the default for the modern codegen) and reach for `keepAlive` deliberately,
  with a comment explaining the lifetime.
- Use `family` for parameterized providers (`articleProvider(id)`), and pass **ids**, not objects.
- Notifiers contain presentation logic only. Business rules belong in use cases.

## Anti-Patterns

- ❌ Mutating a list/map inside state (`state.items.add(x)`) — no rebuild fires.
- ❌ `ref.read` inside `build()` (state changes silently stop rebuilding the widget).
- ❌ `ref.watch` inside a callback or a notifier method (creates a stale, un-disposed dependency).
- ❌ Calling `Navigator`/`showDialog` from a notifier — notifiers must not import `BuildContext`.
- ❌ Business logic (validation, pricing, retry policy) living in the notifier instead of a use case.
- ❌ `StateNotifier`/`ChangeNotifier` for new code — `Notifier`/`AsyncNotifier` is the current API.
- ❌ One god-provider holding the whole app's state; split by concern.
- ❌ Mixing Riverpod and BLoC in the same codebase.

## Checklist

- [ ] Every screen's state is an `AsyncValue` or a sealed union — no loose boolean flags.
- [ ] State objects are immutable with `copyWith`; no in-place mutation.
- [ ] `ref.watch` only in `build`/other providers; `ref.read` only in callbacks.
- [ ] Mutations use `AsyncValue.guard` (or set an explicit failure state) — errors never escape.
- [ ] Rebuild scope narrowed with `select` where the state object is large.
- [ ] Notifier has no `BuildContext`, no `Navigator`, no direct `Dio`/database access.
- [ ] Every notifier has a unit test using `ProviderContainer` with overridden dependencies.
- [ ] `keepAlive` is used deliberately and commented; everything else auto-disposes.

## Dart Examples

```dart
// presentation/articles_notifier.dart
class ArticlesNotifier extends AsyncNotifier<List<Article>> {
  @override
  Future<List<Article>> build() => ref.watch(getArticlesProvider)();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(getArticlesProvider)());
  }
}

final articlesProvider =
    AsyncNotifierProvider<ArticlesNotifier, List<Article>>(ArticlesNotifier.new);
```

```dart
// presentation/articles_screen.dart — every state handled, no flags
class ArticlesScreen extends ConsumerWidget {
  const ArticlesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articles = ref.watch(articlesProvider);

    return switch (articles) {
      AsyncData(:final value) when value.isEmpty => const EmptyView(),
      AsyncData(:final value) => ArticleList(articles: value),
      AsyncError(:final error) => ErrorView(
          message: '$error',
          onRetry: () => ref.read(articlesProvider.notifier).refresh(),
        ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
```

```dart
// ✅ a hand-written sealed union when AsyncValue is not expressive enough
sealed class CheckoutState {
  const CheckoutState();
}

final class CheckoutIdle extends CheckoutState {
  const CheckoutIdle();
}

final class CheckoutSubmitting extends CheckoutState {
  const CheckoutSubmitting();
}

final class CheckoutSucceeded extends CheckoutState {
  const CheckoutSucceeded(this.orderId);
  final String orderId;
}

final class CheckoutFailed extends CheckoutState {
  const CheckoutFailed(this.failure);
  final Failure failure;
}
```

```dart
// ❌ impossible states are representable        ✅ they are not
class BadState {                              // sealed CheckoutState above
  bool isLoading = false;                     // — loading AND failed cannot
  String? error;                              //   coexist by construction
  List<Article>? articles;                    //
}
```

## When to Choose BLoC/Cubit Instead

Riverpod is the default. Pick **BLoC/Cubit** when:

- The team already runs BLoC across a large codebase — consistency beats the migration cost.
- You want an explicit, replayable **event stream** for audit or analytics: BLoC's
  `Event → Bloc → State` pipeline records intent, which `Notifier` method calls do not.
- Your org's review standards already encode `bloc_test`, `BlocObserver`, and event naming.

If you choose BLoC, the toolkit's rules translate directly: states remain immutable sealed
classes, one `Cubit`/`Bloc` per screen, no `BuildContext` inside it, business rules stay in use
cases, and DI moves to `get_it`+`injectable` or `RepositoryProvider`. Use `Cubit` unless you
actually need the event log — `Bloc` costs an event class per interaction. **Do not mix the two
libraries in one codebase**; the resulting two sources of truth are the failure mode this rule
exists to prevent.

## Common Interview Questions

- Why does mutating a list inside Riverpod state fail to rebuild the UI?
- `ref.watch` vs `ref.read` vs `ref.listen` — when is each correct?
- What problem does `select` solve, and what is the cost of not using it?
- How does `AsyncValue.guard` change error handling compared with a `try/catch` in the widget?
- When does `autoDispose` dispose, and when would you `keepAlive`?
- What does BLoC give you that Riverpod does not, and is it worth an event class per interaction?

## AI Implementation Notes

- Default to `AsyncNotifier` + `AsyncValue` for any screen backed by I/O; reach for a hand-written
  sealed class only when `AsyncValue` cannot express the state.
- Generate exhaustive `switch` over the state — never an `if (isLoading)` ladder.
- Never generate `StateNotifier` or `ChangeNotifier` for new code.
- Detect the existing pattern before writing: if `flutter_bloc` is in `pubspec.yaml` and Riverpod
  is not, follow BLoC and say so rather than introducing a second state library.
- Always emit a notifier unit test alongside, using `ProviderContainer` with overridden providers.
- iOS counterpart: [`../ios/mvvm.md`](../ios/mvvm.md).
- Related: [`dependency_injection.md`](dependency_injection.md),
  [`../../../standards/flutter_standards.md`](../../../standards/flutter_standards.md),
  [`../../testing/flutter/unit_testing.md`](../../testing/flutter/unit_testing.md).
