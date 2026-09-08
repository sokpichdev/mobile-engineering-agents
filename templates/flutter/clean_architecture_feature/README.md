# Template: Clean Architecture Feature

The canonical end-to-end Flutter feature: all three layers, the Riverpod DI graph, typed error
handling, and tests. This bundle ships representative `.dart` files you can copy and rename. See
[`architecture/clean_architecture.md`](../../../architecture/clean_architecture.md) and
[`skills/architecture/flutter/clean_architecture.md`](../../../skills/architecture/flutter/clean_architecture.md).

## Folder Structure

```text
clean_architecture_feature/
├── domain.dart          // entity + Failure union + repository interface + use cases
├── data.dart            // DTO + mapper + remote data source + repository impl
├── presentation.dart    // AsyncNotifier + ConsumerWidget with every state handled
├── providers.dart       // composition root — the DI graph
└── feature_test.dart    // mapper + use case + notifier + widget tests
```

> The files use a sample `Article` feature. Replace `Article`/`article` with your entity, and split
> each file into one-type-per-file when you copy it into a real module. They are illustrative —
> they are not part of a compiled package, so cross-file symbols won't resolve in isolation.

## How the layers connect

```text
ArticlesScreen → ArticlesNotifier → GetArticles → ArticleRepository (interface)
                                                          ▲
                            ArticleRepositoryImpl (Data) ── ArticleRemoteDataSource ── Dio
```

## Conventions Demonstrated

- **Domain is framework-free** — `domain.dart` imports nothing. The entity, the `Failure` union,
  the repository interface, and the use cases all live there.
- **Data owns the wire format** — `ArticleDto` and its `toEntity()` mapper never leave `data.dart`,
  and every `DioException` is translated into a `Failure` before it crosses the boundary.
- **Presentation is a function of state** — the widget renders loading / loaded / empty / error and
  nothing else; `_messageFor` maps typed failures to user-facing copy.
- **Providers are typed as Domain interfaces** (`Provider<ArticleRepository>`), which is what makes
  every edge overridable in a test.
- **Tests override the repository seam** with a hand-written fake, so the real notifier and use case
  logic actually runs. `addTearDown(container.dispose)` prevents state leaking between tests.
- **Keys on everything a test drives** (`articles.loading`, `articles.empty`, `articles.error`,
  `articles.retry`) so finders are stable.

## Usage

1. Copy the bundle into your feature module (`lib/features/<name>/`).
2. Rename `Article`/`article` → your entity, and split into per-type files.
3. Point `dioProvider`'s `baseUrl` at your configuration provider rather than a literal.
4. Register the screen in the `go_router` route table
   ([`skills/architecture/flutter/router_navigation.md`](../../../skills/architecture/flutter/router_navigation.md)).
5. Run `flutter analyze` and `flutter test`.

## Related

- Skill: [`skills/architecture/flutter/clean_architecture.md`](../../../skills/architecture/flutter/clean_architecture.md)
- Skill: [`skills/architecture/flutter/repository_pattern.md`](../../../skills/architecture/flutter/repository_pattern.md)
- Standard: [`standards/flutter_standards.md`](../../../standards/flutter_standards.md)
- Template: [`templates/flutter/networking_layer/`](../networking_layer/)
