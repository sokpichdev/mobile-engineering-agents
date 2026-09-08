---
platform: flutter
---

# Skill: Repository Pattern

## Overview

A repository is the Domain-owned interface that hides *where* data comes from. Domain declares
`abstract interface class ArticleRepository`; Data implements it over one or more data sources
(remote HTTP, local database, platform channel) and maps DTOs to entities. Callers get entities
and typed failures and never learn that a `DioException` or a Drift row existed.

## Use Cases

- Any feature reading from a backend, with or without a cache.
- Offline-first reads where the cache is authoritative and the network refreshes it.
- Swapping a stub for a real backend while an API contract is still being agreed.
- Consolidating retry/caching policy in one place instead of per-call-site.

## Best Practices

- **Interface in Domain, implementation in Data.** The interface speaks entities only.
- Split the implementation into **data sources**: `ArticleRemoteDataSource` (Dio) and
  `ArticleLocalDataSource` (Drift/sqflite). The repository composes them and owns the policy.
- **Map at the edge.** `Dto.toEntity()` lives in Data; no DTO type ever crosses into Domain.
- **Translate errors.** Catch `DioException`/`DatabaseException` in Data and return a sealed
  `Failure` (or throw a Domain-level exception) so Presentation switches on meaningful cases.
- For offline-first reads, return a `Stream<List<Article>>` from the local store and trigger a
  background refresh — the UI then updates once, from one source of truth.
- Keep the interface **narrow and task-shaped** (`fetchArticles({required int page})`), not a
  generic CRUD surface mirroring the database.
- Repositories are stateless apart from injected data sources; caching policy is explicit.

## Anti-Patterns

- ❌ Returning `Response`, `Map<String, dynamic>`, or a DTO from a repository method.
- ❌ Letting `DioException` propagate to a notifier or widget.
- ❌ A "repository" that is a thin `Dio` wrapper with no mapping and no policy.
- ❌ Business rules (pricing, eligibility) inside the repository — those belong in use cases.
- ❌ One `AppRepository` for the whole app.
- ❌ Caching decisions scattered across call sites instead of owned by the repository.

## Checklist

- [ ] Interface lives in Domain and mentions only entities and Domain failures.
- [ ] Remote and local access are separate data sources behind the repository.
- [ ] DTO ⇄ entity mapping is in Data, with tests for the mapper.
- [ ] Transport/database errors are caught and translated to typed failures.
- [ ] Method names describe the task, not the HTTP verb or table.
- [ ] A fake implementation of the interface exists for tests.

## Dart Examples

```dart
// domain/repositories/article_repository.dart
sealed class Failure {
  const Failure();
}

final class NetworkFailure extends Failure {
  const NetworkFailure();
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure();
}

final class UnknownFailure extends Failure {
  const UnknownFailure(this.cause);
  final Object cause;
}

abstract interface class ArticleRepository {
  /// Emits the cached articles, then any refreshed set.
  Stream<List<Article>> watchArticles();

  Future<void> refreshArticles({required int page});
}
```

```dart
// data/repositories/article_repository_impl.dart
class ArticleRepositoryImpl implements ArticleRepository {
  const ArticleRepositoryImpl({required this.remote, required this.local});

  final ArticleRemoteDataSource remote;
  final ArticleLocalDataSource local;

  @override
  Stream<List<Article>> watchArticles() =>
      local.watchArticles().map((rows) => rows.map((r) => r.toEntity()).toList());

  @override
  Future<void> refreshArticles({required int page}) async {
    try {
      final dtos = await remote.getArticles(page: page);
      await local.upsertAll(dtos.map(ArticleRow.fromDto).toList());
    } on DioException catch (e) {
      throw switch (e.response?.statusCode) {
        401 => const UnauthorizedFailure(),
        null => const NetworkFailure(),
        _ => UnknownFailure(e),
      };
    }
  }
}
```

```dart
// ❌ leaks transport                          ✅ speaks Domain
Future<Response> getArticles();              // Future<List<Article>> fetchArticles({int page});
```

## Common Interview Questions

- What does the repository hide from its callers, and why does that matter for testing?
- Where do DTO mappers belong, and what breaks if they live in Domain?
- Why translate `DioException` at the Data boundary instead of in the widget?
- How do repository, data source, and use case differ in responsibility?
- How would you add an offline cache without changing a single caller?

## AI Implementation Notes

- Generate the interface, the impl, the data source(s), and the mapper together — never an impl
  without an interface.
- Always translate transport errors into a sealed `Failure`; never let `DioException` escape Data.
- Prefer returning `Stream` from read methods when a local cache exists, so the UI has one source
  of truth.
- Generate a hand-written `FakeArticleRepository` alongside for tests.
- iOS counterpart: [`../ios/repository_pattern.md`](../ios/repository_pattern.md).
- Related: [`clean_architecture.md`](clean_architecture.md),
  [`../../networking/flutter/rest_api.md`](../../networking/flutter/rest_api.md),
  [`../../storage/flutter/offline_sync.md`](../../storage/flutter/offline_sync.md).
