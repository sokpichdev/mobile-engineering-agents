# Workflow: Perform a Security Audit

Systematic review against OWASP MASVS. Led by the [Security Expert](../agents/security_expert.md)
with blocking authority.

## Objective

Identify and remediate security weaknesses across storage, transport, auth, crypto, and
platform usage, mapped to OWASP MASVS with severities.

## Inputs

- Scope (whole app or a module), threat model/sensitivity level, target MASVS level.

## Outputs

- A findings report (severity + MASVS control + remediation) and remediated Critical/High issues.

## Step-by-Step Process

1. **Scope + threat model** — what data is sensitive, who the adversary is, target MASVS level.
2. **Storage** — scan for secrets/tokens/PII in `UserDefaults`, plists, files, logs; verify
   Keychain usage (see [`skills/security/ios/keychain.md`](../skills/security/ios/keychain.md)).
3. **Transport** — TLS enforced; pinning for sensitive hosts; no arbitrary-loads exceptions
   (see [`skills/security/ios/ssl_pinning.md`](../skills/security/ios/ssl_pinning.md)).
4. **Auth + session** — OAuth2/PKCE, JWT handling, refresh races, logout clears credentials.
5. **Crypto** — CryptoKit AES-GCM, no homegrown crypto, secure randomness, key storage.
6. **Platform** — pasteboard, screenshots/backups of sensitive data, deep-link auth, jailbreak
   posture as needed.
7. **Logging** — no secrets/PII in logs.
8. **Report + remediate** — score each finding; block on Critical/High; verify fixes; re-run
   [`checklists/security_review.md`](../checklists/security_review.md).

## Validation Steps

- Each finding maps to a MASVS control with a severity and remediation.
- Critical/High findings are fixed and re-verified.
- A grep/static pass shows no secrets in storage or logs.

## Failure Scenarios

- **Secret found in source/storage** → rotate the secret, remove, and add a lint/CI guard.
- **No pinning on sensitive API** → add SPKI pinning with backup + rotation plan.
- **Crypto misuse** → replace with vetted primitives; add known-answer tests.
- **Policy/compliance ambiguity** → escalate to the human owner.

## AI Agent Instructions

- Treat Critical/High findings as blocking; never wave them through.
- Map every finding to MASVS with severity and a concrete fix.
- Prefer automatable checks (grep/lint/tests) so issues can't silently return.
- Never log or echo any secret you discover.

## Acceptance Criteria

- [ ] Scope + threat model documented; MASVS level chosen.
- [ ] Storage/transport/auth/crypto/platform/logging reviewed.
- [ ] Findings mapped to MASVS with severity + remediation.
- [ ] Critical/High remediated and re-verified.
- [ ] `checklists/security_review.md` passes.
