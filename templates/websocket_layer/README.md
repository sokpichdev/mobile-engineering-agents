# Template: WebSocket Layer

Actor-based realtime transport with state machine, heartbeat, and backoff reconnection. See
[`skills/networking/websocket.md`](../../skills/networking/websocket.md) and
[`architecture/websocket_architecture.md`](../../architecture/websocket_architecture.md).

## Folder Structure

```text
Realtime/
├── ConnectionState.swift
├── {{Feature}}Event.swift          // typed domain events
├── {{Feature}}Socket.swift         // actor transport
└── {{Feature}}RealtimeRepository.swift
Tests/
└── {{Feature}}SocketTests.swift
```

## State & Events

```swift
enum ConnectionState: Equatable { case connecting, connected, reconnecting, disconnected }

enum {{Feature}}Event: Equatable, Identifiable {
    case message(id: String, text: String)
    case presence(userID: String, online: Bool)
    var id: String { /* stable id for de-dup */ "" }
}
```

## Transport (actor)

```swift
actor {{Feature}}Socket {
    private var task: URLSessionWebSocketTask?
    private var attempt = 0
    private var seen = Set<String>()                 // de-dup by event id
    private(set) var state: ConnectionState = .disconnected

    private let url: URL
    private let tokenProvider: () async throws -> String
    private let continuation: AsyncStream<{{Feature}}Event>.Continuation
    let events: AsyncStream<{{Feature}}Event>

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
        } catch { await scheduleReconnect() }
    }

    func close() { task?.cancel(with: .goingAway, reason: nil); state = .disconnected }

    private func receiveLoop() async {
        guard let task else { return }
        do {
            while true {
                if case let .string(text) = try await task.receive(),
                   let event = decode(text), seen.insert(event.id).inserted {
                    continuation.yield(event)
                }
            }
        } catch { await scheduleReconnect() }
    }

    private func scheduleReconnect() async {
        state = .reconnecting; attempt += 1
        let delay = min(pow(2.0, Double(attempt)), 30) + Double.random(in: 0...0.5)
        try? await Task.sleep(for: .seconds(delay))
        await connect()
    }

    private func schedulePing() {
        task?.sendPing { [weak self] _ in Task { await self?.schedulePing() } }
    }

    private func decode(_ text: String) -> {{Feature}}Event? { /* map frame → event */ nil }
}
```

## Conventions

- **State machine** — no ad-hoc booleans.
- **Heartbeat + backoff + jitter** — built in above.
- **Re-auth on (re)connect** via `tokenProvider`.
- **De-dup by id**; **bound the buffer** if your event rate is high (add a buffering policy).
- **Testing:** drive the receive path with a fake task; assert lifecycle + de-dup
  ([`checklists/websocket_review.md`](../../checklists/websocket_review.md)).
