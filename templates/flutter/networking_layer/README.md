# Template: Networking Layer

A `dio`-based API client with a typed endpoint model, an interceptor stack, and error mapping into
a sealed `Failure` union. See
[`skills/networking/flutter/rest_api.md`](../../../skills/networking/flutter/rest_api.md) and
[`standards/networking_standards.md`](../../../standards/networking_standards.md).

## Folder Structure

```text
core/network/
├── api_client.dart          // configured Dio + provider
├── endpoint.dart            // typed request description
├── failure.dart             // sealed Failure union + DioException mapping
└── interceptors/
    ├── auth_interceptor.dart    // token injection + single-flight refresh
    ├── retry_interceptor.dart   // backoff + jitter, idempotent methods only
    └── log_interceptor.dart     // redacted, debug-only
```

## Client

```dart
final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(configProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      // Defaults are effectively "wait forever" on a mobile network. Always set these.
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  // Order matters: auth first, then retry, then logging.
  dio.interceptors.addAll([
    AuthInterceptor(ref.watch(tokenStoreProvider), ref.watch(refreshTokenProvider)),
    RetryInterceptor(maxAttempts: 3),
    RedactedLogInterceptor(enabled: kDebugMode),
  ]);

  ref.onDispose(dio.close);
  return dio;
});
```

## Failure Mapping

```dart
sealed class Failure implements Exception {
  const Failure();
}

final class NetworkFailure extends Failure {
  const NetworkFailure();
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure();
}

final class ServerFailure extends Failure {
  const ServerFailure();
}

final class CancelledFailure extends Failure {
  const CancelledFailure();
}

final class UnknownFailure extends Failure {
  const UnknownFailure(this.cause);
  final Object cause;
}

/// Called from the repository. Nothing above the Data layer sees DioException.
Failure mapDioException(DioException e) => switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.connectionError =>
        const NetworkFailure(),
      DioExceptionType.cancel => const CancelledFailure(),
      DioExceptionType.badResponse => switch (e.response?.statusCode) {
          401 => const UnauthorizedFailure(),
          final code? when code >= 500 => const ServerFailure(),
          _ => UnknownFailure(e),
        },
      _ => UnknownFailure(e),
    };
```

## Retry Interceptor

```dart
class RetryInterceptor extends Interceptor {
  RetryInterceptor({this.maxAttempts = 3});

  final int maxAttempts;

  static const _idempotent = {'GET', 'HEAD', 'PUT', 'DELETE'};

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final attempt = (err.requestOptions.extra['attempt'] as int? ?? 0) + 1;
    final method = err.requestOptions.method.toUpperCase();
    final status = err.response?.statusCode;

    final retryable = _idempotent.contains(method) &&
        (status == null || status == 408 || status == 429 || status >= 500);

    if (!retryable || attempt >= maxAttempts) return handler.next(err);

    // Exponential backoff with jitter: without jitter, every client retries in
    // lockstep after an outage and re-floods the server.
    final backoff = Duration(milliseconds: 300 * (1 << (attempt - 1)));
    final jitter = Duration(milliseconds: Random().nextInt(300));
    await Future<void>.delayed(backoff + jitter);

    err.requestOptions.extra['attempt'] = attempt;
    handler.resolve(await Dio().fetch<dynamic>(err.requestOptions));
  }
}
```

## Conventions Demonstrated

- **One configured `Dio` per API**, built in a provider — never `Dio()` inline in a data source.
- **All three timeouts set explicitly.**
- **Interceptors are single-purpose and ordered**: auth → retry → logging.
- **Retries only on idempotent methods**, with backoff, jitter, and a cap. A non-idempotent `POST`
  needs an idempotency key before it can be retried.
- **Transport errors are mapped at the Data boundary** into a sealed `Failure`.
- **Logging is redacted and debug-only** — never log `Authorization`, cookies, or PII.

## Usage

1. Copy into `lib/core/network/` and split the sections into the files above.
2. Wire `configProvider` and `tokenStoreProvider` to your app's real providers.
3. Call `mapDioException` from every repository `catch`.
4. Add pinning if the app requires it
   ([`skills/security/flutter/ssl_pinning.md`](../../../skills/security/flutter/ssl_pinning.md)).

## Related

- Skill: [`skills/networking/flutter/rest_api.md`](../../../skills/networking/flutter/rest_api.md)
- Skill: [`skills/security/flutter/oauth2.md`](../../../skills/security/flutter/oauth2.md)
- Architecture: [`architecture/networking_architecture.md`](../../../architecture/networking_architecture.md)
