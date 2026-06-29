# Template: Repository Layer

Boilerplate for a repository: Domain protocol + Data implementation with DTO mapping and
typed errors. See [`skills/architecture/ios/repository_pattern.md`](../../../skills/architecture/ios/repository_pattern.md).

## Folder Structure

```text
Domain/
├── {{Entity}}.swift
├── {{Entity}}Repository.swift      // protocol
└── DomainError.swift
Data/
├── {{Entity}}DTO.swift
├── {{Entity}}Mapper.swift
└── Remote{{Entity}}Repository.swift
```

## Domain — Protocol & Entity

```swift
struct {{Entity}}: Equatable, Identifiable {
    let id: String
    // domain fields…
}

protocol {{Entity}}Repository {
    func all(refresh: Bool) async throws -> [{{Entity}}]
    func item(id: String) async throws -> {{Entity}}
}

enum DomainError: Error, Equatable {
    case notFound
    case network
    case unexpected
}
```

## Data — DTO, Mapper, Implementation

```swift
struct {{Entity}}DTO: Decodable {
    let id: String
    // wire fields (snake_case decoded by the shared decoder)…
}

enum {{Entity}}Mapper {
    static func toDomain(_ dto: {{Entity}}DTO) -> {{Entity}} {
        {{Entity}}(id: dto.id /*, map fields */)
    }
}

final class Remote{{Entity}}Repository: {{Entity}}Repository {
    private let client: APIClient
    init(client: APIClient) { self.client = client }

    func all(refresh: Bool) async throws -> [{{Entity}}] {
        do {
            let dtos: [{{Entity}}DTO] = try await client.send(Endpoint(path: "/{{entities}}"))
            return dtos.map({{Entity}}Mapper.toDomain)
        } catch let error as NetworkError {
            throw map(error)
        }
    }

    func item(id: String) async throws -> {{Entity}} {
        do {
            let dto: {{Entity}}DTO = try await client.send(Endpoint(path: "/{{entities}}/\(id)"))
            return {{Entity}}Mapper.toDomain(dto)
        } catch let error as NetworkError {
            throw map(error)
        }
    }

    private func map(_ error: NetworkError) -> DomainError {
        switch error {
        case .http(404): return .notFound
        case .http, .transport, .invalidResponse: return .network
        case .decoding: return .unexpected
        default: return .unexpected
        }
    }
}
```

## Conventions

- **Naming:** `Remote{{Entity}}Repository` / `Caching{{Entity}}Repository` (use an `actor` if it holds a cache).
- **DI:** `APIClient`/data sources injected; never construct `URLSession` here.
- **Error handling:** map `NetworkError` → `DomainError`; never leak `NetworkError`/DTOs upward.
- **Testing:** see [unit_test_template](../unit_test_template/); test mapping + error mapping.
