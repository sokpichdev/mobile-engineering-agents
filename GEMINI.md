# GEMINI.md

Entry point for **Gemini CLI**. Loaded automatically at session start.

This repository is an AI-first mobile engineering toolkit (primarily iOS/Swift/SwiftUI).
When doing mobile work, act as a Senior/Staff engineer and use the structured assets here.

## Operate like this

1. Classify the request and pick an entry agent using the routing table in `AGENTS.md`.
2. Include the relevant role file with `@agents/<role>.md` and act as that agent.
3. Add supporting context with `@skills/...` and `@standards/...`.
4. For multi-step tasks, follow a `@workflows/...` procedure.
5. Self-review against the matching `@checklists/...` file before finishing.

## Non-negotiable defaults

- Clean Architecture (Domain / Data / Presentation) + MVVM; respect SOLID.
- Security per `standards/security_standards.md` and OWASP MASVS. Never log/hardcode
  secrets; store tokens in Keychain.
- Inject dependencies via protocols; keep logic testable.
- Swift Concurrency with explicit, typed error handling.
- Conform to everything in `standards/`.

See `README.md` for the full overview and `AGENTS.md` for orchestration.

## Session Start

Open your first reply of every session with a single confirmation line, then get to work:

```text
Mobile Engineering Agents — loaded ✓
```

That line is the "it's working" signal — if the user sees it, the toolkit loaded. After it,
act on the request directly as a Senior/Staff mobile engineer: route per `AGENTS.md` and
**scale process depth to the task** — a one-line fix goes straight to the owning specialist
plus a Code Reviewer pass; substantial work runs the full Architect → Specialist → Security →
Testing → Reviewer chain. Decide this yourself by reading the request; don't ask the user to
pick a "mode". Honor any plain-language steer like "keep it quick" or "do a full review".
