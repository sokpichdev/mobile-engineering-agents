---
platform: flutter
---

# Skill: WebSocket

## Overview

Realtime transport in Flutter uses `web_socket_channel`, wrapped in a Data-layer service that owns
an explicit connection state machine and exposes a broadcast `Stream` of decoded domain messages.
The hard parts are not the connect call — they are reconnection with backoff, re-authentication
after a token refresh, backpressure, and disposing the socket. A leaked socket that reconnects
forever in the background is the single most common Flutter realtime bug.

## Use Cases

- Live prices, order status, or telemetry pushed from the server.
- Chat and presence.
- Collaborative editing and any low-latency bidirectional feature.
- Long-lived subscriptions where polling would be wasteful on battery.

## Best Practices

- Model connection state as an explicit sealed union —
  `Disconnected | Connecting | Connected | Reconnecting | Failed` — and surface it to the UI. Users
  need to see "reconnecting", not a frozen screen.
- **Reconnect with exponential backoff plus jitter**, with a cap (e.g. 30s) and a maximum attempt
  budget before surfacing `Failed`. Jitter matters: without it every client reconnects in lockstep
  after a server restart and re-DDoSes it.
- Send **heartbeats** and treat a missed pong as a dead connection. TCP will not tell you the peer
  vanished behind a NAT timeout.
- Expose a **broadcast** stream so several widgets can listen; decode to domain types in Data.
- **Always `ref.onDispose(close)`.** An `autoDispose` provider plus an unclosed sink still leaks.
- Reconnect on auth refresh: pass the token at connect time and re-connect after rotation.
- Handle backpressure: buffer or drop deliberately (`Stream.transform` with a bounded queue).
  Never `await` slow work inside a `listen` callback — it blocks the socket's event loop.
- Pause on app background and resume on foreground where the feature allows; a socket held open in
  the background drains battery and may be killed by the OS anyway.
- Distinguish close codes: a clean server close (1000) is not a reason to reconnect; 1006/1011 is.

## Anti-Patterns

- ❌ Opening a socket in a widget's `initState` and never closing it.
- ❌ Reconnecting in a tight loop with no backoff.
- ❌ A single-subscription stream that a second widget then fails to listen to.
- ❌ Parsing JSON and applying business rules inside the `listen` callback.
- ❌ Treating every close as fatal, or every close as retryable.
- ❌ Ignoring the auth token's expiry so the socket silently stops receiving.
- ❌ Unbounded buffering of inbound messages when the UI cannot keep up.

## Checklist

- [ ] Connection state is an explicit sealed union surfaced to the UI.
- [ ] Reconnect uses exponential backoff with jitter, a cap, and an attempt budget.
- [ ] Heartbeat/pong timeout detects dead connections.
- [ ] Stream is broadcast; messages are decoded to domain types in Data.
- [ ] `ref.onDispose` closes the sink and cancels the subscription.
- [ ] Close codes are handled distinctly (clean vs abnormal).
- [ ] Backpressure strategy is explicit (bounded buffer or documented drop).
- [ ] Token rotation triggers a reconnect with the new credential.

## Dart Examples

```dart
// data/realtime/ticker_service.dart
sealed class ConnectionState {
  const ConnectionState();
}

final class Disconnected extends ConnectionState {
  const Disconnected();
}

final class Connecting extends ConnectionState {
  const Connecting();
}

final class Connected extends ConnectionState {
  const Connected();
}

final class Reconnecting extends ConnectionState {
  const Reconnecting(this.attempt);
  final int attempt;
}

final class ConnectionFailed extends ConnectionState {
  const ConnectionFailed(this.cause);
  final Object cause;
}
```

```dart
class TickerService {
  TickerService(this._uri, this._tokens);

  final Uri _uri;
  final TokenStore _tokens;
  final _messages = StreamController<Tick>.broadcast();
  final _state = StreamController<ConnectionState>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _reconnect;
  int _attempt = 0;
  bool _closed = false;

  Stream<Tick> get messages => _messages.stream;
  Stream<ConnectionState> get state => _state.stream;

  Future<void> connect() async {
    if (_closed) return;
    _state.add(_attempt == 0 ? const Connecting() : Reconnecting(_attempt));

    final token = await _tokens.accessToken();
    final channel = WebSocketChannel.connect(
      _uri.replace(queryParameters: {'access_token': token ?? ''}),
    );
    _channel = channel;

    await channel.ready;
    _attempt = 0;
    _state.add(const Connected());

    _sub = channel.stream.listen(
      // Decode only; never await slow work here — it blocks the socket.
      (event) => _messages.add(Tick.fromJson(jsonDecode(event as String) as Map<String, dynamic>)),
      onDone: _scheduleReconnect,
      onError: (Object _) => _scheduleReconnect(),
      cancelOnError: true,
    );
  }

  void _scheduleReconnect() {
    if (_closed) return;
    // Clean server close: do not fight it.
    if (_channel?.closeCode == status.normalClosure) {
      _state.add(const Disconnected());
      return;
    }
    if (_attempt >= 8) {
      _state.add(const ConnectionFailed('retry budget exhausted'));
      return;
    }
    final backoff = Duration(milliseconds: 500 * (1 << _attempt));
    final jitter = Duration(milliseconds: Random().nextInt(500));
    _attempt++;
    _state.add(Reconnecting(_attempt));
    _reconnect = Timer(
      Duration(milliseconds: min(backoff.inMilliseconds, 30000) + jitter.inMilliseconds),
      connect,
    );
  }

  Future<void> close() async {
    _closed = true;
    _reconnect?.cancel();
    await _sub?.cancel();
    await _channel?.sink.close(status.normalClosure);
    await _messages.close();
    await _state.close();
  }
}

final tickerServiceProvider = Provider<TickerService>((ref) {
  final service = TickerService(ref.watch(configProvider).wsUri, ref.watch(tokenStoreProvider))
    ..connect();
  ref.onDispose(service.close); // without this, the socket outlives the screen
  return service;
});
```

## Common Interview Questions

- Why add jitter to reconnect backoff?
- How do you detect a connection that is dead but not closed?
- Why must the stream be broadcast, and what happens if it isn't?
- What goes wrong if you `await` inside the socket's `listen` callback?
- How do you handle the access token expiring on a long-lived socket?
- Which close codes should trigger a reconnect and which should not?

## AI Implementation Notes

- Always generate the state machine and the disposal path together with the connect call.
- Never generate a socket opened from a widget or a notifier — it belongs in a Data service.
- Every provider that owns a socket must register `ref.onDispose`.
- Default to backoff with jitter, a 30s cap, and a finite attempt budget.
- iOS counterpart: [`../ios/websocket.md`](../ios/websocket.md).
- Related: [`../../../architecture/websocket_architecture.md`](../../../architecture/websocket_architecture.md),
  [`../../../checklists/websocket_review.md`](../../../checklists/websocket_review.md).
