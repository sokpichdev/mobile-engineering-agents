# Standard: Git & Workflow Standards

Rules for branching, commits, PRs, and CI. Enforced by the
[DevOps](../agents/devops_expert.md) and [Code Reviewer](../agents/code_reviewer.md).

## Branching

- Trunk-based: short-lived feature branches off `main`.
- Branch naming: `feat/…`, `fix/…`, `chore/…`, `refactor/…`, `docs/…` (e.g. `feat/account-summary`).
- Keep branches small and focused; rebase or merge `main` frequently to avoid drift.

## Commits (Conventional Commits)

- Format: `type(scope): summary` in imperative mood, ≤ 72-char subject.
- Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`, `build`, `ci`.
- Body explains **why**; reference issues (`Closes #123`).
- One logical change per commit; don't mix refactor + behavior change.

```text
feat(auth): add single-flight token refresh

Concurrent requests previously triggered multiple refreshes, invalidating
each other's tokens. Serialize refresh through an actor.

Closes #142
```

## Pull Requests

- Use the [PR template](../.github/PULL_REQUEST_TEMPLATE.md); state intent + acceptance criteria.
- Keep PRs reviewable (ideally < ~400 lines of diff); split large work.
- All CI checks green; at least one approving review; resolve all Critical/High findings.
- Squash-merge to keep `main` history linear and readable (team preference).

## Versioning & Releases

- **Semantic Versioning** `MAJOR.MINOR.PATCH`.
- Tag releases (`v2.4.0`); maintain a changelog.
- Release builds come from tagged commits via CI (see
  [`workflows/release_application.md`](../workflows/release_application.md)).

## CI Requirements

- Every PR runs lint + build + tests; merge is blocked until green.
- Secrets only from the CI secret store — never committed or echoed in logs.
- Pin action/tool versions for reproducibility.

## Hygiene

- Never commit secrets, build artifacts, or `*.p8`/`*.p12`/`GoogleService-Info.plist`
  (`.gitignore` enforces this).
- Don't commit commented-out code or debug logging.
