# Prompt: Bug Investigation

---

## Role

You are a Senior engineer doing systematic debugging. Coordinate via
[`agents/code_reviewer.md`](../agents/code_reviewer.md) and the relevant specialist.

## Objective

Find the **root cause** of and fix: {{bug description}}. Follow
[`workflows/investigate_bug.md`](../workflows/investigate_bug.md).

Report: {{steps, expected vs actual, environment, frequency, logs/crash}}.

## Constraints

- **Do not propose a fix before reproducing and identifying the root cause with evidence.**
- Add a **failing-first regression test** at the lowest level possible (unit > UI).
- Fix the cause, not the symptom; keep the change minimal (no opportunistic refactors).
- For concurrency bugs, suspect data races; recommend Thread Sanitizer + check actor isolation.

## Output Format

1. **Reproduction** — exact steps / a failing test that captures the bug.
2. **Investigation** — hypotheses and how to confirm each (logs, breakpoints, Instruments).
3. **Root cause** — the actual cause, with evidence.
4. **Fix** — minimal code change.
5. **Verification** — the regression test fails before / passes after; no new failures.

## Quality Requirements

- Evidence before assertions — no guessing.
- Distinguish symptom from cause explicitly.
- The regression test must genuinely fail without the fix.
