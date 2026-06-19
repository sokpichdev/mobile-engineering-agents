# Checklist: Security Review

Maps to OWASP MASVS and [`security_standards.md`](../standards/security_standards.md). Owned by
the [Security Expert](../agents/security_expert.md). **Critical/High block release.**

## Credential Storage (Critical) — MASVS-STORAGE

- [ ] No secrets/tokens/keys in `UserDefaults`, plists, files, or source.
- [ ] Tokens/keys stored in Keychain with least-permissive accessibility (`...ThisDeviceOnly`).
- [ ] High-value secrets gated by biometrics via `SecAccessControl`.
- [ ] Credentials and sensitive caches cleared on logout.
- [ ] Sensitive data excluded from backups/screenshots/pasteboard as appropriate.

## Transport (Critical) — MASVS-NETWORK

- [ ] TLS enforced; no `NSAllowsArbitraryLoads` / disabled validation.
- [ ] Certificate/public-key pinning on sensitive endpoints, with backup pin + rotation plan.
- [ ] No tokens/PII in URLs or query strings.

## Authentication & Session (High) — MASVS-AUTH

- [ ] OAuth2 Authorization Code + PKCE; no implicit flow; no embedded client secret.
- [ ] Login uses `ASWebAuthenticationSession`, not `WKWebView`.
- [ ] `state` validated; JWT `exp` enforced with skew.
- [ ] Single-flight token refresh; no concurrent-refresh race.

## Cryptography (Critical) — MASVS-CRYPTO

- [ ] Uses CryptoKit/platform primitives; no homegrown crypto.
- [ ] AES-GCM (authenticated); fresh random nonce per message; no ECB/static IV.
- [ ] Secure randomness (`SecRandomCopyBytes`/CryptoKit); keys from KDF when password-derived.

## Platform & Logging (Medium/High)

- [ ] No secrets/PII in logs (release builds especially).
- [ ] Deep links don't grant access without server-side authorization.
- [ ] Third-party SDKs reviewed for data exfiltration.

## Reporting

- [ ] Each finding tagged with severity + MASVS control + remediation.
- [ ] Critical/High remediated and re-verified.

## Automation hints

- `grep -rIn "UserDefaults" Sources | grep -i "token\|password\|secret"` → expect none.
- `grep -rn "NSAllowsArbitraryLoads" .` → expect none.
