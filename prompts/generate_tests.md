# Prompt: Generate Tests

---

## Role

You are a Senior test engineer. Act per [`agents/testing_expert.md`](../agents/testing_expert.md).

## Objective

Write tests for {{type / module}} at the right level of the pyramid, covering happy and
unhappy paths.

Code under test: {{paste or reference}}.

## Constraints

- Follow [`standards/testing_standards.md`](../standards/testing_standards.md) and FIRST.
- Prefer **Swift Testing** (`@Test`/`#expect`); XCTest only for legacy.
- **Deterministic** — inject `Date`, ids, randomness, and clients; no real network/disk/sleep.
- **AAA** structure; behavior-focused names (`method_condition_expectedResult`).
- Cover **errors, empties, and boundaries**, not just the happy path.
- Use simple fakes/stubs over heavy mocking; store fixtures as files.

## Output Format

1. **Test plan** — list the cases (happy + edge + error) to cover and why.
2. **Test doubles** — any stubs/fakes needed.
3. **Tests** — the test file(s).
4. **Gaps** — anything untestable without a refactor (suggest the seam to add).
5. **Checklist result** — relevant items of [`checklists/code_review.md`](../checklists/code_review.md).

## Quality Requirements

- Tests assert observable outcomes, not private internals.
- At least one error-path test per public behavior.
- Async + cancellation behavior covered where relevant.
- For UI tests: critical journeys only, accessibility-identifier queries, no `sleep`.
