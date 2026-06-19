# Workflow: Conduct a Code Review

Led by the [Code Reviewer](../agents/code_reviewer.md). Produces a prioritized, actionable verdict.

## Objective

Evaluate a change for correctness, security, architecture fit, and test adequacy; deliver a
clear verdict with severity-tagged, actionable feedback.

## Inputs

- The diff/PR, its stated intent, and acceptance criteria.
- Relevant context (linked issue, design notes).

## Outputs

- A review with findings (Critical/High/Medium/Low/Nit) and a verdict:
  Approve / Approve-with-nits / Request-changes.

## Step-by-Step Process

1. **Understand intent** — read the description and acceptance criteria first.
2. **Correctness pass** — edge/error/empty/boundary cases, concurrency, resource cleanup.
3. **Architecture pass** — layering respected, DTOs/framework not leaked, DI used, SRP.
4. **Security pass** — secrets/PII, auth, input handling; route deep concerns to
   [Security Expert](../agents/security_expert.md).
5. **Tests pass** — coverage matches risk; deterministic; bug fixes include regression tests.
6. **Readability/standards** — consistency with [`standards/`](../standards/); naming; dead code.
7. **Summarize** — prioritize findings; separate "must fix" from nits; give the verdict.

## Validation Steps

- Every Critical/High finding has a location and a concrete fix.
- The change is evaluated against its acceptance criteria, not just in isolation.
- Style preferences not in `standards/` are labeled as nits.

## Failure Scenarios

- **Can't understand the code** → that's a finding; request clarification/refactor.
- **No tests for risky logic** → Request-changes.
- **Scope creep in the PR** → ask to split.
- **Security ambiguity** → escalate; block until resolved.

## AI Agent Instructions

- Use [`checklists/code_review.md`](../checklists/code_review.md) as the baseline.
- Prioritize by severity; block on Critical/High; be specific (file:line + why + fix).
- Don't bikeshed style while missing correctness/security issues.
- Verify tests exist and are deterministic before approving.

## Acceptance Criteria

- [ ] Findings prioritized by severity with locations + fixes.
- [ ] Correctness, architecture, security, and tests all assessed.
- [ ] Verdict issued; Critical/High block merge.
- [ ] `checklists/code_review.md` applied.
