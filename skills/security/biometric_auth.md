# Skill: Biometric Authentication

## Overview

Biometric authentication (Face ID / Touch ID) uses `LocalAuthentication` to gate access to
sensitive features or secrets. The strongest pattern is to bind biometrics to the
**Keychain** via `SecAccessControl` (`.biometryCurrentSet`/`.userPresence`) so the OS — not
your app code — enforces access; a secret is only released after a successful biometric
check. Always provide a **passcode/PIN fallback** and handle the case where biometrics are
unavailable, locked out, or re-enrolled.

## Use Cases

- App lock / re-auth for sensitive screens (payments, settings).
- Releasing a Keychain-stored token or key only after biometric verification.
- Step-up authentication for high-risk actions.

## Best Practices

- **Bind to Keychain** with `SecAccessControl` so the secret is gated by the OS, not a UI flag.
- Use **`.biometryCurrentSet`** to invalidate when biometrics are re-enrolled (security event).
- Always offer a **fallback** (device passcode / app PIN); never lock the user out entirely.
- Check **`canEvaluatePolicy`** first and handle `LAError` cases (lockout, not enrolled, cancel).
- Add a clear, localized **reason string**; never store the biometric data yourself (you can't).

## Anti-Patterns

- ❌ Using a boolean "didAuthenticate" flag with the secret stored unprotected (bypassable).
- ❌ No fallback when biometrics fail/unavailable.
- ❌ Ignoring re-enrollment (a new fingerprint should re-gate sensitive data).
- ❌ Treating biometric success as identity proof to the server without server-side auth.
- ❌ Blocking the main thread during evaluation.

## Checklist

- [ ] Sensitive secrets gated via Keychain `SecAccessControl`, not just a UI flag.
- [ ] `.biometryCurrentSet` (or justified alternative) used.
- [ ] Passcode/PIN fallback present.
- [ ] `canEvaluatePolicy` checked; `LAError` cases handled.
- [ ] Clear localized reason; evaluation off the main thread.

## Swift Examples

```swift
import LocalAuthentication

func authenticate(reason: String) async throws {
    let context = LAContext()
    context.localizedFallbackTitle = "Use Passcode"
    var error: NSError?
    guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
        throw BiometricError.unavailable(error)
    }
    let success = try await context.evaluatePolicy(
        .deviceOwnerAuthentication,           // biometrics with passcode fallback
        localizedReason: reason)
    guard success else { throw BiometricError.failed }
}
```

```swift
// Stronger: store a secret that the OS only releases after a biometric check.
func storeBiometricProtected(_ data: Data, account: String, service: String) throws {
    let access = SecAccessControlCreateWithFlags(
        nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        .biometryCurrentSet, nil)!
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: account,
        kSecValueData as String: data,
        kSecAttrAccessControl as String: access
    ]
    SecItemDelete(query as CFDictionary)
    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else { throw KeychainError.status(status) }
}
```

## Common Interview Questions

- How do you bind a secret to biometric authentication securely?
- Why is a boolean "authenticated" flag insufficient?
- What does `.biometryCurrentSet` protect against?
- How do you handle biometric lockout / not-enrolled states?
- Can the app access raw biometric data? (No.)

## AI Implementation Notes

- Prefer Keychain `SecAccessControl` gating over app-side flags.
- Always implement a passcode/PIN fallback and handle `LAError` cases.
- Use `.biometryCurrentSet` to invalidate on re-enrollment; localize the reason.
- Related: [`keychain.md`](keychain.md),
  [`../../checklists/security_review.md`](../../checklists/security_review.md).
