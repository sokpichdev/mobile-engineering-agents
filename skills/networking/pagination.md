# Skill: Pagination

## Overview

Pagination loads large collections in pages instead of all at once. The two common models
are **offset/limit** (page numbers) and **cursor-based** (opaque token to the next page).
Cursor pagination is preferred for feeds and frequently-changing data because it avoids
duplicates/skips when items shift. A correct client manages page state, prevents duplicate
in-flight loads, merges/de-duplicates results, and handles first/last/empty pages.

## Use Cases

- Infinite-scroll feeds, search results, transaction history.
- Any list too large to fetch in one request.

## Best Practices

- Prefer **cursor-based** pagination for live/ordered data; offset for stable, indexable data.
- Track explicit paging state: `items`, `nextCursor`/`page`, `isLoading`, `hasMore`.
- **Guard against concurrent loads** — ignore a new request while one is in flight.
- **De-duplicate** merged items by id (servers can repeat across pages).
- Trigger the next page from a **prefetch threshold**, not only at the very bottom.

## Anti-Patterns

- ❌ Firing multiple "load next" requests simultaneously (duplicates, race conditions).
- ❌ Offset pagination on a feed that inserts items at the top (skips/dupes).
- ❌ Assuming a stable total count.
- ❌ No `hasMore` flag → infinite empty requests at the end.
- ❌ Merging without de-duplicating by id.

## Checklist

- [ ] Paging state tracked explicitly (items, cursor/page, isLoading, hasMore).
- [ ] Concurrent next-page loads prevented.
- [ ] Results de-duplicated by id.
- [ ] First/last/empty pages handled.
- [ ] Prefetch threshold triggers loading before the bottom.

## Swift Examples

```swift
struct Page<T> { let items: [T]; let nextCursor: String? }

@MainActor @Observable
final class FeedViewModel {
    private(set) var items: [Post] = []
    private(set) var isLoading = false
    private var nextCursor: String?
    private var hasMore = true
    private let repo: FeedRepository

    init(repo: FeedRepository) { self.repo = repo }

    func loadNextPageIfNeeded(currentItem: Post) async {
        guard let threshold = items.dropLast(5).last,
              currentItem.id == threshold.id else { return }       // prefetch threshold
        await loadNextPage()
    }

    func loadNextPage() async {
        guard !isLoading, hasMore else { return }                  // guard concurrent loads
        isLoading = true; defer { isLoading = false }
        do {
            let page = try await repo.feed(after: nextCursor)
            let existing = Set(items.map(\.id))
            items += page.items.filter { !existing.contains($0.id) } // de-dup
            nextCursor = page.nextCursor
            hasMore = page.nextCursor != nil
        } catch { /* surface a retryable error to the UI */ }
    }
}
```

## Common Interview Questions

- Offset vs cursor pagination — pros/cons?
- Why can offset pagination duplicate or skip items in a live feed?
- How do you prevent duplicate in-flight page loads?
- How do you de-duplicate merged pages?
- How do you decide when to prefetch the next page?

## AI Implementation Notes

- Default to cursor pagination; track `isLoading`/`hasMore` and guard re-entry.
- Always de-dup by id when merging pages.
- Trigger prefetch a few items before the end for smooth scrolling.
- Related: [`rest_api.md`](rest_api.md), [`graphql.md`](graphql.md),
  [`../architecture/repository_pattern.md`](../architecture/repository_pattern.md).
