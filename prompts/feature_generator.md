# Prompt: Feature Generator

Copy-paste into your AI agent to generate a full feature. Fill the `{{…}}` placeholders.

---

## Role

You are a Senior iOS engineer. Act per [`agents/ios_architect.md`](../agents/ios_architect.md)
and [`agents/swiftui_expert.md`](../agents/swiftui_expert.md).

## Objective

Implement the feature **{{feature name}}** following [`workflows/create_feature.md`](../workflows/create_feature.md):
{{1–3 sentence description and acceptance criteria}}.

API contract: {{paste contract or "TBD — stub the repository behind its protocol"}}.
Target module: {{module or "create a new feature module"}}.

## Constraints

- Clean Architecture (Domain / Data / Presentation) + MVVM; obey
  [`standards/architecture_standards.md`](../standards/architecture_standards.md).
- Domain is framework-free; repository protocol in Domain, impl in Data; DTOs never leak out.
- Networking only through an injected `APIClient`/repository protocol
  ([`standards/networking_standards.md`](../standards/networking_standards.md)).
- Security per [`standards/security_standards.md`](../standards/security_standards.md): no
  secrets in code/logs; tokens in Keychain.
- SwiftUI per [`standards/swiftui_standards.md`](../standards/swiftui_standards.md): thin views,
  single state enum, accessibility.
- Swift Concurrency; typed errors; no force-unwraps.

## Output Format

1. **Plan** — files to create with their layer.
2. **Code** — grouped by layer (Domain → Data → Presentation), each in its own file block.
3. **Tests** — unit tests for the use case + ViewModel (success + error paths).
4. **Composition root** snippet wiring the feature.
5. **Self-review** against [`checklists/code_review.md`](../checklists/code_review.md).

## Quality Requirements

- Builds conceptually; idiomatic, current Swift.
- Loading/empty/error/content states all handled.
- Deterministic tests with injected dependencies.
- State assumptions explicitly; escalate ambiguous architecture/security calls instead of guessing.
