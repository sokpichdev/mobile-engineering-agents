---
platform: flutter
---

# Skill: Dependency Injection

## Overview

In a Riverpod codebase the **provider graph is the DI container**. A provider declares how to
build a dependency; `ref.watch` resolves it; `ProviderScope(overrides: …)` swaps it. That gives
compile-checked wiring with no service locator, no runtime registration order, and a test seam on
every edge. The rule from the rest of this toolkit still holds: depend on interfaces declared in
Domain, never on concrete Data classes.

## Use Cases

- Wiring a feature's repository → use case → notifier chain at the composition root.
- Replacing a real data source with a fake in unit and widget tests.
- Environment/flavor differences (staging base URL, mock backend) resolved at app start.
- Objects that must exist before `runApp` (`SharedPreferences`, database handles) injected via a
  root override.

## Best Practices

- **Declare providers for interfaces, not implementations**: the provider's type is
  `ArticleRepository`, its body returns `ArticleRepositoryImpl`.
- Keep the **composition root at `ProviderScope`** in `main.dart`. Feature code never constructs
  its own `Dio` or database.
- For dependencies that need `await` before the app runs, create an unimplemented provider and
  override it at the root — this keeps callers synchronous.
- Use `ref.watch` for dependencies inside providers so the graph rebuilds when a dependency
  changes (e.g. the auth token changes and the client must be recreated).
- Use `ref.onDispose` to release sockets, controllers, and subscriptions.
- Keep provider declarations next to the thing they build (Data providers in `data/`, use case
  providers in `domain/`), not in one giant `providers.dart`.
- If the team wants DI decoupled from state management, `get_it` + `injectable` is the accepted
  alternative — but then **all** wiring goes through it; do not run two containers.

## Anti-Patterns

- ❌ A hand-rolled singleton (`static final instance = …`) reachable from business logic.
- ❌ Constructing `Dio()`, `Drift`, or a repository inside a widget or notifier.
- ❌ Providers typed as the concrete implementation, which defeats the test seam.
- ❌ `ref.read` of a dependency inside a provider body (it will not react to changes).
- ❌ Globals for configuration read directly by Domain code.
- ❌ Running `get_it` *and* Riverpod as parallel containers.

## Checklist

- [ ] Every dependency is reachable through a provider; no singletons in business logic.
- [ ] Providers expose Domain interfaces, not Data implementations.
- [ ] Pre-`runApp` async dependencies are injected via root `ProviderScope` overrides.
- [ ] Providers use `ref.watch` for their own dependencies.
- [ ] Disposable resources register `ref.onDispose`.
- [ ] Tests override the outermost seam (repository or data source), not internals.

## Dart Examples

```dart
// data/providers.dart
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(baseUrl: ref.watch(configProvider).apiBaseUrl))
    ..interceptors.add(ref.watch(authInterceptorProvider));
  ref.onDispose(dio.close);
  return dio;
});

// The provider's TYPE is the Domain interface — that is the seam.
final articleRepositoryProvider = Provider<ArticleRepository>(
  (ref) => ArticleRepositoryImpl(ArticleRemoteDataSource(ref.watch(dioProvider))),
);

// domain/providers.dart
final getArticlesProvider = Provider<GetArticles>(
  (ref) => GetArticles(ref.watch(articleRepositoryProvider)),
);
```

```dart
// main.dart — the composition root, and the only place async setup happens
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const App(),
    ),
  );
}

// core/providers.dart
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('overridden in main()'),
);
```

```dart
// test — override the seam, no mocking framework required
test('loads articles from the repository', () async {
  final container = ProviderContainer(
    overrides: [
      articleRepositoryProvider.overrideWithValue(FakeArticleRepository(articles: [article])),
    ],
  );
  addTearDown(container.dispose);

  final articles = await container.read(articlesProvider.future);

  expect(articles, hasLength(1));
});
```

## Common Interview Questions

- Why type a provider as the interface rather than the implementation?
- How do you inject something that requires `await` before `runApp`?
- `ref.watch` vs `ref.read` inside a provider body — what breaks if you get it wrong?
- How does `ProviderScope(overrides:)` compare with a service locator for testability?
- When would you still reach for `get_it`?

## AI Implementation Notes

- When adding a data source, generate its provider in the same commit and type it as the Domain
  interface.
- Never generate a singleton or a top-level mutable global for a dependency.
- In generated tests, override at the repository boundary and use a hand-written fake before
  reaching for `mocktail`.
- iOS counterpart: [`../ios/dependency_injection.md`](../ios/dependency_injection.md).
- Related: [`clean_architecture.md`](clean_architecture.md),
  [`state_management.md`](state_management.md).
