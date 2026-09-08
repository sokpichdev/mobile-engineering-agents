---
platform: flutter
---

# Skill: Clean Architecture

## Overview

Clean Architecture splits a Flutter app into three layers with a one-way dependency rule:
**Presentation → Domain ← Data**. Domain is plain Dart — it must not `import 'package:flutter/…'`
and must not know about Dio, Drift, or Riverpod. Data implements the interfaces Domain declares.
Presentation renders state produced by a `Notifier` that calls use cases. The payoff is that
business rules are testable with `dart test` alone (no widget pump, no device) and the data
source can be swapped without touching a widget.

## Use Cases

- New feature packages where business rules outlive the current backend or UI.
- Codebases where widgets call `http`/`Dio` directly and logic is impossible to test.
- Apps with several data sources per concept (remote, cache, platform channel).
- Multi-package (melos) repos that need enforceable module boundaries.

## Best Practices

- Organize **package by feature, layer inside it** — `lib/features/articles/{domain,data,presentation}/`.
  Shared plumbing lives in `lib/core/`.
- Keep Domain free of every framework import. A quick grep for `package:flutter` under `domain/`
  is a cheap architecture test; encode it as a lint or a CI grep.
- Model entities as immutable classes (`final` fields, `const` constructors, `copyWith`).
- Express a use case as a small callable class (`class GetArticles { Future<…> call(…) }`) so it
  reads like a function at the call site and still injects like an object.
- Declare repository **interfaces in Domain**, implement them in Data. Domain never sees a DTO.
- Return typed failures (a sealed `Failure` union or `Result<T, Failure>`), not raw exceptions,
  across the Data → Domain boundary.
- Wire everything at the composition root (`ProviderScope` overrides) — see
  [`dependency_injection.md`](dependency_injection.md).

## Anti-Patterns

- ❌ `import 'package:flutter/material.dart'` anywhere under `domain/`.
- ❌ Widgets calling a repository or `Dio` directly from `build()` or `initState()`.
- ❌ DTOs (`fromJson`/`toJson` classes) leaking into Domain or Presentation.
- ❌ A `models/` folder shared by all layers — it couples the API shape to the UI.
- ❌ Anemic use cases that only forward one call *and* add no rule — inline those instead of
  generating ceremony.
- ❌ Organizing top-level folders by layer (`lib/models/`, `lib/screens/`), which scatters every
  feature across the tree.

## Checklist

- [ ] Domain has zero Flutter/package imports; entities are immutable.
- [ ] Repository interfaces live in Domain; implementations live in Data.
- [ ] DTO ⇄ entity mapping happens in Data and nowhere else.
- [ ] Presentation talks to use cases, never to a data source.
- [ ] Failures are typed and exhaustively handled at the Presentation boundary.
- [ ] Dependencies are injected at the composition root, not constructed inline.
- [ ] Domain and use cases have unit tests that need no `WidgetTester`.

## Dart Examples

```dart
// domain/entities/article.dart — pure Dart, no Flutter imports
class Article {
  const Article({required this.id, required this.title, required this.publishedAt});

  final String id;
  final String title;
  final DateTime publishedAt;
}

// domain/repositories/article_repository.dart — the interface Domain owns
abstract interface class ArticleRepository {
  Future<List<Article>> fetchArticles({required int page});
}

// domain/usecases/get_articles.dart
class GetArticles {
  const GetArticles(this._repository);

  final ArticleRepository _repository;

  Future<List<Article>> call({int page = 1}) => _repository.fetchArticles(page: page);
}
```

```dart
// data/models/article_dto.dart — the wire shape stays in Data
class ArticleDto {
  const ArticleDto({required this.id, required this.title, required this.publishedAt});

  factory ArticleDto.fromJson(Map<String, dynamic> json) => ArticleDto(
        id: json['id'] as String,
        title: json['title'] as String,
        publishedAt: json['published_at'] as String,
      );

  final String id;
  final String title;
  final String publishedAt;

  Article toEntity() => Article(
        id: id,
        title: title,
        publishedAt: DateTime.parse(publishedAt),
      );
}

// data/repositories/article_repository_impl.dart
class ArticleRepositoryImpl implements ArticleRepository {
  const ArticleRepositoryImpl(this._remote);

  final ArticleRemoteDataSource _remote;

  @override
  Future<List<Article>> fetchArticles({required int page}) async {
    final dtos = await _remote.getArticles(page: page);
    return dtos.map((dto) => dto.toEntity()).toList(growable: false);
  }
}
```

## Common Interview Questions

- Why must Domain not import Flutter? (Testability, portability, and it stops UI concerns from
  driving business rules.)
- Where do DTO → entity mappers belong, and why not in Domain?
- When is a use case class worth the ceremony over calling the repository directly?
- How do you enforce the dependency rule in a Dart codebase? (Package boundaries in melos,
  `import` lint rules, or a CI grep over `domain/`.)
- How does this layering change what you can unit-test without a device?

## AI Implementation Notes

- Generate the three layers together: entity + repository interface + use case, then DTO +
  mapper + repository impl, then notifier + widget.
- Never let a generated widget import from `data/`. If it needs data, add a use case.
- Default to `abstract interface class` for repository contracts (Dart 3) so they cannot be
  extended accidentally.
- Pair every use case with a unit test using a fake repository — no mocks needed.
- iOS counterpart: [`../ios/clean_architecture.md`](../ios/clean_architecture.md).
- Related: [`state_management.md`](state_management.md),
  [`repository_pattern.md`](repository_pattern.md),
  [`../../../standards/flutter_standards.md`](../../../standards/flutter_standards.md).
