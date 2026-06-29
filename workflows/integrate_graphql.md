# Workflow: Integrate GraphQL

## Objective

Add a GraphQL query/mutation integration with minimal field selection, partial-error
handling, DTO→entity mapping, and tests — behind a repository.

## Inputs

- GraphQL schema / operation, variables, and the fields the UI actually needs.
- Sample response(s), including a partial-error response.

## Outputs

- Operation (query/mutation) with variables, response DTO, mapper, repository method, tests.

## Step-by-Step Process

1. **Design the operation** ([Backend Integrator](../agents/backend_integrator.md)) — select
   only needed fields; use fragments + variables (see
   [`skills/networking/ios/graphql.md`](../skills/networking/ios/graphql.md)).
2. **Define the response DTO** matching the selected shape; capture fixtures (incl. `errors`).
3. **Handle partial failures** — check the `errors` array even on HTTP 200; map to a typed error.
4. **Map DTO→entity**; unit-test mapping with fixtures.
5. **Implement the repository method** using the GraphQL client; choose a cache policy.
6. **Auth** ([Security Expert](../agents/security_expert.md)) — headers, token refresh, no leakage.
7. **Integration-test** decode + error handling.
8. **Review** against [`checklists/api_review.md`](../checklists/api_review.md).

## Validation Steps

- Only required fields are requested; inputs passed as variables.
- `errors` array handled even on 200.
- Mapping pure and tested; generated/DTO types not leaked to the UI.

## Failure Scenarios

- **Partial data + errors** → decide per field: surface error vs. render partial; document.
- **Over-fetching** → trim the selection set.
- **N+1 / large query** → split or paginate; coordinate with backend.

## AI Agent Instructions

- Always check `errors` even on HTTP 200; never interpolate inputs into the query string.
- Request the minimal field set; map DTOs to domain entities behind a repository.
- Generate fixtures (success + partial error) and tests.

## Acceptance Criteria

- [ ] Operation uses variables/fragments; minimal fields.
- [ ] Partial errors handled and typed.
- [ ] Mapping tested; no generated types in Presentation.
- [ ] Auth handled; `checklists/api_review.md` passes.
