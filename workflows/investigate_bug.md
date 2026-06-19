# Workflow: Investigate a Bug

Systematic debugging — find the root cause with evidence before fixing. Pairs with the
[systematic-debugging](../agents/code_reviewer.md) mindset.

## Objective

Reproduce, diagnose the **root cause** (not the symptom), fix it, and prevent regression with
a test.

## Inputs

- Bug report: steps, expected vs actual, environment, frequency, logs/crash report.

## Outputs

- A reliable reproduction, root-cause explanation, minimal fix, and a regression test.

## Step-by-Step Process

1. **Reproduce reliably** — establish exact steps and a failing case. If you can't reproduce,
   gather more data (logs, device, OS, account state).
2. **Write a failing test** that captures the bug at the lowest possible level (unit > UI).
3. **Form a hypothesis** about the root cause; locate the responsible component.
4. **Confirm with evidence** — logs, breakpoints, Instruments, the memory graph — don't guess.
5. **Fix the root cause** ([Refactoring](../agents/refactoring_expert.md)/relevant specialist),
   keeping the change minimal.
6. **Verify** the failing test now passes and no others regress.
7. **Review** ([Code Reviewer](../agents/code_reviewer.md)) the fix + test.

## Validation Steps

- The regression test fails before the fix and passes after.
- The original reproduction no longer occurs.
- No new failures introduced; the fix addresses cause, not symptom.

## Failure Scenarios

- **Can't reproduce** → add logging/telemetry; narrow environment; consider a flaky/timing issue.
- **Symptom masks cause** → keep tracing inward; don't patch the surface.
- **Heisenbug (timing/concurrency)** → suspect data races; use Thread Sanitizer.
- **Fix breaks other tests** → reassess the hypothesis.

## AI Agent Instructions

- Do **not** propose a fix before reproducing and identifying the root cause with evidence.
- Always add a failing-first regression test at the lowest level.
- Prefer the smallest change that fixes the cause; avoid opportunistic refactors in the same PR.
- For concurrency bugs, enable Thread Sanitizer and review actor/isolation boundaries.

## Acceptance Criteria

- [ ] Reliable reproduction documented.
- [ ] Root cause identified with evidence.
- [ ] Regression test fails before, passes after.
- [ ] Minimal fix; no new regressions.
- [ ] Reviewed and approved.
