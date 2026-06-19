# Glossary

Shared terminology used across the toolkit. Agents and skills assume these definitions.

## Architecture

- **Clean Architecture** — Layered design with dependencies pointing inward. Three layers
  used throughout this repo: **Domain**, **Data**, **Presentation**.
- **Domain layer** — Pure business logic: entities, value objects, use cases, and
  repository *protocols*. No framework or platform imports.
- **Data layer** — Implements Domain repository protocols using data sources (network,
  database, cache). Maps DTOs ↔ domain entities.
- **Presentation layer** — UI and view state. Uses **MVVM**: `View` ↔ `ViewModel` ↔ use cases.
- **MVVM** — Model-View-ViewModel. The `ViewModel` exposes observable state and calls use
  cases; the `View` is a function of state.
- **Use Case (Interactor)** — A single application operation in the Domain layer (e.g.
  `FetchAccountsUseCase`). Orchestrates repositories.
- **Repository** — Abstraction over data access. Protocol in Domain, implementation in Data.
- **DTO (Data Transfer Object)** — Wire/serialization model (`Codable`). Never used directly
  by the UI; mapped to a domain entity.
- **DI (Dependency Injection)** — Providing dependencies from outside via initializers/protocols
  rather than constructing them internally.
- **Module** — An independently buildable unit (Swift Package / framework) with an explicit
  public interface.
- **SOLID** — Single responsibility, Open/closed, Liskov substitution, Interface segregation,
  Dependency inversion.

## Networking

- **REST** — Resource-oriented HTTP API.
- **GraphQL** — Query language where the client specifies the response shape.
- **WebSocket** — Full-duplex persistent TCP connection for realtime messaging.
- **SSE (Server-Sent Events)** — Server-to-client one-way stream over HTTP.
- **Backpressure** — Strategy for handling messages arriving faster than they can be processed.
- **Idempotency key** — Client-generated key that lets the server safely de-duplicate retried
  mutating requests.
- **Exponential backoff** — Retry delay that grows multiplicatively, usually with jitter.

## Security

- **OWASP MASVS** — Mobile Application Security Verification Standard. The requirement baseline.
- **OWASP MASTG** — Mobile Application Security Testing Guide. The testing companion to MASVS.
- **Keychain** — Apple's secure, encrypted credential store.
- **SSL/Certificate Pinning** — Validating the server's certificate or public key against a
  known value to resist MITM.
- **JWT** — JSON Web Token; a signed, base64url-encoded claims token.
- **OAuth2 / PKCE** — Delegated authorization framework; PKCE is the public-client extension.
- **AES-GCM** — Authenticated symmetric encryption (confidentiality + integrity).

## Testing

- **Unit test** — Tests one component in isolation with dependencies stubbed/mocked.
- **Integration test** — Tests collaboration across components (e.g. repository + decoder).
- **UI test** — Drives the app through the accessibility layer (XCUITest).
- **Test double** — Stub, mock, spy, or fake standing in for a real dependency.
- **AAA** — Arrange, Act, Assert test structure.

## Delivery

- **CI/CD** — Continuous Integration / Continuous Delivery.
- **Fastlane** — Automation toolchain for build, sign, and store submission.
- **Semantic Versioning** — `MAJOR.MINOR.PATCH`.
- **TestFlight** — Apple's beta distribution service.

## Toolkit Vocabulary

- **Agent** — A loadable operational role (file in `agents/`).
- **Skill** — A deep, single-topic capability (file in `skills/`).
- **Workflow** — An end-to-end procedure chaining agents/skills (file in `workflows/`).
- **Handoff** — The structured context one agent passes to the next (see [AGENTS.md](AGENTS.md)).
