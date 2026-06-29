---
name: Platform port
about: Port an existing iOS agent/skill to Android, Flutter, or another platform
title: "[Port] "
labels: enhancement, help wanted
assignees: ''
---

## What to port
<!-- The existing iOS file and the target platform -->

**Source file:** `skills/<topic>/ios/...`
**Target file:** `skills/<topic>/<platform>/...` (e.g. `skills/security/android/keystore.md`)

## Platform equivalents
<!-- The native APIs / libraries this maps to, e.g. Keychain → Android Keystore -->

## Scope

- [ ] **Rebase on `main` before you start** so you're against the current platform-scoped
      layout (see [CONTRIBUTING.md → Repository layout](../../CONTRIBUTING.md#repository-layout-platforms))
- [ ] Place the file in the right platform subfolder; reference shared paths as they exist on
      `main` (e.g. `templates/ios/...`, not `templates/...`)
- [ ] Add `platform:` front-matter (`android` / `flutter` / `react_native`)
- [ ] Mirror the source file's section template (see [CONTRIBUTING.md](../../CONTRIBUTING.md#file-section-templates))
- [ ] Code blocks labeled with the right language (`kotlin`, `dart`)
- [ ] Cross-link the iOS counterpart so the two stay in sync
- [ ] Add the new file to the directory `README.md` index
- [ ] Run `npm run lint` (link-check included) and confirm it passes

## Notes
<!-- Anything tricky about the platform mapping, or open questions on scope -->
