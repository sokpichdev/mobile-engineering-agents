# Checklist: API Integration Review

For REST/GraphQL integrations. Owned by [Backend Integrator](../agents/backend_integrator.md) +
[Networking Expert](../agents/networking_expert.md). See
[`networking_standards.md`](../standards/networking_standards.md).

## Contract & DTOs

- [ ] DTOs match the wire contract; required vs optional fields modeled correctly.
- [ ] Unknown enum values decode to a safe `.unknown` case (no crash on new server values).
- [ ] DTO→entity mapping is pure and unit-tested with fixtures (success + error + empty).
- [ ] No DTO types referenced outside the Data layer.

## Requests

- [ ] Endpoints are typed values; no scattered stringly-typed URL building.
- [ ] Explicit timeouts set; cancellation honored.
- [ ] Retries only on idempotent requests, with exponential backoff + jitter and a cap.
- [ ] Mutating requests use idempotency keys where the server supports them.

## Responses & Errors

- [ ] HTTP status validated before decoding.
- [ ] Non-2xx mapped to typed domain errors; error bodies parsed where useful.
- [ ] GraphQL: `errors` array checked even on HTTP 200.
- [ ] No raw status codes/server messages surfaced to the UI.

## Auth & Security

- [ ] Auth headers injected centrally; 401 → refresh-once-and-retry.
- [ ] No tokens/PII in logs or URLs.

## Pagination (if applicable)

- [ ] Cursor/offset state tracked; concurrent next-page loads prevented.
- [ ] Results de-duplicated by id; first/last/empty pages handled.

## Tests

- [ ] Decode/map covered by unit tests; decode path covered by an integration test
      (`URLProtocol` stub + fixtures).
