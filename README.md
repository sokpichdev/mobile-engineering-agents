# Mobile Engineering Agents

> An AI-first engineering toolkit that turns coding agents into Senior/Staff mobile engineers.

`mobile-engineering-agents` is **not** a tutorial or a handbook. It is a structured,
reusable knowledge system designed to be loaded directly into AI coding agents —
**Claude Code, OpenAI Codex, Cursor, Windsurf, Gemini CLI, and Aider** — so they
produce mobile code that is secure, well-architected, testable, and consistent.

It encodes the judgment of experienced mobile engineers as **agents**, **skills**,
**workflows**, **checklists**, **templates**, **prompts**, **standards**, and
**architecture references**, with a primary focus on **iOS / Swift / SwiftUI** and
secondary coverage of **Android/Kotlin** and **Flutter**.

---

## Project Vision

AI agents are now capable of writing large amounts of mobile code quickly. The
bottleneck is no longer typing speed — it is **engineering judgment**: choosing the
right architecture, handling errors and concurrency correctly, securing data, and
keeping a codebase maintainable as it scales.

This repository supplies that judgment in a machine-loadable form. The goal is that
an agent loaded with these files behaves like a senior engineer who:

- Defaults to **Clean Architecture + MVVM** and **SOLID** principles.
- Treats **security** (OWASP MASVS) as a first-class requirement, not an afterthought.
- Writes **testable**, **modular**, **observable** code with explicit error handling.
- Follows consistent **standards** so generated code looks like one team wrote it.

---

## Repository Structure

```text
mobile-engineering-agents/
├── README.md                  # You are here
├── AGENTS.md                  # Master orchestration: agent hierarchy, routing, review flow
├── CONTRIBUTING.md            # How to contribute and keep content consistent
├── GLOSSARY.md                # Shared terminology
├── CLAUDE.md / GEMINI.md      # Platform auto-load entry points
├── .cursorrules / .windsurfrules
├── .github/                   # copilot-instructions, CI, issue/PR templates
│
├── agents/                    # Loadable operational AI roles (iOS architect, security, …)
├── skills/                    # Deep, single-topic capabilities (auth, websockets, caching, …)
├── workflows/                 # End-to-end procedures (build a feature, integrate an API, …)
├── templates/                 # Copy-paste project scaffolding with boilerplate Swift
├── checklists/                # Objective, automatable review checklists
├── prompts/                   # Production prompts for common engineering tasks
├── examples/                  # Reference apps (banking, chat, ecommerce, social)
├── architecture/              # Architecture references with Mermaid diagrams
└── standards/                 # Coding, security, testing, git standards
```

Each top-level content directory has its own `README.md` index.

---

## Agent System Overview

The toolkit defines **14 specialized agents**. Each is a self-contained operational
role describing its purpose, responsibilities, hard rules, coding standards, review
checklist, common mistakes, and example tasks.

| Agent | Focus |
|-------|-------|
| [iOS Architect](agents/ios_architect.md) | Module boundaries, layering, tech decisions |
| [SwiftUI Expert](agents/swiftui_expert.md) | View composition, state, navigation |
| [Networking Expert](agents/networking_expert.md) | REST/GraphQL clients, retries, error mapping |
| [WebSocket Expert](agents/websocket_expert.md) | Realtime transport, reconnection, backpressure |
| [Security Expert](agents/security_expert.md) | Keychain, pinning, crypto, OWASP MASVS |
| [Backend Integrator](agents/backend_integrator.md) | API contracts, DTO mapping, pagination |
| [Testing Expert](agents/testing_expert.md) | Unit/integration/UI test strategy |
| [Performance Expert](agents/performance_expert.md) | Startup, memory, battery, rendering |
| [Accessibility Expert](agents/accessibility_expert.md) | VoiceOver, Dynamic Type, contrast |
| [Code Reviewer](agents/code_reviewer.md) | Correctness, style, risk gating |
| [Refactoring Expert](agents/refactoring_expert.md) | Safe, incremental code improvement |
| [Release Manager](agents/release_manager.md) | Versioning, signing, store submission |
| [DevOps Expert](agents/devops_expert.md) | CI/CD, Fastlane, automation |
| [System Design Expert](agents/system_design_expert.md) | Large-scale client/server design |

Orchestration — how these agents hand off, review each other, and escalate — is
defined in [AGENTS.md](AGENTS.md).

---

## How to Use

The core idea is the same across every platform: **load the relevant agent, skill,
or workflow file into the model's context, then ask for the task.**

### Claude Code

`CLAUDE.md` at the repo root is loaded automatically. To pull in a specific role:

```text
> Read agents/security_expert.md and act as that agent.
> Then audit Sources/Auth for credential storage issues using checklists/security_review.md.
```

You can also reference workflows directly:

```text
> Follow workflows/integrate_rest_api.md to add the /transactions endpoint.
```

### OpenAI Codex

`AGENTS.md` is read automatically by Codex. Reference files explicitly in your prompt:

```text
Using agents/swiftui_expert.md and standards/swiftui_standards.md, build the
account summary screen described below.
```

### Cursor

`.cursorrules` is applied automatically. For a focused task, add the relevant file to
context (`@agents/networking_expert.md`) and prompt:

```text
@workflows/integrate_graphql.md implement the feed query with pagination.
```

### Windsurf

`.windsurfrules` is applied automatically by Cascade. Reference files in chat the same
way, e.g. `@checklists/code_review.md review the open diff`.

### Gemini CLI

`GEMINI.md` is loaded automatically. Use `@path` to include files:

```text
@agents/testing_expert.md @standards/testing_standards.md write tests for AuthRepository.
```

### Aider

Add files to the chat session:

```bash
aider --read agents/ios_architect.md --read standards/architecture_standards.md
```

---

## Example Workflows

- **Build a feature end-to-end:** [workflows/create_feature.md](workflows/create_feature.md)
- **Integrate a REST API:** [workflows/integrate_rest_api.md](workflows/integrate_rest_api.md)
- **Add realtime with WebSockets:** [workflows/integrate_websocket.md](workflows/integrate_websocket.md)
- **Implement authentication:** [workflows/implement_authentication.md](workflows/implement_authentication.md)
- **Run a security audit:** [workflows/perform_security_audit.md](workflows/perform_security_audit.md)
- **Ship a release:** [workflows/release_application.md](workflows/release_application.md)

A typical multi-agent flow:

```text
Feature Request
  → iOS Architect      (define module + layer boundaries)
  → SwiftUI Expert     (build the UI + state)
  → Networking Expert  (wire the data layer)
  → Security Expert    (review sensitive data handling)
  → Testing Expert     (add unit + UI tests)
  → Code Reviewer      (final gate)
```

---

## Best Practices

1. **Load the smallest sufficient context.** Pull in the specific agent/skill/workflow
   for the task instead of the whole repo.
2. **Chain agents** for non-trivial work (architect → implementer → reviewer).
3. **Always end with a checklist.** Have the agent self-review against the matching
   file in `checklists/`.
4. **Treat standards as non-negotiable.** Reference `standards/` so output stays
   consistent across sessions and contributors.
5. **Prefer workflows over ad-hoc prompts** for repeatable tasks.

---

## Contribution Guidelines

See [CONTRIBUTING.md](CONTRIBUTING.md). In short: keep files focused, follow the
section templates, cross-link instead of duplicating, and use illustrative — not
necessarily compilable — Swift snippets that demonstrate the correct pattern.

---

## Roadmap

- [ ] Kotlin/Compose and Flutter parity for the iOS-first skills.
- [ ] Machine-readable agent manifests (YAML front-matter) for automated routing.
- [ ] Expanded example apps with full test suites.
- [ ] Evaluations that score agent output against the checklists.
- [ ] Optional MCP server exposing skills as callable tools.

---

## License

[MIT](LICENSE).
