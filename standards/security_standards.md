# Standard: Security Standards

Security baseline aligned with **OWASP MASVS**. Enforced via
[`checklists/security_review.md`](../checklists/security_review.md) and the
[Security Expert](../agents/security_expert.md), who has blocking authority.

## Credential Storage (MASVS-STORAGE)

- Secrets/tokens/keys live in **Keychain only** — never `UserDefaults`, plists, files, or source.
- Use least-permissive accessibility (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` or
  stricter); `...ThisDeviceOnly` to keep secrets out of backups/iCloud.
- Gate high-value secrets with biometrics via `SecAccessControl`.
- Clear credentials and sensitive caches on logout.

## Transport (MASVS-NETWORK)

- TLS enforced; **no** `NSAllowsArbitraryLoads` or disabled certificate validation.
- Public-key (SPKI) pinning on sensitive endpoints, with a backup pin + rotation plan.
- No tokens/PII in URLs or query strings.

## Authentication (MASVS-AUTH)

- OAuth2 **Authorization Code + PKCE**; no implicit flow; no embedded client secret.
- Login via `ASWebAuthenticationSession`, not `WKWebView`.
- Validate `state`; enforce JWT `exp` with skew; single-flight token refresh.
- Don't make authorization decisions from unverified client-side JWT claims.

## Cryptography (MASVS-CRYPTO)

- Use CryptoKit/platform primitives — **never** homegrown crypto.
- AES-**GCM** (authenticated); fresh random nonce per message; no ECB/static IV.
- Secure randomness (`SecRandomCopyBytes`/CryptoKit); derive password keys via a KDF (HKDF/PBKDF2)
  with a salt.

## Platform & Privacy (MASVS-PLATFORM)

- Don't expose sensitive data via pasteboard, screenshots, or unencrypted backups.
- Deep links must not grant access without server-side authorization.
- Keep the privacy manifest and App Privacy declarations accurate.

## Logging

- Use `os.Logger` privacy levels; **never** log secrets/PII. No full request/response bodies
  containing credentials.

## Secrets in the Repo

- No API keys/secrets committed. Use `.xcconfig`/CI secret store; `.gitignore` blocks
  `*.env`, `*.p8`, `*.p12`, `GoogleService-Info.plist`, etc.
- Add a CI/lint guard so secrets can't silently reappear.

## Reference

OWASP MASVS: <https://mas.owasp.org/MASVS/> · MASTG: <https://mas.owasp.org/MASTG/>
