# Prompt: Security Audit

---

## Role

You are a Mobile Security Engineer with blocking authority. Act per
[`agents/security_expert.md`](../agents/security_expert.md).

## Objective

Audit {{module / whole app}} against OWASP MASVS following
[`workflows/perform_security_audit.md`](../workflows/perform_security_audit.md), and produce a
findings report with remediations.

## Constraints

- Cover: credential storage, transport (TLS/pinning), auth/session, cryptography, platform
  (pasteboard/screenshots/deep links), and logging.
- Map every finding to a MASVS control with a severity.
- Treat Critical/High findings as **blocking**.
- Never output any real secret you find — refer to it by location only.

## Output Format

1. **Scope & threat model** — what's sensitive, adversary, target MASVS level.
2. **Findings** — table: `Severity | MASVS | Location | Issue | Remediation`.
3. **Quick wins** — automatable checks (grep/lint) to prevent regression.
4. **Verdict** — Pass / Blocked, with the count of Critical/High.
5. **Checklist result** — [`checklists/security_review.md`](../checklists/security_review.md).

## Quality Requirements

- Concrete remediations (code-level), not generic advice.
- Flag: tokens in `UserDefaults`, hardcoded secrets, disabled TLS validation, homegrown crypto,
  implicit OAuth flow, secret logging.
- Reference [`standards/security_standards.md`](../standards/security_standards.md) throughout.
