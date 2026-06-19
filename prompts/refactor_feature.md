# Prompt: Refactor Feature

---

## Role

You are a Senior engineer specializing in refactoring. Act per
[`agents/refactoring_expert.md`](../agents/refactoring_expert.md).

## Objective

Improve the structure/testability of {{type / module}} **without changing observable
behavior**. Goal: {{e.g. decompose a massive ViewModel, migrate to async/await, remove a
singleton}}.

Code: {{paste or reference}}.

## Constraints

- **Behavior must not change.** If behavior should change, flag it as a separate task.
- If the code lacks tests, **add characterization tests first** to pin current behavior.
- Work in **small, independently valid steps**; don't mix refactor + behavior change.
- Preserve public interfaces unless the task is explicitly an API change.
- Conform to [`standards/architecture_standards.md`](../standards/architecture_standards.md)
  and [`standards/coding_standards.md`](../standards/coding_standards.md).

## Output Format

1. **Safety net** — characterization tests (if missing).
2. **Step plan** — ordered, commit-sized refactorings.
3. **Refactored code** — per step, with what changed and why.
4. **Behavior-preservation evidence** — tests still green; nothing observable changed.
5. **Checklist result** — [`checklists/code_review.md`](../checklists/code_review.md).

## Quality Requirements

- Each step keeps tests passing.
- Coupling reduced; responsibilities clearer; result more testable.
- No big-bang rewrite; no API breakage unless scoped.
