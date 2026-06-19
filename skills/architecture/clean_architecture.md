# Skill: Clean Architecture

## Overview

Clean Architecture organizes code into concentric layers where **dependencies point
inward**. In this toolkit we use three layers: **Domain** (pure business logic — entities,
use cases, repository protocols), **Data** (repository implementations, network/db data
sources, DTO mapping), and **Presentation** (SwiftUI views + MVVM ViewModels). The Domain
layer is framework-free; outer layers depend on it via protocols (Dependency Inversion).

## Use Cases

- Medium-to-large apps that must stay maintainable and testable as teams grow.
- Apps where data sources (API, DB, cache) change independently of business rules.
- Codebases that need high unit-test coverage of business logic.

## Best Practices

- Keep the **Domain layer pure** — no `Foundation` networking, no Core Data, no SwiftUI.
- Define **repository protocols in Domain**, implement them in Data.
- Encapsulate each operation as a **use case** with a single `execute` method.
- Map **DTO ↔ entity at the Data boundary**; never leak DTOs outward.
- Wire concrete types only in a **composition root** (see DI skill).

## Anti-Patterns

- ❌ ViewModels calling `URLSession`/Core Data directly (skips Domain/Data).
- ❌ Importing networking frameworks in the Domain layer.
- ❌ Use cases that are thin pass-throughs adding no value (over-engineering) — or god use cases.
- ❌ Sharing `Codable` DTOs as the app-wide model.
- ❌ Circular dependencies between layers/modules.

## Checklist

- [ ] Domain has zero framework imports.
- [ ] Repository protocols in Domain, implementations in Data.
- [ ] Use cases encapsulate operations and depend on protocols.
- [ ] DTOs mapped at the Data boundary, not leaked.
- [ ] Dependency graph is acyclic and points inward.

## Swift Examples

```swift
// Domain — pure, framework-free
struct Account: Equatable { let id: String; let name: String; let balanceCents: Int }

protocol AccountRepository {
    func accounts() async throws -> [Account]
}

struct FetchAccountsUseCase {
    let repository: AccountRepository
    func execute() async throws -> [Account] {
        try await repository.accounts().sorted { $0.balanceCents > $1.balanceCents }
    }
}
```

```swift
// Data — implements the Domain protocol, maps DTO -> entity
struct AccountDTO: Decodable { let id: String; let name: String; let balance_cents: Int }

final class RemoteAccountRepository: AccountRepository {
    private let client: APIClient
    init(client: APIClient) { self.client = client }

    func accounts() async throws -> [Account] {
        let dtos: [AccountDTO] = try await client.send(.accounts)
        return dtos.map { Account(id: $0.id, name: $0.name, balanceCents: $0.balance_cents) }
    }
}
```

## Common Interview Questions

- What is the Dependency Rule and why does it matter?
- Why does the Domain layer avoid framework imports?
- Where do DTO→entity mappers live, and why?
- How do use cases improve testability over fat ViewModels?
- When is Clean Architecture overkill?

## AI Implementation Notes

- Generate three layers; put protocols in Domain and implementations in Data.
- Never import `URLSession`/Core Data in Domain code you produce.
- For each feature, scaffold: entity, repository protocol, use case, repository impl, DTO, mapper.
- Related: [`mvvm.md`](mvvm.md), [`repository_pattern.md`](repository_pattern.md),
  [`../../architecture/clean_architecture.md`](../../architecture/clean_architecture.md).
