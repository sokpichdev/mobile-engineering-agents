# Skill: Repository Pattern

## Overview

The Repository pattern abstracts data access behind a protocol so the rest of the app
depends on *what* data it needs, not *how* or *where* it's fetched. The **protocol lives in
the Domain layer**; the **implementation lives in the Data layer** and coordinates data
sources (remote API, local DB, in-memory cache). This decouples business logic from
storage/transport and enables strategies like cache-then-network and offline-first.

## Use Cases

- Any feature that reads/writes data from a backend and/or local store.
- Implementing caching or offline behavior transparently to callers.
- Swapping data sources (REST → GraphQL, or adding a cache) without touching use cases.

## Best Practices

- Define a **focused protocol** per aggregate (e.g. `AccountRepository`), not one giant repo.
- Return **domain entities**, not DTOs or `Codable` models.
- Coordinate sources **inside** the repository (e.g. return cache, refresh in background).
- Keep methods **async and throwing**; surface typed domain errors.
- Make repositories **stateless or thread-safe** (actor if it holds a cache).

## Anti-Patterns

- ❌ "God repository" with dozens of unrelated methods.
- ❌ Returning DTOs to callers.
- ❌ Leaking caching/network details into the protocol signature.
- ❌ Repository that also formats data for the UI (that's the ViewModel's job).
- ❌ Hidden shared mutable cache without synchronization.

## Checklist

- [ ] Protocol in Domain; implementation in Data.
- [ ] Returns domain entities, not DTOs.
- [ ] Methods are `async throws` with typed errors.
- [ ] Caching/source coordination hidden behind the protocol.
- [ ] Thread-safe if it holds state.

## Swift Examples

```swift
// Domain
protocol ArticleRepository {
    func latest(refresh: Bool) async throws -> [Article]
    func article(id: String) async throws -> Article
}
```

```swift
// Data — cache-then-network behind the protocol
actor CachingArticleRepository: ArticleRepository {
    private let remote: ArticleRemoteDataSource
    private let cache: ArticleCache

    init(remote: ArticleRemoteDataSource, cache: ArticleCache) {
        self.remote = remote; self.cache = cache
    }

    func latest(refresh: Bool) async throws -> [Article] {
        if !refresh, let cached = await cache.latest() { return cached }
        let fresh = try await remote.latest().map(ArticleMapper.toDomain)
        await cache.store(fresh)
        return fresh
    }

    func article(id: String) async throws -> Article {
        ArticleMapper.toDomain(try await remote.article(id: id))
    }
}
```

## Common Interview Questions

- Why put the repository protocol in the Domain layer?
- How does a repository differ from a DAO or a data source?
- How would you implement cache-then-network behind a repository?
- How do you keep a caching repository thread-safe?
- When does the Repository pattern add unnecessary indirection?

## AI Implementation Notes

- Generate one protocol per aggregate in Domain and an implementation in Data.
- Always map DTO→entity inside the implementation; never return DTOs.
- Use an `actor` when the repository owns a cache.
- Related: [`clean_architecture.md`](clean_architecture.md),
  [`../storage/caching.md`](../storage/caching.md),
  [`../../templates/repository_layer/`](../../templates/repository_layer/).
