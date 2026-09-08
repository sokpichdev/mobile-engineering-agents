---
platform: flutter
---

# Standard: Dart Coding Standards

Baseline rules for all Dart code. Enforced by `flutter analyze` with a strict lint set
(`very_good_analysis` or `flutter_lints`) plus `dart format`. These are **law** — generated code
must conform. UI-specific rules live in [`flutter_standards.md`](flutter_standards.md).

## Naming

- Types, enums, extensions `UpperCamelCase`; members, variables, parameters `lowerCamelCase`.
- Files and directories `snake_case.dart`.
- Booleans read as assertions: `isEnabled`, `hasLoaded`, `canSubmit`.
- Methods are verb phrases (`fetchAccounts()`); no `get` prefix on accessors.
- Private members use a leading underscore; libraries expose an explicit public surface.

```dart
// ✅                                        // ❌
class AccountSummary {}                     class account_summary {}
Future<void> loadTransactions() async {}    void getTxns() {}
final bool isAuthenticated;                 final bool auth;
```

## Types & Immutability

- Prefer `final` over `var`; prefer `const` wherever the value is compile-time constant.
- Model entities as **immutable** classes with `const` constructors and `copyWith`.
- Use `sealed` classes for finite state and result unions, then `switch` on them — the compiler
  enforces exhaustiveness. Do not use loose booleans or strings for state.
- Use `abstract interface class` for contracts that must be implemented, not extended.
- Annotate public APIs with explicit types; do not rely on inference across a library boundary.

```dart
// ✅ exhaustive by construction
sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
```

## Null Safety

- **No `!` (bang) on data that can legitimately be absent.** It is a runtime crash waiting for a
  bad payload. Use `?.`, `??`, a pattern match, or an early return.
- `late` only for a value guaranteed initialized before first read, and never for something that
  might legitimately stay unset.
- Do not widen a type to nullable to silence the analyzer; fix the model.

```dart
// ✅                                        // ❌
final name = user?.name ?? 'Guest';         final name = user!.name;
if (token case final String t) use(t);      use(token!);
```

## Errors

- Cross layer boundaries with **typed failures** — a sealed `Failure` union or a `Result` — not
  raw exceptions from a package.
- Catch narrowly (`on DioException`, `on FormatException`), never a bare `catch (_) {}`.
- Every `catch` either handles, translates, or rethrows. Silently swallowing is a defect.
- `throw` only for genuinely exceptional conditions; expected failure paths return a value.
- Never include a token, password, or PII in an exception message.

```dart
// ✅                                        // ❌
} on DioException catch (e) {                } catch (_) {
  throw _mapToFailure(e);                      return [];
}                                            }
```

## Async & Concurrency

- `async`/`await` over raw `.then()` chains. Always `await` or deliberately handle a `Future` —
  an unawaited future swallows its error.
- Use `unawaited()` explicitly when fire-and-forget is intended, so the intent is visible.
- `Future` for one value, `Stream` for many. Always cancel subscriptions
  (`ref.onDispose`, `dispose()`).
- Move CPU-bound work to an isolate (`Isolate.run`/`compute`). Anything over a few milliseconds on
  the UI isolate drops frames.
- Never use `Future.delayed` as a synchronization mechanism; await the actual operation.
- Guard `BuildContext` use after an `await` with `if (!context.mounted) return;`.

## Logging & Secrets

- No `print()` in shipped code — use a logger with levels, and disable verbose logging in release.
- **Never log tokens, passwords, auth headers, or PII**, in any build mode.
- Log actionable context (operation, identifier, failure kind), not whole payloads.

## Tooling

- `dart format` is the formatting authority — no hand-formatting debates. CI runs
  `dart format --set-exit-if-changed .`.
- `flutter analyze` must be clean; an `// ignore:` needs a comment explaining why.
- Enable `prefer_const_constructors` — it is a rendering-performance rule, not a style rule
  (see [`../skills/performance/flutter/rendering_optimization.md`](../skills/performance/flutter/rendering_optimization.md)).
- Pin dependencies with a committed `pubspec.lock` for applications.

## Related

- [`flutter_standards.md`](flutter_standards.md) — widgets, state, navigation, theming, a11y.
- [`architecture_standards.md`](architecture_standards.md) — layers, SOLID, DI.
- [`security_standards.md`](security_standards.md) — OWASP MASVS baseline.
- [`testing_standards.md`](testing_standards.md) — pyramid, FIRST, coverage, doubles.
