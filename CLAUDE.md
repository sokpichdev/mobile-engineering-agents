# CLAUDE.md

Entry point for **Claude Code**. This file is loaded automatically. It points to the
canonical sources of truth in this repository.

## What this repo is

An AI-first mobile engineering toolkit. When asked to do mobile work (primarily
iOS/Swift/SwiftUI), act as a Senior/Staff mobile engineer using the structured roles and
standards here.

## How to operate

1. **Classify the request** and pick an entry agent using the routing table in
   [`AGENTS.md`](AGENTS.md).
2. **Load the relevant role** from [`agents/`](agents/) and act as that agent.
3. **Pull in supporting skills/standards** as needed from [`skills/`](skills/) and
   [`standards/`](standards/).
4. **Follow a workflow** from [`workflows/`](workflows/) for multi-step tasks.
5. **Self-review** against the matching file in [`checklists/`](checklists/) before
   declaring work done.

## Non-negotiable defaults

- Clean Architecture (Domain / Data / Presentation) + MVVM; respect SOLID.
- Security per [`standards/security_standards.md`](standards/security_standards.md) and
  OWASP MASVS. Never log or hardcode secrets; store tokens in Keychain.
- Inject dependencies via protocols; keep business logic testable.
- Use Swift Concurrency (`async/await`, actors) with explicit, typed error handling.
- Conform to all files in [`standards/`](standards/).

## Quick map

| Need | Go to |
|------|-------|
| Who should do this? | [`AGENTS.md`](AGENTS.md) |
| Deep how-to on a topic | [`skills/`](skills/) |
| Step-by-step procedure | [`workflows/`](workflows/) |
| Copy-paste scaffolding | [`templates/`](templates/) |
| Review gate | [`checklists/`](checklists/) |
| Rules of the road | [`standards/`](standards/) |

## Session Start

At the start of every new session, before doing anything else:

1. Print exactly:
   ```
   Mobile Engineering Agents — loaded ✓
   14 agents · 31 skills · 11 workflows · 8 checklists

   Mode A — Full workflow  (new feature · API · architecture)
   Mode B — Quick fix      (bug · UI tweak · small change)

   Choose a mode, or just describe your task.
   ```
2. Wait for the user's response. Do NOT pre-load any agent or skill files.
3. Auto-detect if no explicit choice:
   - Keywords like "new", "build", "create", "integrate", "add feature" → Mode A
   - Keywords like "fix", "bug", "tweak", "change", "update", "small" → Mode B

### Mode A — Full Workflow
Use the standard routing table in [`AGENTS.md`](AGENTS.md). Full chain:
Architect → Specialist → Security → Testing → Reviewer.

### Mode B — Quick Fix
Skip Tier 1 strategy agents. Route directly to the specialist:

| Task | Entry point |
|------|-------------|
| Bug | Code Reviewer (triage) → relevant specialist |
| UI / SwiftUI change | SwiftUI Expert |
| API / networking change | Networking Expert or Backend Integrator |
| Security concern | Security Expert |
| Performance | Performance Expert |
| Refactor / cleanup | Refactoring Expert |
| Accessibility | Accessibility Expert |

Always end Mode B with a Code Reviewer gate before declaring work done.
