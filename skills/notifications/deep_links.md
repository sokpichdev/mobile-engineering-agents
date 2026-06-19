# Skill: Deep Links & Universal Links

## Overview

Deep links route users directly to specific in-app content. **Custom URL schemes**
(`myapp://`) are simple but spoofable and not web-fallback-friendly. **Universal Links**
(`https://` associated domains) are the recommended approach: verified by an
`apple-app-site-association` (AASA) file, secure, and they fall back to the website if the
app isn't installed. A robust implementation centralizes parsing in a **router** that maps a
URL to a typed destination and drives navigation — including the cold-start case.

## Use Cases

- Opening a specific item from a notification, email, or web page.
- Marketing/referral links and deferred deep linking.
- Inter-app navigation and OAuth callbacks (custom scheme).

## Best Practices

- Prefer **Universal Links** with a correct AASA and Associated Domains entitlement.
- **Centralize parsing** in a router that returns a typed route; validate/sanitize parameters.
- Handle **cold start** (`onOpenURL`/`continueUserActivity`) and warm routing consistently.
- **Verify ownership/authorization** before acting (don't trust the URL to grant access).
- Provide a **web fallback** for uninstalled apps; handle unknown links gracefully.

## Anti-Patterns

- ❌ Relying solely on custom schemes (spoofable, hijackable by other apps).
- ❌ Scattering URL parsing across many views.
- ❌ Trusting link parameters for authorization.
- ❌ Ignoring cold-start launches from a link.
- ❌ Crashing/dead-ending on malformed or unknown URLs.

## Checklist

- [ ] Universal Links configured (AASA + Associated Domains).
- [ ] Centralized router maps URL → typed route; params validated.
- [ ] Cold start and warm routing both handled.
- [ ] Authorization checked before acting on a link.
- [ ] Web fallback + graceful unknown-link handling.

## Swift Examples

```swift
enum Route: Equatable {
    case article(id: String)
    case profile(userID: String)
    case unknown
}

@MainActor
final class DeepLinkRouter: ObservableObject {
    static let shared = DeepLinkRouter()
    @Published var route: Route?

    func parse(_ url: URL) -> Route {
        guard url.scheme == "https", url.host == "example.com" else { return .unknown }
        let parts = url.pathComponents.filter { $0 != "/" }
        switch parts.first {
        case "articles" where parts.count == 2: return .article(id: parts[1])
        case "users" where parts.count == 2: return .profile(userID: parts[1])
        default: return .unknown
        }
    }

    func handle(_ url: URL) { route = parse(url) }
}
```

```swift
// SwiftUI entry — handles Universal Links including cold start
.onOpenURL { url in DeepLinkRouter.shared.handle(url) }
.onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
    if let url = activity.webpageURL { DeepLinkRouter.shared.handle(url) }
}
```

## Common Interview Questions

- Universal Links vs custom URL schemes — security and UX differences?
- What is the AASA file and how is it verified?
- How do you handle a deep link on cold start?
- Why centralize deep link parsing?
- What is deferred deep linking?

## AI Implementation Notes

- Default to Universal Links; centralize parsing into a router returning a typed `Route`.
- Handle both `onOpenURL` and `onContinueUserActivity`; validate params; never authorize off the URL.
- Map every notification tap through this router.
- Related: [`apns.md`](apns.md), [`fcm.md`](fcm.md),
  [`../../agents/swiftui_expert.md`](../../agents/swiftui_expert.md).
