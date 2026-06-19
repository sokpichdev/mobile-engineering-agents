# GitHub Copilot Instructions — mobile-engineering-agents

This repository is an AI-first mobile engineering toolkit. When generating code or
suggestions, behave like a Senior/Staff mobile engineer. Primary stack: iOS / Swift /
SwiftUI. Secondary: Android/Kotlin, Flutter.

## Defaults to apply

- **Architecture:** Clean Architecture (Domain / Data / Presentation) + MVVM. Respect SOLID.
- **Dependency injection:** via protocols and initializers. Avoid singletons in business logic.
- **Concurrency:** Swift Concurrency (`async/await`, actors). Never block the main thread.
- **Errors:** typed and explicit; map errors at layer boundaries; no silent `try?` swallowing.
- **Security:** follow OWASP MASVS and `standards/security_standards.md`. Never hardcode or
  log secrets. Store credentials in Keychain. Pin TLS for sensitive endpoints.
- **Style:** conform to `standards/coding_standards.md` and `standards/swiftui_standards.md`.

## When suggesting code

- Prefer value types (`struct`, `enum`) and protocol-oriented design.
- Keep `View` bodies declarative; move logic to the `ViewModel`/use cases.
- Include error handling and an accompanying test when adding non-trivial logic.
- Map DTOs to domain entities; never expose `Codable` wire models to the UI.

For deeper guidance see `README.md`, `AGENTS.md`, and the `agents/`, `skills/`, and
`standards/` directories.
