---
platform: flutter
---

# Skill: REST API

## Overview

The standard HTTP client is **`dio`**: it has interceptors, cancellation, per-request timeouts,
and `FormData` built in, which is what a real app needs for auth refresh, retries, and redacted
logging. `package:http` is fine for a trivial app with no cross-cutting concerns. Wrap it in a
typed `ApiClient` inside the Data layer, map `DioException` to a sealed `Failure`, and never let
a `Response` escape upward.

## Use Cases

- Any backend integration behind a repository.
- Authenticated APIs needing token injection and 401-triggered refresh.
- Uploads/downloads with progress and cancellation.
- Environments where retries and timeouts must be policy, not per-call-site guesswork.

## Best Practices

- One configured `Dio` instance per API, created in a provider with the base URL and timeouts;
  never `Dio()` inline in a data source.
- **Interceptor stack, in order:** auth-token injection → retry → logging (redacted). Keep each
  interceptor single-purpose.
- **Single-flight refresh.** On 401, one refresh runs and every other in-flight 401 waits on it.
  Refreshing per-request is the classic source of token-rotation races and mass logouts.
- Retry only **idempotent** requests (`GET`, `HEAD`, `PUT`, `DELETE`, or `POST` carrying an
  idempotency key), with exponential backoff plus jitter and a cap. Never retry a 4xx except 408/429.
- Honor `Retry-After` on 429/503.
- Set `connectTimeout`, `sendTimeout`, and `receiveTimeout` explicitly — the defaults are
  effectively "wait forever" for a mobile network.
- Generate DTOs with `json_serializable` (or `freezed`); map to entities in the repository. Never
  hand-parse JSON in a widget or notifier.
- Pass a `CancelToken` for anything a screen can navigate away from, and cancel it on dispose.
- **Redact logs.** Never log `Authorization`, cookies, or response bodies containing PII.

## Anti-Patterns

- ❌ Calling `dio` from a widget, notifier, or use case.
- ❌ Returning `Response` or `Map<String, dynamic>` from a repository.
- ❌ `catch (_) {}` swallowing a transport error into a silent empty state.
- ❌ Retrying non-idempotent `POST` without an idempotency key (duplicate orders).
- ❌ Logging the full request in release builds.
- ❌ A refresh interceptor that can recurse into itself on a failing refresh endpoint.
- ❌ Base URL or API keys hardcoded in Dart source.

## Checklist

- [ ] One `Dio` per API, configured in a provider, with all three timeouts set.
- [ ] Auth, retry, and logging are separate interceptors in a defined order.
- [ ] Token refresh is single-flight and cannot recurse.
- [ ] Retries are limited to idempotent requests, with backoff, jitter, and a cap.
- [ ] `DioException` is mapped to a sealed `Failure` at the Data boundary.
- [ ] DTOs are generated/typed and mapped to entities in Data.
- [ ] `CancelToken` is used and cancelled on dispose for screen-scoped requests.
- [ ] No secrets or PII in logs; logging interceptor is redacted.

## Dart Examples

```dart
// data/network/api_client.dart
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ref.watch(configProvider).apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  dio.interceptors.addAll([
    AuthInterceptor(ref.watch(tokenStoreProvider), ref.watch(refreshTokenProvider)),
    RetryInterceptor(maxAttempts: 3),
    RedactedLogInterceptor(enabled: kDebugMode),
  ]);
  ref.onDispose(dio.close);
  return dio;
});
```

```dart
// data/network/auth_interceptor.dart — single-flight refresh
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokens, this._refresh);

  final TokenStore _tokens;
  final RefreshToken _refresh;
  Future<String>? _inFlight;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokens.accessToken();
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401 || err.requestOptions.extra['retried'] == true) {
      return handler.next(err);
    }
    try {
      // Every concurrent 401 awaits the same refresh; only one hits the network.
      final token = await (_inFlight ??= _refresh().whenComplete(() => _inFlight = null));
      final options = err.requestOptions
        ..headers['Authorization'] = 'Bearer $token'
        ..extra['retried'] = true;
      handler.resolve(await Dio().fetch<dynamic>(options));
    } catch (_) {
      await _tokens.clear();
      handler.next(err);
    }
  }
}
```

```dart
// data/repositories/article_repository_impl.dart — errors become Domain failures here
Never _mapError(DioException e) => throw switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => const NetworkFailure(),
      DioExceptionType.cancel => const CancelledFailure(),
      DioExceptionType.badResponse => switch (e.response?.statusCode) {
          401 => const UnauthorizedFailure(),
          404 => const NotFoundFailure(),
          final code? when code >= 500 => const ServerFailure(),
          _ => UnknownFailure(e),
        },
      _ => UnknownFailure(e),
    };
```

```dart
// ❌ transport leaks upward                    ✅ entities and typed failures only
Future<Response> getArticles();               // Future<List<Article>> fetchArticles({int page});
```

## Common Interview Questions

- Why must token refresh be single-flight, and what goes wrong without it?
- Which HTTP methods are safe to retry automatically, and what makes `POST` different?
- Where should `DioException` be caught, and what should cross the Data boundary instead?
- What do the three `dio` timeouts each cover?
- How do you cancel an in-flight request when the user leaves the screen?

## AI Implementation Notes

- Never generate a `Dio()` constructed inside a data source, notifier, or widget — inject it.
- Always generate the `DioException` → `Failure` mapping; never leave a bare `catch`.
- Default to `dio`; use `http` only if the project already depends on it and needs no interceptors.
- Pair every new endpoint with a DTO, a mapper, and a repository method returning entities.
- iOS counterpart: [`../ios/rest_api.md`](../ios/rest_api.md).
- Related: [`pagination.md`](pagination.md),
  [`../../security/flutter/oauth2.md`](../../security/flutter/oauth2.md),
  [`../../../standards/networking_standards.md`](../../../standards/networking_standards.md).
