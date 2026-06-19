# Contributing

Thanks for helping build the definitive AI-first mobile engineering toolkit! Contributions
of all sizes are welcome — fixing a typo, improving a skill, adding an agent, or proposing a
whole new section. The value of this repository depends on **consistency**, so this guide
explains how to keep everything coherent.

New here? Look for issues labeled **good first issue**, or open an issue describing what you'd
like to add before starting larger work.

## How to Contribute

1. **Fork** the repo and create a branch: `git checkout -b feat/<short-name>`.
2. **Set up locally** (see [Local Setup](#local-setup)) so you can validate before pushing.
3. **Make your change**, following the [file section templates](#file-section-templates) and
   [style](#style).
4. **Commit** using the [Conventional Commit format](#commit-convention) — this is enforced in CI.
5. **Validate**: run `npm run lint` and confirm cross-links resolve.
6. **Open a pull request** using the template; fill in the checklist.

## Local Setup

The toolkit is markdown + illustrative Swift, so the only tooling is for docs validation:

```bash
npm install                 # installs markdownlint, link-check, commitlint
npm run lint                # markdown lint + relative/external link check
npm run lint:md:fix         # auto-fix common markdown issues
git config commit.template .gitmessage   # (optional) prefill the commit format
```

CI runs the same checks on every PR, plus commit-message linting, so running them locally
saves a round-trip.

## Principles

1. **AI-first, not human-first.** Write for a coding agent reading the file as context.
   Be explicit, structured, and unambiguous. Prefer rules and checklists over prose.
2. **Focused files.** One file = one role / skill / workflow / topic. If a file covers
   two things, split it.
3. **Cross-link, don't duplicate.** Reference other files with relative links instead of
   repeating content. Duplication drifts out of sync.
4. **Illustrative code.** Swift/SwiftUI snippets demonstrate the correct pattern; they do
   not need to compile as a whole project. Keep them idiomatic and current.
5. **Standards are law.** New content must conform to [`standards/`](standards/).

## File Section Templates

Use the canonical section set for each content type. Do not invent new section names.

| Type | Required sections |
|------|-------------------|
| `agents/*` | Purpose · Responsibilities · Rules · Coding Standards · Review Checklist · Common Mistakes · Example Tasks |
| `skills/*` | Overview · Use Cases · Best Practices · Anti-Patterns · Checklist · Swift Examples · Common Interview Questions · AI Implementation Notes |
| `workflows/*` | Objective · Inputs · Outputs · Step-by-Step Process · Validation Steps · Failure Scenarios · AI Agent Instructions · Acceptance Criteria |
| `checklists/*` | Grouped checkbox items, each objective and measurable |
| `prompts/*` | Role · Objective · Constraints · Output Format · Quality Requirements |
| `standards/*` | Topic-grouped rules with ✅/❌ examples |
| `architecture/*` | Explanation · Mermaid diagram(s) · Data flow · Sample implementation |

## Style

- Markdown with ATX headings (`#`), one `H1` per file.
- Fenced code blocks **must** declare a language (`swift`, `kotlin`, `bash`, `mermaid`, `json`).
- Use `✅` for recommended and `❌` for discouraged examples.
- Keep line length reasonable (~100 chars) for diff readability.
- American English, present tense, imperative voice for instructions.

## Checklist Authoring Rules

Each checklist item must be:

- **Objective** — two reviewers would agree whether it passes.
- **Measurable** — ideally automatable (lint rule, test, grep).
- **Production-focused** — reflects real risk, not style preference (style → `standards/`).

## Commit Convention

All commits **must** follow [Conventional Commits](https://www.conventionalcommits.org/).
CI lints **every commit in a PR** and the **PR title** — non-conforming messages fail the build.

Format:

```text
<type>(<scope>): <subject>

<optional body — explain what and why>

<optional footer — e.g. Closes #123>
```

- **type** (required): `feat` · `fix` · `docs` · `refactor` · `test` · `chore` · `perf` ·
  `build` · `ci` · `revert`
- **scope** (optional): the area touched — common ones: `security`, `networking`, `ui`, `auth`,
  `storage`, `agents`, `skills`, `workflows`, `checklists`, `standards`, `architecture`,
  `prompts`, `templates`, `examples`, `ci`, `repo`.
- **subject** (required): imperative, lower-case, no trailing period, ≤ 100 chars total.

Examples:

```text
feat(security): add public-key TLS pinning with backup pin
fix(networking): map 404 to DomainError.notFound
docs(readme): clarify Cursor setup
chore(repo): add markdown link-check to CI
```

Run `git config commit.template .gitmessage` to prefill the format in your editor, and
`npm run lint:commits` to check your branch's commits before pushing. See
[`standards/git_standards.md`](standards/git_standards.md) for the full convention.

## Pull Requests

- Keep PRs scoped to one area (e.g. "add storage skills", not "misc updates").
- Update the relevant directory `README.md` index when adding a file.
- Verify cross-links resolve (`workflows/` references should point to real files).
- Run the docs checks locally: `npm run lint`.
- Use a Conventional Commit **PR title** (it's linted, and becomes the squash-merge commit).
- Follow [`standards/git_standards.md`](standards/git_standards.md) for commits and PR
  descriptions.

## Adding a New Agent or Skill

1. Copy the section template above.
2. Cross-link related agents/skills/workflows.
3. Add an entry to the directory `README.md` and, for agents, to the table in
   [`README.md`](README.md) and routing in [`AGENTS.md`](AGENTS.md).
