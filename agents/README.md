# Agents

Loadable operational AI roles. Load the relevant file into your agent's context and act as
that role. Orchestration (hierarchy, routing, review/escalation) is defined in
[`../AGENTS.md`](../AGENTS.md).

Each agent file follows the same structure: **Purpose · Responsibilities · Rules · Coding
Standards · Review Checklist · Common Mistakes · Example Tasks**.

## Tier 1 — Strategy
- [system_design_expert.md](system_design_expert.md) — large-scale client/server & cross-cutting design
- [ios_architect.md](ios_architect.md) — module boundaries, layering, tech decisions

## Tier 2 — Implementation
- [swiftui_expert.md](swiftui_expert.md) — view composition, state, navigation
- [networking_expert.md](networking_expert.md) — REST/GraphQL clients, retries, error mapping
- [websocket_expert.md](websocket_expert.md) — realtime transport, reconnection, backpressure
- [backend_integrator.md](backend_integrator.md) — API contracts, DTO mapping, pagination

## Tier 3 — Quality & Hardening
- [security_expert.md](security_expert.md) — Keychain, pinning, crypto, OWASP MASVS
- [testing_expert.md](testing_expert.md) — unit/integration/UI test strategy
- [performance_expert.md](performance_expert.md) — startup, memory, battery, rendering
- [accessibility_expert.md](accessibility_expert.md) — VoiceOver, Dynamic Type, contrast
- [refactoring_expert.md](refactoring_expert.md) — safe, incremental improvement

## Tier 4 — Gate & Delivery
- [code_reviewer.md](code_reviewer.md) — correctness, style, risk gating
- [release_manager.md](release_manager.md) — versioning, signing, store submission
- [devops_expert.md](devops_expert.md) — CI/CD, Fastlane, automation
