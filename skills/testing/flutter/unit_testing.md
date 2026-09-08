---
platform: flutter
---

# Skill: Unit Testing

## Overview

Unit tests verify one component in isolation — a use case, notifier, mapper, or repository — with
its dependencies replaced by test doubles. They are the **base of the test pyramid**: fast,
deterministic, and numerous. In Flutter, prefer **`mocktail`** (null-safe, no code generation) and
hand-written fakes over `mockito`. Riverpod's `ProviderContainer` with `overrides` is the standard
seam for testing a notifier without pumping a widget. The prerequisite is testable design:
constructor injection and an injected `Clock`/id generator.

## Use Cases

- Business logic (use cases), presentation logic (notifiers), DTO ⇄ entity mappers.
- Edge-case and error-path verification.
- Regression tests accompanying bug fixes.
- Repository policy: caching, retry, and error mapping.

## Best Practices

- Follow **AAA** (Arrange, Act, Assert); keep one behavior per test.
- **Inject** dependencies (repositories, `Clock`, id generator) so tests are deterministic.
- Name tests by behavior: `method_condition_expectedResult`.
- Cover **errors, empties, and boundaries** first, not just the happy path.
- Prefer **fakes** implementing the Domain interface over mocks; reserve `mocktail` for verifying
  that an interaction happened.
- Test a notifier through a `ProviderContainer` with `overrides`, and always
  `addTearDown(container.dispose)` — a leaked container keeps providers alive across tests.
- Use `container.listen` to capture the sequence of emitted states, not just the final one; a bug
  that skips the loading state is invisible if you only assert the end value.
- Use `package:clock` (`withClock`) and `FakeAsync` for time, timers, and debounce — never
  `DateTime.now()` or a real `Future.delayed`.
- Register fallback values for `mocktail` `any()` matchers on custom types (`registerFallbackValue`).

## Anti-Patterns

- ❌ Hitting the real network, database, or clock (flaky, slow).
- ❌ Asserting on private implementation details.
- ❌ One giant test asserting many unrelated things.
- ❌ Non-deterministic data (`DateTime.now()`, random ids) in assertions.
- ❌ Only happy-path coverage.
- ❌ Forgetting `addTearDown(container.dispose)`, so state leaks between tests.
- ❌ Real `Future.delayed` for waits instead of `FakeAsync`.
- ❌ Mocking a type you own when a five-line fake would be clearer.

## Checklist

- [ ] Logic covered with isolated, deterministic tests.
- [ ] Dependencies injected and faked.
- [ ] Error/empty/boundary cases tested.
- [ ] Behavior-focused names; one focus per test.
- [ ] No real network, database, clock, or randomness.
- [ ] `ProviderContainer` disposed via `addTearDown`.
- [ ] Emitted state sequence asserted, not only the final value.
- [ ] Time-dependent behavior driven by `FakeAsync`/`withClock`.

## Dart Examples

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class FakeArticleRepository implements ArticleRepository {
  FakeArticleRepository({this.articles = const [], this.error});

  final List<Article> articles;
  final Object? error;

  @override
  Future<List<Article>> fetchArticles({required int page}) async {
    if (error != null) throw error!;
    return articles;
  }
}

void main() {
  ProviderContainer makeContainer(ArticleRepository repository) {
    final container = ProviderContainer(
      overrides: [articleRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose); // without this, providers leak across tests
    return container;
  }

  test('build with articles emits them', () async {
    final container = makeContainer(FakeArticleRepository(articles: [testArticle]));

    final articles = await container.read(articlesProvider.future);

    expect(articles, [testArticle]);
  });

  test('refresh with a failing repository emits an error state', () async {
    final container = makeContainer(FakeArticleRepository(error: const NetworkFailure()));

    await expectLater(
      container.read(articlesProvider.future),
      throwsA(isA<NetworkFailure>()),
    );
    expect(container.read(articlesProvider), isA<AsyncError<List<Article>>>());
  });

  test('refresh emits loading before data', () async {
    final container = makeContainer(FakeArticleRepository(articles: [testArticle]));
    await container.read(articlesProvider.future);

    final emitted = <AsyncValue<List<Article>>>[];
    container.listen(articlesProvider, (_, next) => emitted.add(next), fireImmediately: false);

    await container.read(articlesProvider.notifier).refresh();

    // Asserting only the final value would hide a skipped loading state.
    expect(emitted.map((v) => v.runtimeType), [
      isA<AsyncLoading<List<Article>>>().runtimeType,
      isA<AsyncData<List<Article>>>().runtimeType,
    ]);
  });
}
```

```dart
// Deterministic time — never DateTime.now() in the code under test.
test('token is refreshed once expired', () {
  withClock(Clock.fixed(DateTime.utc(2026, 1, 1)), () {
    final session = Session(expiresAt: DateTime.utc(2025, 12, 31));
    expect(session.isExpired, isTrue);
  });
});
```

```dart
// mocktail — reach for it to verify an interaction, not to stand in for a simple fake
class MockAnalytics extends Mock implements Analytics {}

test('sign-in success is reported once', () async {
  final analytics = MockAnalytics();
  when(() => analytics.log(any())).thenAnswer((_) async {});

  await SignIn(analytics: analytics, auth: FakeAuth()).call('a@b.com', 'pw');

  verify(() => analytics.log('sign_in_success')).called(1);
});
```

## Common Interview Questions

- Why prefer a fake implementing the interface over a mock?
- What does `addTearDown(container.dispose)` prevent?
- Why assert the sequence of emitted states rather than the final value?
- How do you make a debounce or timeout deterministic in a test?
- What makes a piece of code untestable, and what change fixes it?
- When is `mocktail` the right tool rather than a hand-written fake?

## AI Implementation Notes

- Generate a test alongside every notifier and use case, covering success and at least one failure.
- Default to a hand-written fake; use `mocktail` only to verify interactions.
- Always `addTearDown(container.dispose)` in generated notifier tests.
- Never generate `DateTime.now()` in code under test — inject a `Clock`.
- iOS counterpart: [`../ios/unit_testing.md`](../ios/unit_testing.md).
  Android counterpart: [`../android/unit_testing.md`](../android/unit_testing.md).
- Related: [`widget_testing.md`](widget_testing.md),
  [`../../../standards/testing_standards.md`](../../../standards/testing_standards.md).
