---
platform: flutter
---

# Skill: Secure Storage

## Overview

`flutter_secure_storage` is the cross-platform front for the OS credential stores: the **Keychain**
on iOS and a **Keystore-backed encrypted store** on Android. Access tokens, refresh tokens,
client-side encryption keys, and PII go there and nowhere else. `shared_preferences` is a plain
XML/plist file — it is readable on a rooted device and, on Android, may be swept into cloud backup.
Hide the choice behind a `TokenStore` interface in Domain so the rest of the app never imports the
package.

## Use Cases

- Storing OAuth access and refresh tokens.
- Holding a database encryption key for SQLCipher-backed `drift`.
- Biometric-gated secrets (paired with `local_auth`).
- Any PII that must survive a restart but must not be world-readable on a compromised device.

## Best Practices

- **Interface in Domain, package in Data.** Domain declares `TokenStore`; only the Data
  implementation imports `flutter_secure_storage`.
- **Set iOS accessibility explicitly.** Default to `first_unlock_this_device`: it keeps the item
  off backups and off other devices while still allowing background refresh after first unlock.
  `whenUnlocked` if the secret must never be readable while locked.
- **The iOS Keychain survives app uninstall.** A reinstall can therefore find a stale token for a
  user who is "signed out". Clear secure storage on first run after install (flag it in
  `shared_preferences`, which *is* wiped).
- On Android, ensure the encrypted store is used and exclude it from auto-backup
  (`android:allowBackup="false"` or explicit backup rules) so a cloud backup can't carry
  credentials to another device.
- **Access tokens live in memory; refresh tokens live in secure storage.** Writing on every request
  is slow and pointless.
- Clear everything on logout — tokens, cached PII, and the encrypted DB key.
- Encrypt the local database with SQLCipher when it holds PII, keeping the key in secure storage.
- Know the boundary: secure storage does **not** defend a rooted/jailbroken device. Pair it with
  short token TTLs and server-side revocation.

## Anti-Patterns

- ❌ Tokens or PII in `shared_preferences`, a plain file, or an unencrypted DB column.
- ❌ API keys or client secrets compiled into Dart — `--dart-define` values are extractable
  strings in the binary, not a secret store.
- ❌ Logging a token value, even truncated, even in debug.
- ❌ Leaving iOS accessibility at the default without deciding.
- ❌ Not clearing the Keychain on first run after reinstall.
- ❌ Caching a decrypted secret in a long-lived provider or a global.
- ❌ Treating secure storage as protection against a rooted device.

## Checklist

- [ ] All credentials go through a `TokenStore` interface; the package is imported in one file.
- [ ] iOS `accessibility` is set explicitly and justified.
- [ ] Android uses the encrypted store and is excluded from auto-backup.
- [ ] Secure storage is cleared on first run after install.
- [ ] Logout clears tokens, cached PII, and any DB encryption key.
- [ ] No secret values appear in logs or crash reports.
- [ ] No API keys or secrets are compiled into the Dart binary.
- [ ] The DB holding PII is encrypted, with its key in secure storage.

## Dart Examples

```dart
// domain/services/token_store.dart — Domain has no idea a keychain exists
abstract interface class TokenStore {
  Future<String?> refreshToken();
  Future<void> save({required String refreshToken});
  Future<void> clear();
}
```

```dart
// data/services/secure_token_store.dart — the only file importing the package
class SecureTokenStore implements TokenStore {
  SecureTokenStore()
      : _storage = const FlutterSecureStorage(
          // Off backups, off other devices, still readable after first unlock
          // so a background token refresh can run.
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  final FlutterSecureStorage _storage;
  static const _refreshKey = 'auth.refresh_token';

  @override
  Future<String?> refreshToken() => _storage.read(key: _refreshKey);

  @override
  Future<void> save({required String refreshToken}) =>
      _storage.write(key: _refreshKey, value: refreshToken);

  @override
  Future<void> clear() => _storage.deleteAll();
}
```

```dart
// main.dart — the Keychain outlives an iOS uninstall; shared_preferences does not.
Future<void> clearCredentialsOnFreshInstall(SharedPreferences prefs, TokenStore tokens) async {
  if (prefs.getBool('installed') ?? false) return;
  await tokens.clear();
  await prefs.setBool('installed', true);
}
```

```dart
// ❌ world-readable on a rooted device        ✅ OS credential store
await prefs.setString('refresh_token', t);   // await tokenStore.save(refreshToken: t);
```

## Common Interview Questions

- Why is `shared_preferences` unsuitable for a refresh token?
- What does the iOS `accessibility` option control, and which would you pick for background refresh?
- Why must you clear the Keychain on first run after a reinstall?
- Why is `--dart-define` not a way to ship a secret?
- What does secure storage *not* protect against?
- Where should the access token live, and why not next to the refresh token?

## AI Implementation Notes

- Never generate a token or PII write to `shared_preferences` — flag it as a Critical finding.
- Always generate the `TokenStore` interface plus the secure implementation, never the package call
  inline in a notifier or repository.
- Always set `accessibility` on iOS options explicitly.
- Verify the current `AndroidOptions` defaults against the package docs before pinning flags — the
  encrypted-store default has shifted across majors.
- iOS counterpart: [`../ios/keychain.md`](../ios/keychain.md).
- Related: [`oauth2.md`](oauth2.md),
  [`../../../standards/security_standards.md`](../../../standards/security_standards.md).
