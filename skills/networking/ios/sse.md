---
platform: ios
---

# Skill: Server-Sent Events (SSE)

## Overview

Server-Sent Events is a one-way (server→client) streaming protocol over a long-lived HTTP
response with `Content-Type: text/event-stream`. It's simpler than WebSockets when you only
need server push (notifications, progress, live feeds, AI token streaming). It supports
automatic reconnection via `Last-Event-ID` and works over standard HTTP. On iOS, consume it
with `URLSession.bytes(for:)` and parse the line-based event format.

## Use Cases

- Server→client only updates: live scores, notifications, status/progress.
- Streaming LLM/AI token responses.
- When you want push without the complexity/bidirectionality of WebSockets.

## Best Practices

- Parse the SSE format correctly: `event:`, `data:` (multi-line), `id:`, `retry:`; events are
  separated by a blank line.
- Track the **last event id** and send it as `Last-Event-ID` on reconnect to resume.
- **Reconnect with backoff** (honor server `retry:` hint); SSE expects auto-reconnect.
- Decode each event's `data` payload into a typed domain event.
- Expose as an `AsyncThrowingStream`; honor cancellation to close the connection.

## Anti-Patterns

- ❌ Treating the body as one JSON blob instead of a line-based event stream.
- ❌ Ignoring `id:`/`Last-Event-ID`, so reconnects lose/duplicate events.
- ❌ No reconnection logic (SSE connections drop routinely).
- ❌ Using SSE when you actually need client→server messaging (use WebSocket).
- ❌ Blocking the main thread parsing the stream.

## Checklist

- [ ] Correct SSE parsing (multi-line `data`, blank-line delimiters).
- [ ] Last event id tracked and resent on reconnect.
- [ ] Reconnection with backoff; server `retry:` respected.
- [ ] Typed event decoding; exposed as an async stream.
- [ ] Cancellation closes the connection.

## Swift Examples

```swift
struct SSEvent { var id: String?; var event: String?; var data: String }

func eventStream(from url: URL, lastEventID: String?) -> AsyncThrowingStream<SSEvent, Error> {
    AsyncThrowingStream { continuation in
        let task = Task {
            var request = URLRequest(url: url)
            request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
            if let lastEventID { request.setValue(lastEventID, forHTTPHeaderField: "Last-Event-ID") }
            do {
                let (bytes, _) = try await URLSession.shared.bytes(for: request)
                var current = SSEvent(data: "")
                for try await line in bytes.lines {
                    if line.isEmpty {                       // blank line = dispatch event
                        if !current.data.isEmpty { continuation.yield(current) }
                        current = SSEvent(data: "")
                    } else if line.hasPrefix("id:") {
                        current.id = line.dropFirst(3).trimmingCharacters(in: .whitespaces)
                    } else if line.hasPrefix("event:") {
                        current.event = line.dropFirst(6).trimmingCharacters(in: .whitespaces)
                    } else if line.hasPrefix("data:") {
                        current.data += line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                    }
                    if Task.isCancelled { break }
                }
                continuation.finish()
            } catch { continuation.finish(throwing: error) }
        }
        continuation.onTermination = { _ in task.cancel() }
    }
}
```

## Common Interview Questions

- SSE vs WebSocket — when to choose each?
- How does SSE resume after a dropped connection?
- How is the SSE wire format structured?
- Can SSE send data from client to server? (No — use a separate request/WebSocket.)
- How would you stream AI tokens to the UI with SSE?

## AI Implementation Notes

- Parse line-by-line with `URLSession.bytes`; dispatch on blank lines.
- Track and resend `Last-Event-ID`; reconnect with backoff.
- Expose `AsyncThrowingStream` and cancel the task on termination.
- Related: [`websocket.md`](websocket.md), [`rest_api.md`](rest_api.md).
