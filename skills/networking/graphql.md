# Skill: GraphQL Integration

## Overview

GraphQL lets the client request exactly the fields it needs from a single endpoint. On iOS
you can use a generated client (Apollo) or a lightweight typed wrapper over POST requests.
Either way, queries/mutations map to DTOs, DTOs map to domain entities, and the GraphQL
layer stays in the Data layer behind repositories. The key differences from REST: a single
endpoint, response shape controlled by the query, and **errors can appear in the `errors`
array even on HTTP 200**.

## Use Cases

- Backends exposing GraphQL where over/under-fetching with REST is costly.
- Screens needing tailored field sets to reduce payload size.
- Aggregating multiple resources in one round trip.

## Best Practices

- Request **only the fields you use**; avoid `...everything` fragments.
- Handle **partial responses**: HTTP 200 can carry `data` *and* `errors`.
- Use **fragments** for reuse and **variables** (never string-interpolate inputs).
- Map GraphQL DTOs → domain entities; don't pass generated types to the UI.
- Cache and normalize where the client supports it; define cache policy explicitly.

## Anti-Patterns

- ❌ Treating HTTP 200 as success while ignoring the `errors` array.
- ❌ String-interpolating user input into the query (correctness + injection risk).
- ❌ Over-fetching huge field sets "to be safe."
- ❌ Leaking Apollo-generated types throughout the app.
- ❌ One mega-query for unrelated screens.

## Checklist

- [ ] Queries request only needed fields; inputs passed as variables.
- [ ] `errors` array checked even on HTTP 200.
- [ ] DTO→entity mapping at the Data boundary.
- [ ] Cache policy chosen deliberately.
- [ ] Generated types not leaked to Presentation.

## Swift Examples

```swift
struct GraphQLRequest: Encodable { let query: String; let variables: [String: AnyEncodable] }

struct GraphQLResponse<T: Decodable>: Decodable {
    let data: T?
    let errors: [GraphQLError]?
    struct GraphQLError: Decodable, Error { let message: String }
}

func execute<T: Decodable>(_ req: GraphQLRequest, as: T.Type) async throws -> T {
    let body = try JSONEncoder().encode(req)
    let endpoint = Endpoint<GraphQLResponse<T>>(path: "/graphql", method: "POST", body: body)
    let response = try await client.send(endpoint)
    if let errors = response.errors, !errors.isEmpty {
        throw NetworkError.graphQL(errors.map(\.message))   // partial failure on HTTP 200
    }
    guard let data = response.data else { throw NetworkError.invalidResponse }
    return data
}
```

```graphql
# Use variables + fragments, never string interpolation
query Feed($cursor: String, $limit: Int!) {
  feed(after: $cursor, first: $limit) {
    edges { node { ...PostFields } }
    pageInfo { endCursor hasNextPage }
  }
}
fragment PostFields on Post { id title author { id name } createdAt }
```

## Common Interview Questions

- How does GraphQL error handling differ from REST?
- What is over-/under-fetching and how does GraphQL address it?
- Why use variables and fragments?
- How does normalized caching work (e.g. Apollo)?
- When would you choose REST over GraphQL?

## AI Implementation Notes

- Always check the `errors` array even on HTTP 200; surface as a typed error.
- Pass inputs as variables; never interpolate into the query string.
- Map generated/DTO types to domain entities behind a repository.
- Related: [`rest_api.md`](rest_api.md), [`pagination.md`](pagination.md),
  [`../../workflows/integrate_graphql.md`](../../workflows/integrate_graphql.md).
