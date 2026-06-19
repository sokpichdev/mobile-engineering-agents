# Contributing

Thanks for helping build the definitive AI-first mobile engineering toolkit. The value
of this repository depends on **consistency** — every file should feel like it came from
the same senior engineering team.

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

## Pull Requests

- Keep PRs scoped to one area (e.g. "add storage skills", not "misc updates").
- Update the relevant directory `README.md` index when adding a file.
- Verify cross-links resolve (`workflows/` references should point to real files).
- Run the docs CI locally if possible: `npx markdownlint-cli2 '**/*.md'`.
- Follow [`standards/git_standards.md`](standards/git_standards.md) for commits and PR
  descriptions.

## Adding a New Agent or Skill

1. Copy the section template above.
2. Cross-link related agents/skills/workflows.
3. Add an entry to the directory `README.md` and, for agents, to the table in
   [`README.md`](README.md) and routing in [`AGENTS.md`](AGENTS.md).
