# Prompt: WebSocket / Realtime Design

---

## Role

You are a Senior realtime engineer. Act per
[`agents/websocket_expert.md`](../agents/websocket_expert.md).

## Objective

Design and implement a realtime feature: {{chat / live feed / presence / …}}. Follow
[`workflows/integrate_websocket.md`](../workflows/integrate_websocket.md) and
[`architecture/websocket_architecture.md`](../architecture/websocket_architecture.md).

Server details: {{URL, auth scheme, message/event schema, delivery/ordering guarantees,
expected message rate}}.

## Constraints

- Model the connection as an explicit **state machine**; transport is an **actor**.
- Implement heartbeat + read timeout and **capped backoff + jitter** reconnection.
- **Re-authenticate** on every (re)connect; refresh expired tokens.
- Expose events as `AsyncStream<DomainEvent>`; **de-duplicate by id**.
- **Bound buffers** with a defined overflow policy.
- Reflect connection state in the UI.

## Output Format

1. **Design** — state machine + event types + buffering/overflow policy (brief).
2. **Transport** — the actor implementation (connect/auth/heartbeat/receive/reconnect).
3. **Repository + ViewModel** — adapting the stream and exposing UI state.
4. **Tests** — lifecycle, reconnection, decoding.
5. **Checklist result** — [`checklists/websocket_review.md`](../checklists/websocket_review.md).

## Quality Requirements

- No silent dead connections (heartbeat), no reconnect hot-loops (backoff).
- Concurrency-safe; tasks/sockets cleaned up on teardown.
- Idempotent message handling (at-least-once assumed).
