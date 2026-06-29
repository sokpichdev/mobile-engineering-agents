# Workflow: Create a Feature

End-to-end procedure for building a new feature with proper architecture, security, and tests.

## Objective

Deliver a production-ready feature implemented in Clean Architecture + MVVM, secured,
tested, and reviewed — from requirement to merge-ready PR.

## Inputs

- Feature requirement / user story with acceptance criteria.
- Relevant API contract(s) or a note that they're TBD.
- Target module (or a decision to create one).

## Outputs

- New/updated module with Domain, Data, Presentation layers.
- Unit tests (and UI test for critical journeys).
- Self-review against the checklists; a merge-ready change.

## Step-by-Step Process

1. **Architect** ([iOS Architect](../agents/ios_architect.md)) — define entities, use cases,
   repository protocols, module placement, and DI wiring. Produce a short architecture brief.
2. **Domain** — implement entities + use cases (pure, framework-free) with unit tests first
   ([TDD](../skills/testing/ios/unit_testing.md)).
3. **Data** ([Networking](../agents/networking_expert.md)/[Backend Integrator](../agents/backend_integrator.md))
   — implement DTOs, mappers, and the repository against the API contract.
4. **Presentation** ([SwiftUI Expert](../agents/swiftui_expert.md)) — build the ViewModel
   (state enum) and View; handle loading/empty/error/content.
5. **Security** ([Security Expert](../agents/security_expert.md)) — review any sensitive data,
   tokens, or new network calls.
6. **Accessibility** ([Accessibility Expert](../agents/accessibility_expert.md)) — labels,
   Dynamic Type, identifiers.
7. **Tests** ([Testing Expert](../agents/testing_expert.md)) — fill coverage gaps; add a UI
   test if it's a critical journey.
8. **Review** ([Code Reviewer](../agents/code_reviewer.md)) — final gate against
   [`checklists/code_review.md`](../checklists/code_review.md).

## Validation Steps

- Project builds; all tests pass.
- Acceptance criteria demonstrably met.
- No layering violations (Domain framework-free; DTOs not leaked).
- Security and accessibility checklists pass.

## Failure Scenarios

- **API contract unclear/missing** → stub the repository behind its protocol, mock data, flag
  to backend; proceed on the protocol.
- **Architecture conflict** → escalate to [System Design Expert](../agents/system_design_expert.md).
- **Security finding (Critical/High)** → block; remediate before continuing.
- **Flaky/failing tests** → run [`investigate_bug.md`](investigate_bug.md) before merge.

## AI Agent Instructions

- Follow the agent chain in order; emit a [handoff block](../AGENTS.md#handoff-contract) at
  each step.
- Write tests before/with implementation, not after.
- Do not skip the security and review steps even for "small" features.
- State assumptions explicitly; escalate rather than guess on ambiguity.

## Acceptance Criteria

- [ ] Three layers implemented; dependency rule respected.
- [ ] Use cases + ViewModel unit-tested (success + error paths).
- [ ] Loading/empty/error/content states handled.
- [ ] Security + accessibility checklists pass.
- [ ] Code review verdict is Approve / Approve-with-nits.
