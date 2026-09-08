---
platform: flutter
---

# Checklist: Flutter Review

Review gate for Flutter/Dart screens and features. Tag findings Critical/High/Medium/Low/Nit; block
on Critical/High. Complements [`../standards/flutter_standards.md`](../standards/flutter_standards.md)
and [`../standards/dart_coding_standards.md`](../standards/dart_coding_standards.md).

## Layering

- [ ] Nothing under `domain/` imports `package:flutter`, `dio`, `drift`, or `flutter/services.dart`.
- [ ] Repository interfaces live in Domain; implementations and DTOs live in Data.
- [ ] DTO ⇄ entity mapping happens in Data only; no DTO reaches Presentation.
- [ ] Widgets and notifiers call use cases or repositories, never a data source or HTTP client.
- [ ] Dependencies are injected via providers; no singletons or inline construction in business logic.

## State (Critical/High)

- [ ] Screen state is an `AsyncValue` or a sealed union — no `bool isLoading` + `String? error` pair.
- [ ] State objects are immutable; every update emits a new value (no in-place list/map mutation).
- [ ] `ref.watch` appears only in `build`/provider bodies; `ref.read` only in callbacks.
- [ ] The notifier holds no `BuildContext`, no `Navigator`, and no direct HTTP/database call.
- [ ] Mutations use `AsyncValue.guard` or set an explicit failure state — no error escapes unhandled.
- [ ] One state library in use (Riverpod **or** BLoC), not both.
- [ ] `keepAlive` (where used) carries a comment justifying the lifetime.

## Widgets

- [ ] `build()` contains no networking, persistence, or business rules and is side-effect free.
- [ ] `const` constructors used wherever applicable; analyzer clean with `prefer_const_constructors`.
- [ ] `StatefulWidget` used only for ephemeral widget-local state, not screen state.
- [ ] Every controller, listener, and subscription created is disposed.
- [ ] No widget file exceeds a readable size; subwidgets extracted past ~40 lines of `build`.

## Navigation

- [ ] All navigation goes through the `go_router` route table; no ad-hoc `Navigator.push`.
- [ ] Routes carry ids/primitives; a cold-start deep link resolves without a passed object.
- [ ] Auth gating is a single `redirect`, not per-screen checks.
- [ ] No `BuildContext` used after an `await` without a `context.mounted` guard.

## Async & Errors

- [ ] No bare `catch (_) {}`; every catch handles, translates, or rethrows.
- [ ] Failures crossing the Data boundary are typed (sealed `Failure`), not raw `DioException`.
- [ ] No `!` (bang) on data that can legitimately be absent.
- [ ] No unawaited futures except an explicit `unawaited(...)`.
- [ ] CPU-bound work runs in an isolate, not on the UI isolate.

## Security

- [ ] Tokens, refresh tokens, and PII are in `flutter_secure_storage` — never `shared_preferences`.
- [ ] No secrets, API keys, or client secrets compiled into Dart source or `--dart-define`.
- [ ] No token, password, auth header, or PII in any log or crash report.
- [ ] TLS validation is never disabled (`badCertificateCallback` never returns `true` blanket).

## Performance

- [ ] Long lists use `ListView.builder`/slivers with stable keys.
- [ ] Provider watches narrowed with `select` where the state object is large.
- [ ] Images decoded at display size (`cacheWidth`/`cacheHeight`).
- [ ] No `Opacity`/`ClipRRect`/`ShaderMask` wrapping a large animated subtree without cause.
- [ ] Any performance claim is backed by a `--profile` measurement, not a guess.

## Accessibility

- [ ] Every interactive control has a visible label or a `Semantics` label.
- [ ] Tap targets are at least 48×48dp.
- [ ] No hardcoded colors or font sizes; theme and `textTheme` used so text scaling works.
- [ ] Layout verified at the largest system text size — no clipping or overflow.
- [ ] `ValueKey` present on anything a test or automation drives.

## Tests

- [ ] Notifier tests use `ProviderContainer` with overrides and `addTearDown(container.dispose)`.
- [ ] Widget tests cover loading, loaded, **empty**, and error for each screen.
- [ ] Finders use keys or semantics, not widget types.
- [ ] No real network, database, clock, or randomness in unit or widget tests.
- [ ] No `pumpAndSettle` where an indeterminate progress indicator is on screen.

## Verdict

- [ ] Verdict recorded: Approve / Approve-with-nits / Request-changes.
- [ ] Every Critical/High finding has a file:line and a concrete fix.
