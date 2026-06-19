# Checklist: Code Review

Baseline pass for the [Code Reviewer](../agents/code_reviewer.md). Tag findings
Critical/High/Medium/Low/Nit; **block on Critical/High**.

## Correctness (Critical/High)

- [ ] Does what the description/acceptance criteria claim.
- [ ] Edge cases handled: empty, nil, boundary, large inputs.
- [ ] Error paths handled; no silent `try?` swallowing.
- [ ] No force-unwraps/force-try on untrusted data (`!`, `try!`, `as!`).
- [ ] Concurrency-safe: no data races; `@MainActor` for UI; actors/locks where shared state exists.
- [ ] Cancellation honored; resources (tasks, observers, files) cleaned up.

## Architecture

- [ ] Layering respected; no DTO/framework leakage across boundaries.
- [ ] Dependencies injected; no new hidden singletons.
- [ ] Single responsibility; no logic added to Views.

## Security

- [ ] No secrets/PII in code, logs, or URLs.
- [ ] Credentials use Keychain; tokens not logged.
- [ ] Input from network/user validated before use.
- [ ] Deep security concerns routed to the [Security Expert](../agents/security_expert.md).

## Tests

- [ ] New logic has deterministic unit tests (success + error paths).
- [ ] Bug fixes include a failing-first regression test.
- [ ] No real network/clock/randomness in tests.

## Readability & Standards

- [ ] Conforms to [`standards/`](../standards/); consistent naming and terminology.
- [ ] No dead/commented-out code; no leftover debug logging.
- [ ] Public APIs and non-obvious logic documented.

## Verdict

- [ ] Verdict recorded: Approve / Approve-with-nits / Request-changes.
- [ ] Every Critical/High finding has a file:line and a concrete fix.
