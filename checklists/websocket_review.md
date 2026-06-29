# Checklist: WebSocket / Realtime Review

Owned by the [WebSocket Expert](../agents/websocket_expert.md). See
[`skills/networking/ios/websocket.md`](../skills/networking/ios/websocket.md) and
[`architecture/websocket_architecture.md`](../architecture/websocket_architecture.md).

## Connection Lifecycle (Critical)

- [ ] Connection modeled as an explicit state machine (`connecting/connected/reconnecting/disconnected`).
- [ ] Heartbeat (ping/pong) and a read timeout detect dead connections.
- [ ] Reconnection uses capped exponential backoff + jitter (no tight loops).
- [ ] Connection authenticates on every (re)connect; expired tokens refreshed first.
- [ ] Sockets/tasks cleaned up on teardown (no leaks).

## Concurrency (Critical)

- [ ] Transport is actor-isolated (or access otherwise serialized); no shared mutable races.
- [ ] Events exposed via `AsyncStream`/`AsyncThrowingStream`.

## Messaging

- [ ] Incoming frames decoded into typed domain events (no raw dictionaries leaking out).
- [ ] Messages de-duplicated by id (at-least-once delivery assumed).
- [ ] Ordering assumptions documented.

## Backpressure

- [ ] Buffers are bounded with a defined overflow policy (drop oldest / coalesce / suspend).
- [ ] Slow-consumer behavior verified under load.

## UX & Performance

- [ ] UI reflects connection state (incl. degraded/reconnecting).
- [ ] No excessive battery/CPU under sustained traffic.

## Tests

- [ ] Connection lifecycle, reconnection, and decoding covered by tests.
