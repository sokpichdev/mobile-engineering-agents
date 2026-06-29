# Skills

Deep, single-topic capabilities. Load the relevant skill into your agent's context for
focused, expert implementation guidance. Each file follows the same structure: **Overview ·
Use Cases · Best Practices · Anti-Patterns · Checklist · Code Examples · Common Interview
Questions · AI Implementation Notes**.

**Platform layout.** Skills are split by platform inside each topic — `<topic>/ios/`,
`<topic>/android/`, `<topic>/flutter/`, … — and each file declares `platform:` in its
front-matter. Load only the platform you're working on. The links below are the **iOS** set;
porting a skill? Add it in the sibling platform folder and cross-link its iOS counterpart (see
[CONTRIBUTING.md](../CONTRIBUTING.md#repository-layout-platforms)).

## Architecture

- [mvvm.md](architecture/ios/mvvm.md)
- [clean_architecture.md](architecture/ios/clean_architecture.md)
- [dependency_injection.md](architecture/ios/dependency_injection.md)
- [repository_pattern.md](architecture/ios/repository_pattern.md)
- [modularization.md](architecture/ios/modularization.md)

## Networking

- [rest_api.md](networking/ios/rest_api.md)
- [graphql.md](networking/ios/graphql.md)
- [websocket.md](networking/ios/websocket.md)
- [sse.md](networking/ios/sse.md)
- [pagination.md](networking/ios/pagination.md)
- [file_upload.md](networking/ios/file_upload.md)

## Security

- [oauth2.md](security/ios/oauth2.md)
- [jwt.md](security/ios/jwt.md)
- [ssl_pinning.md](security/ios/ssl_pinning.md)
- [certificate_pinning.md](security/ios/certificate_pinning.md)
- [aes_encryption.md](security/ios/aes_encryption.md)
- [keychain.md](security/ios/keychain.md)
- [biometric_auth.md](security/ios/biometric_auth.md)

## Storage

- [coredata.md](storage/ios/coredata.md)
- [sqlite.md](storage/ios/sqlite.md)
- [offline_sync.md](storage/ios/offline_sync.md)
- [caching.md](storage/ios/caching.md)

## Notifications

- [apns.md](notifications/ios/apns.md)
- [fcm.md](notifications/ios/fcm.md)
- [deep_links.md](notifications/ios/deep_links.md)

## Testing

- [unit_testing.md](testing/ios/unit_testing.md)
- [integration_testing.md](testing/ios/integration_testing.md)
- [ui_testing.md](testing/ios/ui_testing.md)

## Performance

- [memory_optimization.md](performance/ios/memory_optimization.md)
- [startup_optimization.md](performance/ios/startup_optimization.md)
- [battery_optimization.md](performance/ios/battery_optimization.md)
