# Workflow: Integrate a REST API

## Objective

Add a REST endpoint integration with typed requests, DTO→entity mapping, layered error
handling, and tests — exposed behind a repository.

## Inputs

- Endpoint contract (path, method, params, request/response schema, error codes, auth).
- Sample success and error JSON payloads (or the ability to capture them).

## Outputs

- Typed endpoint, DTO(s), mapper, repository method, and tests with fixtures.

## Step-by-Step Process

1. **Read the contract** ([Backend Integrator](../agents/backend_integrator.md)) — note
   required/optional fields, error codes, pagination, and auth.
2. **Define the DTO(s)** matching the wire format exactly (`Codable`); capture JSON fixtures.
3. **Write the mapper** DTO→domain entity; unit-test it with fixtures (incl. edge cases).
4. **Add the typed endpoint** and repository method using the
   [`APIClient`](../skills/networking/rest_api.md) abstraction.
5. **Map errors** ([Networking Expert](../agents/networking_expert.md)) — status/transport/
   decoding → typed domain error.
6. **Auth** ([Security Expert](../agents/security_expert.md)) — ensure headers injected
   centrally; handle 401 refresh; no token leakage.
7. **Integration test** the decode→map path with `URLProtocol` stubbing
   ([integration testing](../skills/testing/integration_testing.md)).
8. **Review** against [`checklists/api_review.md`](../checklists/api_review.md).

## Validation Steps

- DTOs decode real fixtures (success + error + empty).
- Mapping is pure and unit-tested; unknown enum values don't crash.
- Non-2xx mapped to typed errors; no raw codes surfaced to the UI.
- No tokens/PII in logs or URLs.

## Failure Scenarios

- **Schema mismatch** → adjust DTO, add a fixture, flag drift to backend.
- **Inconsistent/undocumented errors** → map known codes, default the rest to a generic
  domain error; document the gap.
- **Auth/401 loop** → verify single-flight refresh; escalate to Security if unresolved.

## AI Agent Instructions

- Never call `URLSession` directly in features — go through the `APIClient` + repository.
- Validate status before decoding; map all failures to a typed error.
- Generate fixtures and tests alongside the code.
- Retry only idempotent requests with backoff.

## Acceptance Criteria

- [ ] Typed endpoint + DTO + mapper + repository method implemented.
- [ ] Status validated; errors typed and mapped.
- [ ] Mapping unit-tested; decode integration-tested with fixtures.
- [ ] Auth handled centrally; no secret leakage.
- [ ] `checklists/api_review.md` passes.
