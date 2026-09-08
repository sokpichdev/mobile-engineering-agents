---
platform: flutter
---

# Skill: Router Navigation

## Overview

Navigation is declarative: a route table maps URIs to screens, and navigating means changing
location, not imperatively pushing a widget. **`go_router`** is the toolkit's standard — it gives
one table for in-app navigation and deep links, nested navigators for tab shells, and a `redirect`
hook that is the right place for auth gating. This is the Flutter analogue of the iOS rule "drive
navigation by value, not by imperative flags".

## Use Cases

- Any app with more than a couple of screens, or with a bottom-nav/tab shell.
- Auth gating: unauthenticated users land on `/sign-in` no matter which URL they opened.
- Deep links and universal/app links from push notifications, email, or the web.
- Flows that must survive a cold start from a URL (share targets, magic links).

## Best Practices

- **One route table** in one file. Every screen is reachable by a path; nothing is pushed ad hoc.
- Use **typed routes** (`go_router_builder`'s `@TypedGoRoute` codegen) so call sites are
  `ArticleRoute(id: id).go(context)` rather than a stringly-typed `context.go('/articles/$id')`.
- **Pass identifiers, not objects.** A route carries `id`; the screen's notifier loads the entity.
  Passing an object breaks cold-start deep links, which have no object to pass.
- Gate with `redirect` + `refreshListenable` wired to the auth state, so a token expiring
  mid-session redirects immediately. Keep `redirect` pure and fast — it runs on every navigation.
- Use `StatefulShellRoute` for bottom navigation so each tab keeps its own stack and scroll
  position.
- `go` replaces the stack (use it for tab/section switches); `push` stacks (use it for detail and
  modal flows). Choosing wrongly is what produces an un-poppable or infinitely growing stack.
- Define an explicit `errorBuilder` route for unknown paths.
- Navigation is triggered from widgets/callbacks, never from a notifier — a notifier has no
  `BuildContext`. Surface intent as state and let the widget `ref.listen` and navigate.

## Anti-Patterns

- ❌ `Navigator.push(context, MaterialPageRoute(builder: …))` scattered through widgets.
- ❌ Passing an entity through `extra` and reading it without a null fallback — deep links crash.
- ❌ Navigating from inside a `Notifier` or a use case.
- ❌ Using `BuildContext` after an `await` without a `context.mounted` guard.
- ❌ Auth checks duplicated in every screen's `initState` instead of one `redirect`.
- ❌ Building the router inside a widget's `build()` — it must be created once.

## Dart Examples

```dart
// app/router.dart
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider.notifier);

  return GoRouter(
    initialLocation: '/articles',
    refreshListenable: auth,
    redirect: (context, state) {
      final signedIn = ref.read(authStateProvider).isSignedIn;
      final goingToSignIn = state.matchedLocation == '/sign-in';
      if (!signedIn && !goingToSignIn) return '/sign-in?from=${state.uri}';
      if (signedIn && goingToSignIn) return '/articles';
      return null;
    },
    errorBuilder: (context, state) => NotFoundScreen(uri: state.uri),
    routes: [
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),
      GoRoute(
        path: '/articles',
        builder: (_, __) => const ArticlesScreen(),
        routes: [
          // id, not the Article object — a cold-start deep link has no object.
          GoRoute(
            path: ':id',
            builder: (_, state) => ArticleScreen(id: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
});
```

```dart
// ❌ imperative and untyped                    ✅ declarative and typed
Navigator.push(                               // ArticleRoute(id: article.id).go(context);
  context,                                    //
  MaterialPageRoute(                          // (with @TypedGoRoute codegen; without it,
    builder: (_) => ArticleScreen(article),   //  context.go('/articles/${article.id}'))
  ),
);
```

```dart
// Side effects belong in the widget, not the notifier.
class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(checkoutProvider, (_, next) {
      if (next is CheckoutSucceeded) OrderRoute(id: next.orderId).go(context);
    });
    return const CheckoutForm();
  }
}
```

```xml
<!-- android/app/src/main/AndroidManifest.xml — App Links for https deep links -->
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="https" android:host="example.com" />
</intent-filter>
```

## Checklist

- [ ] All navigation goes through the route table; no ad-hoc `Navigator.push`.
- [ ] Routes carry ids/primitives; no entity objects required for a route to resolve.
- [ ] Auth gating is a single `redirect` wired to `refreshListenable`.
- [ ] Tab shells use `StatefulShellRoute` and preserve per-tab stacks.
- [ ] `go` vs `push` chosen deliberately per destination.
- [ ] An `errorBuilder`/404 route exists.
- [ ] No `BuildContext` used across an `await` without `context.mounted`.
- [ ] Cold-start deep links tested on both platforms, including while signed out.

## Common Interview Questions

- Why pass an id rather than the object through a route?
- What does `refreshListenable` do, and what breaks without it?
- `go` vs `push` — what does each do to the stack, and when is each right?
- Why can't a notifier navigate, and where should the side effect live instead?
- How do you keep per-tab navigation stacks independent?

## AI Implementation Notes

- Add every new screen to the route table in the same change that creates it.
- Never generate `Navigator.push(MaterialPageRoute(...))` in a Riverpod codebase.
- Route parameters are primitives. If a screen needs an entity, it loads it by id.
- Put post-action navigation in `ref.listen` in the widget, never in the notifier.
- `auto_route` is an accepted alternative for teams that want generated guards; do not run both.
- iOS counterpart: [`../ios/coordinator_navigation.md`](../ios/coordinator_navigation.md).
- Related: [`state_management.md`](state_management.md),
  [`../../../standards/flutter_standards.md`](../../../standards/flutter_standards.md).
