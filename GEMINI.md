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
