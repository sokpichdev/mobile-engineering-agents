# Standard: Architecture Standards

The architectural rules every feature follows. Enforced via
[`checklists/architecture_review.md`](../checklists/architecture_review.md) and the
[iOS Architect](../agents/ios_architect.md).

## Layers

Three layers, dependencies pointing inward:

- **Domain** — entities, value objects, use cases, repository **protocols**. Pure Swift, **no
  framework imports**.
- **Data** — repository implementations, data sources (network/db/cache), DTOs + mappers.
- **Presentation** — SwiftUI views + MVVM ViewModels.

```text
Presentation ──▶ Domain ◀── Data
        (depend on protocols defined in Domain)
```

## Hard Rules

- Domain imports **no** UIKit/SwiftUI/URLSession/Core Data.
- Repository protocols live in Domain; implementations in Data.
- DTOs (`Codable` wire models) never appear in Domain or Presentation — map at the Data boundary.
- Business logic lives in **use cases**, not Views or ViewModels.
- ViewModels depend on use cases/protocols, never concrete services or `URLSession`.
- Dependency graph is acyclic (a DAG).

## SOLID

- **S** — one reason to change per type.
- **O** — extend via new types/protocol conformances, not by editing closed code.
- **L** — protocol conformances must be substitutable.
- **I** — small, focused protocols over fat ones.
- **D** — depend on abstractions; inject implementations.

## Folder Structure (per feature)

```text
Feature/
├── Domain/         Entity.swift, UseCase.swift, RepositoryProtocol.swift
├── Data/           DTO.swift, Mapper.swift, RepositoryImpl.swift, DataSource.swift
└── Presentation/   ViewModel.swift, View.swift, Subviews/
```

## Dependency Injection

- Constructor injection via protocols; a single composition root wires the graph.
- No service locators or singletons in business logic.
- Provide `#if DEBUG` preview/test factories with stubs.

## Modularization (when it pays off)

- Split into **Core** (networking, design system, models) + **Feature** modules.
- Features depend on Core, not on each other; keep public API minimal.
- See [`skills/architecture/ios/modularization.md`](../skills/architecture/ios/modularization.md).

## Decision Records

- Record non-obvious architecture decisions with a one-line rationale (lightweight ADR) near
  the code or in the module README.
