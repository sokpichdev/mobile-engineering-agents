---
platform: ios
---

# Skill: AES Encryption

## Overview

AES is the standard symmetric cipher for encrypting data at rest. On iOS, use **Apple
CryptoKit** with **AES-GCM**, which provides both confidentiality and integrity
(authenticated encryption). Never roll your own crypto, never use ECB mode, never reuse a
nonce/IV, and store keys in the Keychain or derive them from the Secure Enclave. For most
"encrypt this blob" needs, AES-GCM with a per-message random nonce is the right default.

## Use Cases

- Encrypting cached sensitive data, local files, or a local database blob.
- Protecting exported/backed-up data.
- Wrapping data before storing outside the Keychain.

## Best Practices

- Use **AES-GCM** (authenticated). Generate a **fresh random nonce per encryption**.
- Generate keys with **`SymmetricKey(size: .bits256)`**; store in Keychain or use Secure Enclave.
- Derive keys from passwords with a **KDF** (HKDF/PBKDF2) — never use a raw password as a key.
- Verify the **authentication tag** on decryption (CryptoKit does this; handle the thrown error).
- Keep crypto in a small, **tested** module with known-answer tests.

## Anti-Patterns

- ❌ Custom/"XOR" encryption or unauthenticated modes (ECB/CBC without a MAC).
- ❌ Reusing a nonce/IV across messages (catastrophic for GCM).
- ❌ Hardcoding keys in source or storing them next to the ciphertext.
- ❌ Using a user password directly as an AES key.
- ❌ Ignoring decryption (tag verification) failures.

## Checklist

- [ ] AES-GCM via CryptoKit; fresh random nonce per message.
- [ ] 256-bit keys stored in Keychain / Secure Enclave.
- [ ] Password-derived keys use a KDF with a salt.
- [ ] Auth tag verified; decryption errors handled.
- [ ] Crypto isolated and covered by known-answer tests.

## Swift Examples

```swift
import CryptoKit

enum Crypto {
    static func newKey() -> SymmetricKey { SymmetricKey(size: .bits256) }

    static func encrypt(_ plaintext: Data, with key: SymmetricKey) throws -> Data {
        let sealed = try AES.GCM.seal(plaintext, using: key)   // random nonce per call
        guard let combined = sealed.combined else { throw CryptoError.encryptionFailed }
        return combined                                        // nonce + ciphertext + tag
    }

    static func decrypt(_ combined: Data, with key: SymmetricKey) throws -> Data {
        let box = try AES.GCM.SealedBox(combined: combined)
        return try AES.GCM.open(box, using: key)               // throws if tag invalid
    }

    /// Derive a key from a password using HKDF + a stored random salt.
    static func deriveKey(password: String, salt: Data) -> SymmetricKey {
        let ikm = SymmetricKey(data: Data(password.utf8))
        return HKDF<SHA256>.deriveKey(inputKeyMaterial: ikm, salt: salt, outputByteCount: 32)
    }
}

enum CryptoError: Error { case encryptionFailed }
```

## Common Interview Questions

- Why AES-GCM over AES-CBC/ECB?
- What happens if you reuse a GCM nonce?
- Why must you not use a password directly as a key?
- Where do you store the encryption key on iOS?
- What does the authentication tag protect against?

## AI Implementation Notes

- Default to CryptoKit AES-GCM with a per-message random nonce; never ECB or homegrown crypto.
- Store keys in Keychain/Secure Enclave; derive password keys via HKDF/PBKDF2 with a salt.
- Generate known-answer tests for the crypto module.
- Related: [`keychain.md`](keychain.md),
  [`../../../standards/security_standards.md`](../../../standards/security_standards.md).
