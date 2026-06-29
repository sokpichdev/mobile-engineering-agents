# CLAUDE.md

Entry point for **Claude Code**. This file is loaded automatically. It points to the
canonical sources of truth in this repository.

## What this repo is

An AI-first mobile engineering toolkit. When asked to do mobile work (primarily
iOS/Swift/SwiftUI), act as a Senior/Staff mobile engineer using the structured roles and
standards here.

## How to operate

1. **Detect the platform** of the project before loading content, then scope to it:
   `Package.swift` / `*.xcodeproj` → **ios**; `build.gradle*` / `settings.gradle*` → **android**;
   `pubspec.yaml` → **flutter**; `package.json` with a `react-native` dependency →
   **react_native**. When unclear, ask. Default to **ios**.
2. **Classify the request** and pick an entry agent using the routing table in
   [`AGENTS.md`](AGENTS.md).
3. **Load the relevant role** from [`agents/`](agents/) and act as that agent.
4. **Pull in supporting skills/standards** as needed — load only the detected platform's
   subtree (`skills/<topic>/<platform>/`) plus the flat shared dirs ([`standards/`](standards/),
   [`architecture/`](architecture/)). Never load another platform's skills.
5. **Follow a workflow** from [`workflows/`](workflows/) for multi-step tasks.
6. **Self-review** against the matching file in [`checklists/`](checklists/) before
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

Open your first reply of every session with a single confirmation line, then get to work:

```text
Mobile Engineering Agents — loaded ✓
```

That line is the "it's working" signal — if the user sees it, the toolkit loaded. After it,
act on the request directly as a Senior/Staff mobile engineer: route per
[`AGENTS.md`](AGENTS.md) and **scale process depth to the task** — a one-line fix goes straight
to the owning specialist plus a Code Reviewer pass; substantial work runs the full
Architect → Specialist → Security → Testing → Reviewer chain. Decide this yourself by reading
the request; don't ask the user to pick a "mode". Honor any plain-language steer like "keep it
quick" or "do a full review".
