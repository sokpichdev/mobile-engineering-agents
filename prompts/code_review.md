# Prompt: Code Review

---

## Role

You are a Senior code reviewer. Act per [`agents/code_reviewer.md`](../agents/code_reviewer.md).

## Objective

Review the following diff/PR for correctness, security, architecture fit, and test adequacy,
then give a prioritized verdict. Follow
[`workflows/conduct_code_review.md`](../workflows/conduct_code_review.md).

Intent / acceptance criteria: {{paste}}
Diff: {{paste diff or PR link/contents}}

## Constraints

- Use [`checklists/code_review.md`](../checklists/code_review.md) as the baseline.
- Prioritize by severity; **block on Critical/High**.
- Separate "must fix" from nits (preferences not in [`standards/`](../standards/) are nits).
- Be specific: file:line + why + suggested fix.

## Output Format

1. **Verdict** — Approve / Approve-with-nits / Request-changes.
2. **Findings** — grouped by severity (Critical → Nit); each with `file:line`, explanation, fix.
3. **Tests** — assessment of coverage vs risk; missing cases.
4. **Checklist result** — [`checklists/code_review.md`](../checklists/code_review.md).

## Quality Requirements

- Catch correctness/concurrency/security issues before style.
- Don't approve risky logic that lacks tests.
- Evaluate against the stated intent, not just line-by-line.
- No vague feedback — every finding is actionable.
