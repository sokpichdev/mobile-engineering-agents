# Workflow: Integrate WebSockets (Realtime)

## Objective

Add a reliable realtime feature: an authenticated WebSocket transport with heartbeats,
reconnection, backpressure, and typed events exposed to the UI as an `AsyncStream`.

## Inputs

- WebSocket URL, auth scheme, message/event schema, ordering/delivery guarantees.
- Backpressure expectations (message rate, criticality).

## Outputs

- Actor-based transport (state machine), typed event mappers, repository/stream, UI state, tests.

## Step-by-Step Process

1. **Design** ([iOS Architect](../agents/ios_architect.md) +
   [WebSocket Expert](../agents/websocket_expert.md)) — define the connection state machine,
   event types, and buffering/overflow policy
   (see [`architecture/websocket_architecture.md`](../architecture/websocket_architecture.md)).
2. **Build the transport** as an `actor`: connect, authenticate, heartbeat, receive loop,
   capped backoff reconnection (see [`skills/networking/ios/websocket.md`](../skills/networking/ios/websocket.md)).
3. **Decode events** into typed domain events; de-duplicate by id.
4. **Apply backpressure** — bounded buffer with drop/coalesce policy.
5. **Auth** ([Security Expert](../agents/security_expert.md)) — refresh token on each (re)connect;
   no token leakage.
6. **Expose state** (`connecting/connected/reconnecting/disconnected`) to the UI.
7. **Performance** ([Performance Expert](../agents/performance_expert.md)) — verify no battery/
   memory issues under load.
8. **Test** connection lifecycle, reconnection, and decoding; **review** against
   [`checklists/websocket_review.md`](../checklists/websocket_review.md).

## Validation Steps

- Survives network drop: detects via heartbeat and reconnects with backoff.
- Re-authenticates on reconnect; no duplicate events shown.
- Buffer bounded under load; UI reflects connection state.

## Failure Scenarios

- **Silent dead connection** → heartbeat + read timeout must catch it.
- **Reconnect storm** → ensure capped backoff + jitter.
- **Token expiry across reconnect** → refresh before reconnecting.
- **Consumer flooded** → apply the defined overflow policy.

## AI Agent Instructions

- Model the connection as an explicit state machine; make the transport an actor.
- Always implement heartbeat + backoff reconnection; re-auth on reconnect.
- Expose `AsyncStream<DomainEvent>`; de-dup by id; bound buffers.
- Clean up tasks/sockets on teardown.

## Acceptance Criteria

- [ ] Actor transport with state machine, heartbeat, backoff reconnection.
- [ ] Re-auth on reconnect; events de-duplicated.
- [ ] Bounded buffering; UI shows connection state.
- [ ] Lifecycle + decoding tested; `checklists/websocket_review.md` passes.
