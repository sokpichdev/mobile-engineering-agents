---
platform: flutter
---

# Skill: Platform Channels

## Overview

Platform channels are the bridge from Dart to native iOS (Swift) and Android (Kotlin) code. Use
them when a capability has no package: a vendor SDK, a hardware integration, an existing native
module. **Prefer `pigeon`** — it generates typed Dart and native interfaces from one schema, so
the compiler catches a signature mismatch that a hand-written `MethodChannel` would only surface
as a runtime crash. Architecturally the channel is a **Data-layer detail**: Domain declares an
interface, Data implements it over the channel, and nothing above Data imports
`package:flutter/services.dart`.

## Use Cases

- Vendor SDKs with no Flutter package (payments, telematics, DRM, kiosk hardware).
- Reusing an existing native module during an incremental migration to Flutter.
- OS APIs Flutter does not surface (specific `HealthKit`/`SensorManager` calls, widgets/complications).
- Native→Dart event streams: location updates, BLE scans, sensor feeds (`EventChannel`).
- CPU-bound native libraries where the marshalling cost matters (`dart:ffi` instead).

## Best Practices

- **Use `pigeon` for anything beyond a single trivial call.** It removes stringly-typed method
  names, generates both sides, and makes an argument-type change a compile error.
- Keep the channel wrapper in `data/`, behind a Domain interface, so callers are testable with a
  fake and no method-channel plumbing.
- **Version the contract.** Channel names should be reverse-DNS and stable
  (`dev.example.app/payments`); treat a change as a breaking API change.
- Map native errors into the same sealed `Failure` hierarchy the network layer uses. Agree a
  fixed `code` vocabulary with the native side and document it in the wrapper.
- **Channels are bound to the platform thread.** Do long native work on a background thread/queue
  natively and reply when it completes; never block the platform thread.
- Calling a channel from a background Dart isolate requires
  `BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken)` — otherwise it throws.
- Handle `MissingPluginException`: it means the native side is not registered on this platform.
  Degrade gracefully rather than crashing on the platform you did not implement.
- Package as a federated plugin (`flutter create --template=plugin`) when the capability is
  reusable across apps; keep it in-app otherwise.

## Anti-Patterns

- ❌ `MethodChannel` invoked directly from a widget or a notifier.
- ❌ `import 'package:flutter/services.dart'` anywhere in Domain.
- ❌ Stringly-typed method names and `Map<String, dynamic>` payloads for a non-trivial API.
- ❌ Swallowing `PlatformException` into a generic "something went wrong".
- ❌ Long-running or blocking work on the native platform thread (it janks the UI).
- ❌ Assuming a channel exists on both platforms — an unimplemented side throws
  `MissingPluginException`.
- ❌ Sending large binary payloads as base64 strings instead of using `dart:ffi` or a file path.

## Checklist

- [ ] The channel lives in Data, behind a Domain interface.
- [ ] Non-trivial contracts use `pigeon`, not hand-written `MethodChannel`.
- [ ] Channel name is reverse-DNS and stable; the contract is documented.
- [ ] Native errors map to typed Domain failures with an agreed code vocabulary.
- [ ] `MissingPluginException` is handled per platform.
- [ ] Long native work runs off the platform thread.
- [ ] Background-isolate callers initialize `BackgroundIsolateBinaryMessenger`.
- [ ] A fake channel handler covers the wrapper in widget/unit tests.

## Dart Examples

```dart
// domain/services/device_attestation.dart — Domain owns the interface, knows nothing of channels
abstract interface class DeviceAttestation {
  Future<String> requestToken({required String nonce});
}

// data/services/device_attestation_channel.dart — the only file that knows a channel exists
class DeviceAttestationChannel implements DeviceAttestation {
  const DeviceAttestationChannel([
    this._channel = const MethodChannel('dev.example.app/attestation'),
  ]);

  final MethodChannel _channel;

  @override
  Future<String> requestToken({required String nonce}) async {
    try {
      final token = await _channel.invokeMethod<String>('requestToken', {'nonce': nonce});
      if (token == null) throw const UnknownFailure('null attestation token');
      return token;
    } on PlatformException catch (e) {
      throw switch (e.code) {
        'UNSUPPORTED_DEVICE' => const AttestationUnsupportedFailure(),
        'NETWORK' => const NetworkFailure(),
        _ => UnknownFailure(e),
      };
    } on MissingPluginException {
      throw const AttestationUnsupportedFailure();
    }
  }
}
```

```dart
// EventChannel: a native stream surfaced as a Dart Stream, disposed with the provider
final batteryLevelProvider = StreamProvider.autoDispose<int>((ref) {
  const channel = EventChannel('dev.example.app/battery');
  return channel.receiveBroadcastStream().map((event) => event as int);
});
```

```dart
// test — no native side required
test('maps UNSUPPORTED_DEVICE to a typed failure', () async {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dev.example.app/attestation');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    throw PlatformException(code: 'UNSUPPORTED_DEVICE');
  });

  const sut = DeviceAttestationChannel(channel);

  await expectLater(
    sut.requestToken(nonce: 'n'),
    throwsA(isA<AttestationUnsupportedFailure>()),
  );
});
```

```kotlin
// android — reply on the platform thread, but do the work off it
class AttestationPlugin : FlutterPlugin, MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "requestToken" -> scope.launch {
                runCatching { attestor.token(call.argument<String>("nonce")!!) }
                    .onSuccess { token -> mainHandler.post { result.success(token) } }
                    .onFailure { e -> mainHandler.post { result.error("NETWORK", e.message, null) } }
            }
            else -> result.notImplemented()
        }
    }
}
```

## Common Interview Questions

- Why does the channel belong in Data rather than being called from the notifier?
- What does `pigeon` give you over a hand-written `MethodChannel`?
- What is `MissingPluginException` and when does it legitimately occur?
- Which thread does a `MethodChannel` handler run on natively, and why does that matter?
- When would you reach for `dart:ffi` instead of a method channel?
- How do you unit-test code that calls a platform channel with no device attached?

## AI Implementation Notes

- Always generate the Domain interface first, then the channel wrapper implementing it.
- Never put a `MethodChannel` inside a widget, a notifier, or anything under `domain/`.
- Map every `PlatformException` code explicitly; do not leave a bare `catch`.
- Emit a test using `setMockMethodCallHandler` alongside every new channel wrapper.
- Recommend `pigeon` for any contract with more than one method or a non-primitive argument.
- Related: [`clean_architecture.md`](clean_architecture.md),
  [`repository_pattern.md`](repository_pattern.md),
  [`../../../standards/flutter_standards.md`](../../../standards/flutter_standards.md).
