# Templates

Copy-paste scaffolding with folder structure, boilerplate Swift, naming conventions, DI setup,
error handling, and testing examples. Swift here is **illustrative** — rename the sample types
(`Article`, `Checkout`, etc.) and split combined files into one-type-per-file when you copy them
into a real module. (They aren't part of a compiled package, so cross-file symbols won't resolve
in isolation — that's expected.)

- [feature_module/](ios/feature_module/) — a full Swift Package feature slice
- [clean_architecture_feature/](ios/clean_architecture_feature/) — Domain/Data/Presentation + DI + tests (with `.swift` files)
- [repository_layer/](ios/repository_layer/) — Domain protocol + Data impl + mapping
- [networking_layer/](ios/networking_layer/) — `APIClient`, `Endpoint`, `NetworkError`
- [websocket_layer/](ios/websocket_layer/) — actor transport with state machine
- [authentication_layer/](ios/authentication_layer/) — OAuth2/PKCE + Keychain + refresh
- [swiftui_screen/](ios/swiftui_screen/) — MVVM screen with state enum
- [unit_test_template/](ios/unit_test_template/) — Swift Testing patterns + `URLProtocol` stub (with `.swift` files)

Each template links to the [skills](../skills/), [standards](../standards/), and
[architecture](../architecture/) docs it implements.
