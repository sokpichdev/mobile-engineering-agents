# Template: Clean Architecture Feature

The canonical end-to-end feature: all three layers, DI, error handling, and tests. This bundle
ships representative `.swift` files you can copy and rename. See
[`architecture/clean_architecture.md`](../../../architecture/clean_architecture.md).

## Folder Structure

```text
clean_architecture_feature/
├── Domain.swift          // entity + repository protocol + use case + DomainError
├── Data.swift            // DTO + mapper + repository implementation
├── Presentation.swift    // ViewState + ViewModel + View
├── CompositionRoot.swift // wires the graph (prod + preview/test)
└── Tests.swift           // use case + ViewModel + mapper tests
```

> The files use a sample `Article` feature. Replace `Article`/`article` with your entity, and
> split each file into per-type files when you copy it into a real module.

## How the layers connect

```text
ArticlesView → ArticlesViewModel → FetchArticlesUseCase → ArticleRepository (protocol)
                                                              ▲
                                          RemoteArticleRepository (Data) ── APIClient
```

## Conventions Demonstrated

- **Domain** is framework-free; repository protocol + use case live here.
- **Data** maps `ArticleDTO` → `Article` and `NetworkError` → `DomainError`; DTOs never leak.
- **Presentation** uses a single `ViewState` enum and an `@Observable @MainActor` ViewModel.
- **DI** through a composition root with a `#if DEBUG` preview/test factory.
- **Tests** are deterministic with simple stubs (no real network).

## Usage

1. Copy the bundle into your feature module.
2. Rename `Article`/`article` → your entity.
3. Split combined files into one-type-per-file.
4. Point `RemoteArticleRepository` at your endpoint.
5. Run the tests; extend coverage for your business rules.

See also: [feature_module](../feature_module/), [repository_layer](../repository_layer/),
[swiftui_screen](../swiftui_screen/), [unit_test_template](../unit_test_template/).
