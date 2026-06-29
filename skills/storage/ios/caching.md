---
platform: ios
---

# Skill: Caching

## Overview

Caching stores results so they can be reused, cutting latency, bandwidth, and battery use.
The hard part isn't storing — it's **invalidation**: knowing when cached data is stale.
Mobile caching spans in-memory (`NSCache`), on-disk (files/DB), and HTTP (`URLCache`).
Pick a policy per use case (cache-first, network-first, stale-while-revalidate) and always
define **bounds** (size/count) and a **staleness/TTL** rule.

## Use Cases

- Avoiding refetching unchanged API data.
- Image/thumbnail caching for smooth scrolling.
- Serving instant content while refreshing in the background.

## Best Practices

- Choose a policy explicitly: **cache-first**, **network-first**, or **stale-while-revalidate**.
- **Bound every cache** (`NSCache.countLimit`/`totalCostLimit`; disk size cap with eviction).
- Attach a **TTL or validator** (ETag/Last-Modified) so staleness is decidable.
- Use the **two-tier** pattern: fast in-memory over slower on-disk.
- Leverage **`URLCache`/HTTP caching** when the server sends cache headers.
- **Invalidate on writes** that affect cached data.

## Anti-Patterns

- ❌ Unbounded in-memory caches → memory termination.
- ❌ No TTL/validator → serving stale data indefinitely.
- ❌ Caching personalized/sensitive data without scoping/encryption.
- ❌ Ignoring server cache headers and refetching everything.
- ❌ Not invalidating after a mutation.

## Checklist

- [ ] Explicit caching policy per use case.
- [ ] Every cache bounded with eviction.
- [ ] TTL or validator (ETag/Last-Modified) defined.
- [ ] Two-tier (memory + disk) where appropriate.
- [ ] Invalidation on relevant writes; sensitive data scoped/encrypted.

## Swift Examples

```swift
// Bounded in-memory cache with TTL
final class MemoryCache<Key: Hashable, Value> {
    private struct Entry { let value: Value; let expiry: Date }
    private let cache = NSCache<WrappedKey, Box>()
    private let ttl: TimeInterval

    init(ttl: TimeInterval, countLimit: Int = 200) {
        self.ttl = ttl
        cache.countLimit = countLimit                       // bounded
    }

    func value(for key: Key) -> Value? {
        guard let box = cache.object(forKey: WrappedKey(key)) else { return nil }
        guard box.entry.expiry > Date() else {              // TTL check
            cache.removeObject(forKey: WrappedKey(key)); return nil
        }
        return box.entry.value
    }

    func insert(_ value: Value, for key: Key) {
        let entry = Entry(value: value, expiry: Date().addingTimeInterval(ttl))
        cache.setObject(Box(entry), forKey: WrappedKey(key))
    }
    final class WrappedKey: NSObject { let key: Key; init(_ k: Key) { key = k }
        override var hash: Int { key.hashValue }
        override func isEqual(_ o: Any?) -> Bool { (o as? WrappedKey)?.key == key } }
    final class Box { let entry: Entry; init(_ e: Entry) { entry = e } }
}
```

```swift
// Stale-while-revalidate in a repository
func articles() async throws -> [Article] {
    if let cached = cache.value(for: "articles") {
        Task { try? await refreshArticlesInBackground() }   // serve stale, revalidate
        return cached
    }
    return try await refreshArticlesInBackground()
}
```

## Common Interview Questions

- What are the common caching policies and when to use each?
- Why is cache invalidation hard? How do TTL/ETag help?
- `NSCache` vs a `Dictionary` — why `NSCache`?
- How does `URLCache`/HTTP caching work?
- How do you cache images efficiently for scrolling?

## AI Implementation Notes

- Always bound caches and attach a TTL/validator; never an unbounded dictionary cache.
- Default to stale-while-revalidate for read-heavy feeds; invalidate on writes.
- Don't cache sensitive data without scoping/encryption.
- Related: [`offline_sync.md`](offline_sync.md),
  [`../../performance/ios/memory_optimization.md`](../../performance/ios/memory_optimization.md).
