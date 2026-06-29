---
platform: ios
---

# Skill: Modularization

## Overview

Modularization splits an app into independently buildable units (Swift Packages or
frameworks) with explicit public interfaces and one-directional dependencies. Done well, it
improves build times (incremental + parallel), enforces boundaries the compiler can check,
enables team ownership, and makes features reusable. Done poorly, it creates a tangle of
cross-dependencies that's worse than a monolith. Modularize along **feature** and **layer**
seams, not arbitrarily.

## Use Cases

- Apps large enough that build times or merge conflicts hurt productivity.
- Multiple teams owning distinct features.
- Sharing a core (networking, design system) across app + extensions (widgets, watch).

## Best Practices

- Split into **Core** (foundational: networking, design system, models) and **Feature**
  modules; features depend on core, never on each other directly.
- Keep **public surface minimal**; default to `internal`, expose only what's needed.
- Enforce **acyclic dependencies** (the package graph is a DAG).
- Route inter-feature communication through **abstractions** (protocols in a shared module)
  or a coordinator, not direct imports.
- Co-locate each module's tests with the module.

## Anti-Patterns

- ❌ A "Common"/"Utils" module everything depends on that becomes a dumping ground.
- ❌ Feature modules importing each other directly (coupling + cycles).
- ❌ Over-modularizing a small app into dozens of tiny packages.
- ❌ Exposing internals as `public` "just in case."
- ❌ Circular package dependencies (won't compile / fragile).

## Checklist

- [ ] Package graph is acyclic; dependencies point toward Core.
- [ ] Features don't import each other directly.
- [ ] Public API is minimal and intentional.
- [ ] Shared code is cohesive, not a catch-all "Utils".
- [ ] Each module owns its tests.

## Swift Examples

```swift
// Package.swift for a feature module depending on shared cores
let package = Package(
    name: "AccountsFeature",
    platforms: [.iOS(.v16)],
    products: [.library(name: "AccountsFeature", targets: ["AccountsFeature"])],
    dependencies: [
        .package(path: "../CoreNetworking"),
        .package(path: "../DesignSystem"),
        .package(path: "../CoreModels")
    ],
    targets: [
        .target(name: "AccountsFeature",
                dependencies: ["CoreNetworking", "DesignSystem", "CoreModels"]),
        .testTarget(name: "AccountsFeatureTests", dependencies: ["AccountsFeature"])
    ]
)
```

```text
Dependency direction (DAG):
App ──▶ AccountsFeature ──▶ CoreNetworking ──▶ CoreModels
    └─▶ PaymentsFeature  ──▶ DesignSystem
(no Feature ──▶ Feature edges)
```

## Common Interview Questions

- How do you decide module boundaries (feature vs layer)?
- How do two features communicate without depending on each other?
- What problems do circular package dependencies cause?
- How does modularization affect build and test times?
- What's the risk of a shared "Common" module?

## AI Implementation Notes

- Propose a Core/Feature split; keep the dependency graph a DAG pointing toward Core.
- Default new symbols to `internal`; only mark `public` what crosses a module boundary.
- For cross-feature needs, generate a protocol in a shared module rather than a direct import.
- Related: [`clean_architecture.md`](clean_architecture.md),
  [`../../../architecture/feature_module_architecture.md`](../../../architecture/feature_module_architecture.md).
