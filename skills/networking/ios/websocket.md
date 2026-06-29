---
platform: ios
---

# Skill: WebSockets

## Overview

WebSockets provide a persistent, full-duplex channel for realtime features (chat, live
prices, presence). On iOS, `URLSessionWebSocketTask` is the built-in transport. A robust
implementation is a **state machine** with authentication, heartbeats, reconnection with
backoff, bounded buffering, and typed event decoding — exposed to features as an
`AsyncStream` of domain events. Treat delivery as **at-least-once** and de-duplicate.

## Use Cases

- Chat and messaging, typing/presence indicators.
- Live financial/sports data, collaborative editing.
- Any low-latency bidirectional server↔client communication.

## Best Practices

- Model the connection as an explicit **state machine** (`connecting/connected/reconnecting/disconnected`).
- Implement **ping/pong heartbeats** and a read timeout to detect dead sockets.
- **Reconnect with capped exponential backoff + jitter**; refresh auth on each new connection.
- Make the transport an **actor**; expose events via `AsyncStream`.
- **Bound buffers** with an overflow policy (drop oldest / coalesce); de-dup by message id.

## Anti-Patterns

- ❌ No heartbeat → undetected dead connections.
- ❌ Reconnect loop with no backoff (battery + server hammering).
- ❌ Unbounded buffering under load.
- ❌ Mutating connection state across threads without synchronization.
- ❌ Assuming exactly-once delivery; showing duplicate messages.

## Checklist

- [ ] Explicit connection state machine.
- [ ] Heartbeat + read timeout.
- [ ] Capped backoff + jitter reconnection; re-auth on reconnect.
- [ ] Actor-isolated; events via `AsyncStream`.
- [ ] Bounded buffer + de-duplication by id.

## Swift Examples

```swift
enum ConnectionState { case connecting, connected, reconnecting, disconnected }

actor ChatSocket {
    private var task: URLSessionWebSocketTask?
    private var attempt = 0
    private(set) var state: ConnectionState = .disconnected

    private let url: URL
    private let tokenProvider: () async throws -> String
    private let continuation: AsyncStream<ChatEvent>.Continuation
    let events: AsyncStream<ChatEvent>

    init(url: URL, tokenProvider: @escaping () async throws -> String) {
        self.url = url; self.tokenProvider = tokenProvider
        (events, continuation) = AsyncStream.makeStream()
    }

    func connect() async {
        state = .connecting
        do {
            var request = URLRequest(url: url)
            request.setValue("Bearer \(try await tokenProvider())", forHTTPHeaderField: "Authorization")
            let task = URLSession.shared.webSocketTask(with: request)
            self.task = task; task.resume()
            state = .connected; attempt = 0
            schedulePing()
            await receiveLoop()
        } catch {
            await scheduleReconnect()
        }
    }

    private func receiveLoop() async {
        guard let task else { return }
        do {
            while true {
                let message = try await task.receive()
                if case let .string(text) = message, let event = ChatEvent(json: text) {
                    continuation.yield(event)         // de-dup happens downstream by event.id
                }
            }
        } catch { await scheduleReconnect() }
    }

    private func scheduleReconnect() async {
        state = .reconnecting
        attempt += 1
        let delay = min(pow(2.0, Double(attempt)), 30) + Double.random(in: 0...0.5) // backoff + jitter
        try? await Task.sleep(for: .seconds(delay))
        await connect()
    }

    private func schedulePing() {
        task?.sendPing { [weak self] _ in Task { await self?.schedulePing() } }
    }
}
```

## Common Interview Questions

- How do you detect and recover from a dead WebSocket?
- Why backoff + jitter for reconnection?
- How do you make the transport thread-safe in Swift Concurrency?
- How do you handle backpressure when the consumer is slow?
- WebSocket vs SSE vs long polling — trade-offs?

## AI Implementation Notes

- Generate an `actor` transport with state machine, heartbeat, and backoff reconnection.
- Expose `AsyncStream<DomainEvent>`; keep decoding in mappers; de-dup by id downstream.
- Re-authenticate on every (re)connect.
- Related: [`sse.md`](sse.md),
  [`../../../architecture/websocket_architecture.md`](../../../architecture/websocket_architecture.md),
  [`../../../agents/websocket_expert.md`](../../../agents/websocket_expert.md).
