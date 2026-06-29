---
platform: ios
---

# Skill: UI Testing

## Overview

UI tests (XCUITest) drive the app through the **accessibility layer**, simulating real user
journeys end-to-end. They give the highest confidence but are the **slowest and most
brittle** — so keep them few and focused on **critical paths** (login, checkout, core flow).
Stability comes from using **accessibility identifiers** (not labels or coordinates),
**waiting on expectations** (never `sleep`), and **stubbing the backend** so tests are
deterministic.

## Use Cases

- Smoke-testing critical journeys before release.
- Catching regressions in navigation and end-to-end wiring.
- Verifying accessibility identifiers exist (a side benefit).

## Best Practices

- Test only **critical user journeys**; keep the suite small.
- Use **accessibility identifiers** for element queries, separate from human-readable labels.
- **Wait with expectations** (`waitForExistence`), never fixed `sleep`.
- **Stub the network** (launch arguments + a mock environment) for determinism.
- Use the **Page Object / Screen** pattern to keep tests readable and maintainable.
- Reset state between tests via launch arguments (clean account, seeded data).

## Anti-Patterns

- ❌ Testing everything through the UI instead of unit/integration tests.
- ❌ Querying by visible text/coordinates that change with copy/layout/locale.
- ❌ `sleep`-based waits → flaky tests.
- ❌ Depending on a live backend / real account state.
- ❌ Copy-pasted element queries instead of screen objects.

## Checklist

- [ ] Only critical journeys covered.
- [ ] Elements queried by accessibility identifier.
- [ ] Waits use expectations, not `sleep`.
- [ ] Backend stubbed; state reset per test.
- [ ] Screen/Page Object structure used.

## Swift Examples

```swift
import XCTest

final class LoginUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-uiTesting", "-stubNetwork", "loggedOut"]  // deterministic env
        app.launch()
    }

    func test_login_happyPath_showsDashboard() {
        let login = LoginScreen(app: app)
        login.enterEmail("user@example.com")
            .enterPassword("correct-horse")
            .tapSignIn()

        let dashboard = app.otherElements["dashboard.root"]
        XCTAssertTrue(dashboard.waitForExistence(timeout: 5))   // wait, don't sleep
    }
}

// Screen / Page Object
struct LoginScreen {
    let app: XCUIApplication
    @discardableResult func enterEmail(_ s: String) -> Self {
        let field = app.textFields["login.email"]; field.tap(); field.typeText(s); return self
    }
    @discardableResult func enterPassword(_ s: String) -> Self {
        let field = app.secureTextFields["login.password"]; field.tap(); field.typeText(s); return self
    }
    func tapSignIn() { app.buttons["login.submit"].tap() }
}
```

## Common Interview Questions

- Why keep UI tests few (the test pyramid)?
- Why query by accessibility identifier instead of label/coordinates?
- How do you make UI tests deterministic?
- What is the Page Object pattern?
- How do you avoid flaky waits?

## AI Implementation Notes

- Add `accessibilityIdentifier`s in the app code, then query them in tests.
- Always wait with `waitForExistence`; never `sleep`. Stub the backend via launch args.
- Generate Screen objects; keep the suite limited to critical paths.
- Related: [`unit_testing.md`](unit_testing.md),
  [`../../../agents/accessibility_expert.md`](../../../agents/accessibility_expert.md).
