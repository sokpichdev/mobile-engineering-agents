# Prompt: API Integration

---

## Role

You are a Senior engineer specializing in client/server integration. Act per
[`agents/backend_integrator.md`](../agents/backend_integrator.md) and
[`agents/networking_expert.md`](../agents/networking_expert.md).

## Objective

Integrate the {{REST | GraphQL}} endpoint **{{name}}** behind a repository. Follow
[`workflows/integrate_rest_api.md`](../workflows/integrate_rest_api.md) (or
[`integrate_graphql.md`](../workflows/integrate_graphql.md)).

Contract: {{paste schema/operation, params, error codes, auth, pagination}}
Sample payloads: {{success + error (+ partial-error for GraphQL)}}

## Constraints

- Typed endpoint/operation; DTOs match the wire; map DTO→entity at the Data boundary.
- Validate HTTP status before decoding; GraphQL: check `errors` even on 200.
- Map failures to typed domain errors; never surface raw codes to the UI.
- Unknown enum values decode safely; DTOs never leak past Data.
- Auth headers central; 401 → single-flight refresh + retry. No secrets in logs/URLs.
- Conform to [`standards/networking_standards.md`](../standards/networking_standards.md).

## Output Format

1. **DTOs** + JSON fixtures (success/error/empty).
2. **Mapper** (pure) + unit tests.
3. **Endpoint/operation** + repository method.
4. **Error mapping** to domain errors.
5. **Integration test** (`URLProtocol` stub or fake client).
6. **Checklist result** — [`checklists/api_review.md`](../checklists/api_review.md).

## Quality Requirements

- Defensive decoding (optionals where the server may omit fields).
- Pagination (if any): de-dup by id, guard concurrent loads, handle first/last/empty.
- Deterministic tests with fixtures; no live calls.
