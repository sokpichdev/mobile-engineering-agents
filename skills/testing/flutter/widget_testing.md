---
platform: flutter
---

# Skill: Widget Testing

## Overview

Widget tests render a widget in a headless test environment and drive it with a `WidgetTester` —
faster than an integration test, and far more thorough than a unit test for anything involving
layout, gestures, and state-to-UI binding. The standard harness is `pumpWidget` wrapped in a
`ProviderScope` whose repositories are overridden with fakes, so every screen state can be produced
on demand. The contract this toolkit enforces: **every screen test asserts loading, loaded, empty,
and error** — the direct analogue of the iOS state-enum review rule.

## Use Cases

- Verifying a screen renders each of its states correctly.
- Gesture and form behavior: taps, scrolls, text entry, validation messages.
- Regression tests for layout bugs (overflow, missing empty state).
- Accessibility assertions: tap-target size, contrast, semantic labels.
- Golden (snapshot) tests for stable, design-critical components.

## Best Practices

- Build one **harness helper** (`pumpScreen`) that wraps the widget in `ProviderScope` with
  overrides, `MaterialApp`, and any localization delegates. Repeating that setup per test is where
  widget suites rot.
- Override at the **repository** boundary so the real notifier logic is under test.
- `await tester.pump()` advances one frame; `pumpAndSettle()` waits for all animations. **Never
  `pumpAndSettle` a screen with an indeterminate `CircularProgressIndicator` or a repeating
  animation — it will time out.** Use `pump(Duration(...))` there.
- Find by **semantics or key**, not by widget type: `find.byKey(const Key('submit'))` or
  `find.bySemanticsLabel('Submit')`. `find.byType(ElevatedButton)` breaks the moment a second
  button appears.
- Put a `ValueKey` on anything a test targets, and treat it as part of the widget's contract.
- Assert accessibility cheaply with the built-in guidelines — `meetsGuideline(textContrastGuideline)`,
  `androidTapTargetGuideline`, `labeledTapTargetGuideline`. This automates most of
  [`../../../checklists/accessibility_review.md`](../../../checklists/accessibility_review.md).
- Set an explicit surface size (`tester.view.physicalSize`) when testing responsive layout, and
  reset it with `addTearDown`.
- Golden tests: load fonts explicitly, keep goldens for a small set of stable components, and expect
  to regenerate on a renderer change. Do not golden every screen.
- `integration_test` covers real end-to-end flows on a device; `patrol` adds native dialogs,
  permissions, and WebViews. Keep those few and slow-lane them in CI.

## Anti-Patterns

- ❌ `pumpAndSettle()` on a screen with a persistent progress indicator.
- ❌ `find.byType(...)` for anything that could appear more than once.
- ❌ Real repositories or network calls in a widget test.
- ❌ Testing only the loaded state, so the empty and error branches rot unnoticed.
- ❌ Duplicating `ProviderScope` setup in every test instead of a shared harness.
- ❌ `expect(find.text('...'), findsOneWidget)` as the entire assertion for a complex screen.
- ❌ Goldens for every screen — they become a change-detector suite nobody trusts.
- ❌ Forgetting to reset an overridden surface size, leaking it into later tests.

## Checklist

- [ ] A shared harness wraps `ProviderScope` overrides + `MaterialApp`.
- [ ] Loading, loaded, empty, and error states are each asserted.
- [ ] Finders use keys or semantics, not widget types.
- [ ] No `pumpAndSettle` where an indeterminate animation runs.
- [ ] Fakes are injected at the repository boundary; no real I/O.
- [ ] Accessibility guidelines asserted for at least the primary screen.
- [ ] Surface-size overrides reset in `addTearDown`.
- [ ] Goldens limited to stable components, with fonts loaded.

## Dart Examples

```dart
// test/support/harness.dart — write this once
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  List<Override> overrides = const [],
}) =>
    tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(home: screen),
      ),
    );
```

```dart
void main() {
  testWidgets('shows a spinner while loading', (tester) async {
    await pumpScreen(
      tester,
      const ArticlesScreen(),
      overrides: [
        articleRepositoryProvider.overrideWithValue(
          FakeArticleRepository(delay: const Duration(seconds: 1)),
        ),
      ],
    );

    await tester.pump(); // one frame — NOT pumpAndSettle, the spinner never settles
    expect(find.byKey(const Key('articles.loading')), findsOneWidget);
  });

  testWidgets('shows the empty state when there are no articles', (tester) async {
    await pumpScreen(
      tester,
      const ArticlesScreen(),
      overrides: [
        articleRepositoryProvider.overrideWithValue(FakeArticleRepository(articles: const [])),
      ],
    );
    await tester.pump();

    expect(find.byKey(const Key('articles.empty')), findsOneWidget);
  });

  testWidgets('shows an error with a working retry', (tester) async {
    final repository = FakeArticleRepository(error: const NetworkFailure());
    await pumpScreen(
      tester,
      const ArticlesScreen(),
      overrides: [articleRepositoryProvider.overrideWithValue(repository)],
    );
    await tester.pump();

    expect(find.byKey(const Key('articles.error')), findsOneWidget);

    repository.error = null;
    repository.articles = [testArticle];
    await tester.tap(find.byKey(const Key('articles.retry')));
    await tester.pump();
    await tester.pump();

    expect(find.text(testArticle.title), findsOneWidget);
  });

  testWidgets('meets accessibility guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(
      tester,
      const ArticlesScreen(),
      overrides: [
        articleRepositoryProvider.overrideWithValue(
          FakeArticleRepository(articles: [testArticle]),
        ),
      ],
    );
    await tester.pump();

    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
```

```dart
// ❌ brittle and ambiguous                     ✅ stable contract
find.byType(ElevatedButton)                   // find.byKey(const Key('articles.retry'))
```

## Common Interview Questions

- When does `pumpAndSettle` hang, and what do you use instead?
- Why find by key or semantics rather than by widget type?
- Where should fakes be injected for a screen test, and why not at the notifier?
- What do widget tests cover that unit tests cannot, and vice versa?
- When is a golden test worth its maintenance cost?
- How would you assert a screen is accessible without a manual pass?

## AI Implementation Notes

- Generate the shared harness once per test suite, then reuse it.
- Every generated screen test covers loading, loaded, empty, and error — do not stop at loaded.
- Add a `ValueKey` to any widget the test targets, in the same change as the test.
- Never use `pumpAndSettle` where an indeterminate progress indicator is on screen.
- Prefer the built-in accessibility guideline matchers over hand-rolled assertions.
- Verify the current API of any E2E helper before generating samples — `patrol` in particular has
  had significant version-to-version churn.
- iOS counterpart: [`../ios/ui_testing.md`](../ios/ui_testing.md).
- Related: [`unit_testing.md`](unit_testing.md),
  [`../../../checklists/accessibility_review.md`](../../../checklists/accessibility_review.md).
