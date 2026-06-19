# Skill: Keychain

## Overview

The Keychain is iOS's secure, encrypted store for small secrets: tokens, passwords, keys.
It's the **only** acceptable place for credentials — never `UserDefaults`, plists, or files.
Access is controlled by **accessibility classes** (when the item is readable) and optional
**access control** (biometrics/passcode). Wrap the C API in a small, tested Swift abstraction
and choose the least-permissive accessibility that still works for your use case.

## Use Cases

- Storing OAuth2 access/refresh tokens and session credentials.
- Storing symmetric keys used for local encryption.
- Persisting a small secret that must survive app restarts but not leak via backups.

## Best Practices

- Use **`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`** for tokens needing background
  access; **`WhenUnlockedThisDeviceOnly`** for stricter cases. `...ThisDeviceOnly` prevents
  iCloud/backups from carrying the secret.
- Add **`SecAccessControl`** with biometrics for high-value secrets.
- **Update-or-add** semantics (delete/add or `SecItemUpdate`) to avoid `errSecDuplicateItem`.
- **Clear all credentials on logout.**
- Wrap in a protocol-backed, **tested** service; never scatter raw `SecItem*` calls.

## Anti-Patterns

- ❌ Storing tokens/keys in `UserDefaults`, plists, or files.
- ❌ Using the default (most permissive) accessibility unnecessarily.
- ❌ Syncing secrets to iCloud when they should be device-only.
- ❌ Ignoring `OSStatus` results.
- ❌ Leaving credentials in the Keychain after logout.

## Checklist

- [ ] Secrets only in Keychain, never `UserDefaults`/files.
- [ ] Least-permissive accessibility chosen; `...ThisDeviceOnly` for non-synced secrets.
- [ ] Biometric access control on high-value items where appropriate.
- [ ] Add/update handled (no duplicate errors); `OSStatus` checked.
- [ ] Credentials cleared on logout.

## Swift Examples

```swift
protocol SecureStore {
    func set(_ data: Data, for key: String) throws
    func get(_ key: String) throws -> Data?
    func remove(_ key: String) throws
}

struct KeychainStore: SecureStore {
    let service: String

    func set(_ data: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var add = query; add.merge(attributes) { _, new in new }
            let addStatus = SecItemAdd(add as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw KeychainError.status(addStatus) }
        } else {
            guard status == errSecSuccess else { throw KeychainError.status(status) }
        }
    }

    func get(_ key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw KeychainError.status(status) }
        return result as? Data
    }

    func remove(_ key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.status(status)
        }
    }
}

enum KeychainError: Error { case status(OSStatus) }
```

## Common Interview Questions

- Why store tokens in the Keychain instead of `UserDefaults`?
- What do the accessibility classes control?
- What does `...ThisDeviceOnly` change?
- How do you require Face ID/Touch ID to read an item?
- How do you avoid `errSecDuplicateItem`?

## AI Implementation Notes

- Always route credentials through a protocol-backed Keychain store; never `UserDefaults`.
- Default accessibility to `...AfterFirstUnlockThisDeviceOnly`; tighten when possible.
- Clear secrets on logout; generate tests using a fake `SecureStore`.
- Related: [`oauth2.md`](oauth2.md), [`jwt.md`](jwt.md), [`biometric_auth.md`](biometric_auth.md).
