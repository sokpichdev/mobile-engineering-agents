---
platform: flutter
---

# Skill: Pagination

## Overview

Pagination loads a list in pages instead of all at once. In Flutter the state lives in an
`AsyncNotifier` that accumulates items and tracks `hasMore`; the list widget triggers `loadMore()`
as the user approaches the end. Prefer **cursor-based** paging — offset paging silently skips or
duplicates rows when the underlying data shifts between requests.

## Use Cases

- Feeds, search results, transaction history, chat backlog.
- Any list that can grow beyond a few hundred rows.
- Infinite scroll with pull-to-refresh.

## Best Practices

- **Cursor over offset.** The server returns `nextCursor`; `null` means the end. Offset paging on
  a mutating collection produces duplicates and gaps.
- Model a `Page<T>` domain type (`items`, `nextCursor`) so the repository returns something typed.
- Keep four distinct UI states, not two: first-page loading, loaded-with-more, loading-more, and
  **error-on-a-later-page** (which must keep the already-loaded items visible with a retry row).
- **Guard against concurrent `loadMore`.** Track an in-flight flag; a fast scroll fires the trigger
  many times, and without the guard you fetch the same page repeatedly.
- **De-duplicate on append** by id — retries and shifting data will otherwise show the same row twice.
- Pull-to-refresh resets the cursor and replaces the list, and must cancel or ignore any in-flight
  page from before the refresh.
- Use `ListView.builder` with a sentinel item for the loading/retry row rather than a
  `ScrollController` offset calculation — it works with any list height and with slivers.
- Give `itemExtent` or `prototypeItem` when rows are uniform; it removes per-frame layout cost.
- Page size is a policy: large enough to fill a screen and a bit more (commonly 20–50), tuned
  against payload size, not guessed per screen.

## Anti-Patterns

- ❌ Loading the whole collection and paginating client-side.
- ❌ Firing `loadMore()` without an in-flight guard.
- ❌ Appending without de-duplication.
- ❌ Replacing the whole list with a spinner when page 3 fails.
- ❌ Offset paging against a feed that inserts at the head.
- ❌ Building the trigger from raw `ScrollController.offset` arithmetic.
- ❌ Keeping unbounded pages in memory for an effectively infinite feed.

## Checklist

- [ ] Cursor-based where the API supports it; offset only with a stated reason.
- [ ] `loadMore` is guarded against concurrent invocation.
- [ ] Appends are de-duplicated by id.
- [ ] First-page error, later-page error, empty, and end-of-list are each handled distinctly.
- [ ] Pull-to-refresh resets the cursor and discards stale in-flight pages.
- [ ] Trigger is a sentinel item in `ListView.builder`, not offset math.
- [ ] `itemExtent`/`prototypeItem` set for uniform rows.
- [ ] Notifier has tests for: append, duplicate page, error-on-page-2, refresh-during-load.

## Dart Examples

```dart
// domain/entities/page.dart
class Page<T> {
  const Page({required this.items, this.nextCursor});

  final List<T> items;
  final String? nextCursor;

  bool get hasMore => nextCursor != null;
}
```

```dart
// presentation/articles_feed_notifier.dart
class FeedState {
  const FeedState({
    this.items = const [],
    this.cursor,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<Article> items;
  final String? cursor;
  final bool hasMore;
  final bool isLoadingMore;
  final Object? loadMoreError;

  FeedState copyWith({
    List<Article>? items,
    String? cursor,
    bool? hasMore,
    bool? isLoadingMore,
    Object? loadMoreError,
  }) =>
      FeedState(
        items: items ?? this.items,
        cursor: cursor ?? this.cursor,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadMoreError: loadMoreError,
      );
}

class FeedNotifier extends AsyncNotifier<FeedState> {
  @override
  Future<FeedState> build() async {
    final page = await ref.watch(fetchFeedProvider)(cursor: null);
    return FeedState(items: page.items, cursor: page.nextCursor, hasMore: page.hasMore);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    // The guard: a fast scroll fires this many times per second.
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true, loadMoreError: null));
    try {
      final page = await ref.read(fetchFeedProvider)(cursor: current.cursor);
      final seen = current.items.map((a) => a.id).toSet();
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...page.items.where((a) => seen.add(a.id))],
          cursor: page.nextCursor,
          hasMore: page.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      // Keep the loaded items; only the tail shows an error.
      state = AsyncData(current.copyWith(isLoadingMore: false, loadMoreError: e));
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }
}
```

```dart
// presentation/feed_list.dart — sentinel item drives the trigger
ListView.builder(
  itemCount: state.items.length + (state.hasMore ? 1 : 0),
  itemBuilder: (context, index) {
    if (index < state.items.length) return ArticleRow(article: state.items[index]);
    if (state.loadMoreError != null) {
      return RetryRow(onRetry: () => ref.read(feedProvider.notifier).loadMore());
    }
    ref.read(feedProvider.notifier).loadMore();
    return const LoadingRow();
  },
);
```

## Common Interview Questions

- Why does offset paging break on a feed that inserts at the head?
- What happens without an in-flight guard on `loadMore`, and how do you observe it?
- How should a failure on page 3 differ from a failure on page 1, in the UI?
- Why de-duplicate on append if the server is correct?
- How do you handle a refresh that lands while a `loadMore` is still in flight?

## AI Implementation Notes

- Generate the in-flight guard and the de-duplication together with `loadMore` — they are not
  optional refinements.
- Never collapse a later-page error into the screen-level error state.
- Prefer a cursor; if the API is offset-only, say so in a comment and note the duplication risk.
- `infinite_scroll_pagination` is an acceptable shortcut for the UI plumbing, but state must still
  live in a notifier the tests can drive.
- iOS counterpart: [`../ios/pagination.md`](../ios/pagination.md).
- Related: [`rest_api.md`](rest_api.md),
  [`../../performance/flutter/rendering_optimization.md`](../../performance/flutter/rendering_optimization.md).
