# Checklist: Architecture Review

Objective, measurable gates for [`architecture_standards.md`](../standards/architecture_standards.md).
Owned by the [iOS Architect](../agents/ios_architect.md). Block on any unchecked Critical item.

## Layering (Critical)

- [ ] Domain layer has **zero** framework imports (no `URLSession`, Core Data, SwiftUI).
- [ ] Dependencies point inward: Presentation → Domain ← Data; no outward references.
- [ ] Repository protocols defined in Domain; implementations in Data.
- [ ] DTOs (`Codable` wire models) do not appear in Domain or Presentation.
- [ ] No circular dependencies between modules/types (graph is a DAG).

## Responsibilities

- [ ] Each type has a single responsibility (no class with 2+ reasons to change).
- [ ] Business logic lives in use cases, not in Views or ViewModels.
- [ ] ViewModels depend on use cases/protocols, not concrete services.
- [ ] No file exceeds the size thresholds in `.swiftlint.yml` without justification.

## Dependency Injection

- [ ] Dependencies injected via initializers, not constructed internally.
- [ ] Types depend on protocols, not concretes.
- [ ] A single composition root wires the graph.
- [ ] No global singletons reached from business logic.

## Modularity & Evolvability

- [ ] Public API surface is minimal (`internal`/`private` by default).
- [ ] Feature modules don't import each other directly.
- [ ] Non-obvious decisions documented with a one-line rationale.

## Automation hints

- `grep -rn "import UIKit\|import SwiftUI\|URLSession\|NSManagedObject" Sources/Domain` → expect no matches.
- SwiftLint `file_length`, `type_body_length`, `cyclomatic_complexity` enforce size gates.
