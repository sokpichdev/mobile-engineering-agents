# Template: Riverpod Screen

A screen with an `AsyncNotifier`, a sealed state type, and every state handled. See
[`standards/flutter_standards.md`](../../../standards/flutter_standards.md) and
[`skills/architecture/flutter/state_management.md`](../../../skills/architecture/flutter/state_management.md).

## Folder Structure

```text
presentation/
├── {{screen}}_screen.dart       // ConsumerWidget — renders state, no logic
├── {{screen}}_notifier.dart     // AsyncNotifier — presentation logic only
├── {{screen}}_state.dart        // sealed state (when AsyncValue isn't enough)
└── widgets/
    ├── {{screen}}_content.dart
    ├── empty_view.dart
    └── error_view.dart
```

## State

Most screens need nothing beyond `AsyncValue<T>` — it already encodes loading, data, and error:

```dart
// AsyncNotifier<List<Article>> gives you AsyncLoading / AsyncData / AsyncError for free.
```

Write a sealed union only when the screen has a state `AsyncValue` cannot express:

```dart
sealed class ArticlesState {
  const ArticlesState();
}

final class ArticlesLoaded extends ArticlesState {
  const ArticlesLoaded({required this.articles, this.isRefreshing = false});

  final List<Article> articles;
  final bool isRefreshing; // stale content on screen while a refresh runs

  ArticlesLoaded copyWith({List<Article>? articles, bool? isRefreshing}) => ArticlesLoaded(
        articles: articles ?? this.articles,
        isRefreshing: isRefreshing ?? this.isRefreshing,
      );
}
```

## Notifier

```dart
class ArticlesNotifier extends AsyncNotifier<List<Article>> {
  @override
  Future<List<Article>> build() => ref.watch(getArticlesProvider)();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    // guard() puts the error into state instead of letting it escape the zone.
    state = await AsyncValue.guard(() => ref.read(getArticlesProvider)());
  }
}

final articlesProvider =
    AsyncNotifierProvider<ArticlesNotifier, List<Article>>(ArticlesNotifier.new);
```

## Widget

```dart
class ArticlesScreen extends ConsumerWidget {
  const ArticlesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articles = ref.watch(articlesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Articles')),
      body: switch (articles) {
        // Empty is its own state — not an afterthought inside `loaded`.
        AsyncData(:final value) when value.isEmpty =>
          const EmptyView(key: Key('articles.empty')),
        AsyncData(:final value) => RefreshIndicator(
            onRefresh: () => ref.read(articlesProvider.notifier).refresh(),
            child: ArticlesContent(key: const Key('articles.content'), articles: value),
          ),
        AsyncError(:final error) => ErrorView(
            key: const Key('articles.error'),
            message: '$error',
            onRetry: () => ref.read(articlesProvider.notifier).refresh(),
          ),
        _ => const Center(
            key: Key('articles.loading'),
            child: CircularProgressIndicator(),
          ),
      },
    );
  }
}
```

## Conventions Demonstrated

- **The widget is a function of state** — no I/O, no business rules in `build()`.
- **Every state is rendered**: loading, loaded, empty, error — with a retry on the error path.
- **Keys on everything a test drives** (`articles.loading`, `articles.empty`, …), so widget tests
  find by key rather than by widget type.
- **Side effects stay in the widget** (`ref.listen`), never in the notifier — a notifier has no
  `BuildContext`.
- **Immutable state**, updated with `copyWith`, never mutated in place.

## Usage

1. Copy the folder into your feature's `presentation/`.
2. Rename `Articles`/`articles` → your screen and entity.
3. Drop the sealed state file if `AsyncValue` covers your screen.
4. Add the screen to the `go_router` route table
   ([`skills/architecture/flutter/router_navigation.md`](../../../skills/architecture/flutter/router_navigation.md)).
5. Write the widget test covering all four states
   ([`skills/testing/flutter/widget_testing.md`](../../../skills/testing/flutter/widget_testing.md)).

## Related

- Skill: [`skills/architecture/flutter/state_management.md`](../../../skills/architecture/flutter/state_management.md)
- Standard: [`standards/flutter_standards.md`](../../../standards/flutter_standards.md)
- Checklist: [`checklists/flutter_review.md`](../../../checklists/flutter_review.md)
