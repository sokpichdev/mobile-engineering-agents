# Standard: Networking Standards

Rules for the network/data layer. Enforced via [`checklists/api_review.md`](../checklists/api_review.md)
and the [Networking Expert](../agents/networking_expert.md).

## Client

- All requests go through an injectable `APIClient` protocol — **never** raw `URLSession` in
  features.
- One configured `JSONDecoder` (key + date strategy) shared across the layer.
- Explicit timeouts (request ≤ 30s default); honor `Task` cancellation.

## Requests

- Endpoints are **typed values** (path, method, query, body, headers), not ad-hoc strings.
- Set `Content-Type`/`Accept` explicitly; build query items via `URLComponents`.
- Idempotent requests (GET/PUT/DELETE) may retry with **exponential backoff + jitter** and a cap.
- Non-idempotent requests (POST) retry **only** with a server-supported idempotency key.

## Responses & Errors

- Validate HTTP status **before** decoding; decode error bodies for non-2xx.
- Map transport/HTTP/decoding failures into a **typed domain error**; never surface raw
  `URLError`/status codes to the UI.
- GraphQL: treat a populated `errors` array as a failure even on HTTP 200.

```swift
guard (200..<300).contains(http.statusCode) else { throw NetworkError.http(http.statusCode) }
do { return try decoder.decode(R.self, from: data) } catch { throw NetworkError.decoding }
```

## Mapping

- DTOs mirror the wire format; map DTO→entity in a dedicated mapper.
- Unknown enum values decode to a safe `.unknown` case.
- DTOs never leak past the Data layer.

## Security

- Inject auth headers centrally; on 401, refresh **once** (single-flight) and retry.
- No tokens/PII in URLs, query strings, or logs. TLS enforced; pin sensitive hosts
  (see [`security_standards.md`](security_standards.md)).

## Realtime

- WebSocket/SSE transports are actor-isolated state machines with heartbeat + backoff
  reconnection, exposed as `AsyncStream`. See
  [`checklists/websocket_review.md`](../checklists/websocket_review.md).

## Testing

- Client behavior tested via `URLProtocol` stubbing or an injected fake client with JSON fixtures
  (success + error + empty). No live-server calls in tests.
