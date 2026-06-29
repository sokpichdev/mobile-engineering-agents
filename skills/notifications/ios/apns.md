---
platform: ios
---

# Skill: Apple Push Notifications (APNs)

## Overview

APNs delivers remote push notifications to iOS apps. The app registers for notifications,
receives a **device token**, and sends it to your server, which uses it (with an APNs auth
key) to push payloads. Beyond simple alerts, notification **service** and **content**
extensions let you decrypt/modify payloads and present rich/custom UI. Handle permissions
respectfully, route taps to the right screen (deep links), and never put sensitive data in
the payload.

## Use Cases

- Alerting users to messages, transactions, or events.
- Silent (`content-available`) pushes to trigger background refresh.
- Rich notifications with media via a service extension.

## Best Practices

- Request authorization **in context** (after explaining value), not on first launch.
- Register with `UNUserNotificationCenter`; upload the **device token** to your server; handle
  token refresh/rotation.
- Use **token-based auth (.p8 key)** server-side, not legacy certificates.
- Handle foreground presentation (`willPresent`) and taps (`didReceive`) → route via deep links.
- Keep payloads **minimal and non-sensitive**; use a service extension to fetch details if needed.
- Support **silent pushes** carefully (rate-limited, not guaranteed).

## Anti-Patterns

- ❌ Requesting permission immediately on launch with no context (high denial rate).
- ❌ Putting PII/secrets in the notification payload.
- ❌ Ignoring token refresh, sending to stale tokens.
- ❌ No tap routing → notification opens to a generic home screen.
- ❌ Relying on silent push for guaranteed/timely delivery.

## Checklist

- [ ] Permission requested in context; denial handled gracefully.
- [ ] Device token uploaded and refreshed.
- [ ] Token-based (.p8) auth server-side.
- [ ] Foreground presentation + tap routing implemented.
- [ ] Payloads minimal; no sensitive data.

## Swift Examples

```swift
import UserNotifications

final class PushManager: NSObject, UNUserNotificationCenterDelegate {
    func requestAuthorizationAndRegister() async {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        let granted = (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        guard granted else { return }
        await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
    }

    // Show banners while in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async
        -> UNNotificationPresentationOptions { [.banner, .sound, .badge] }

    // Route taps to the right screen
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let info = response.notification.request.content.userInfo
        if let deepLink = info["deep_link"] as? String, let url = URL(string: deepLink) {
            await DeepLinkRouter.shared.handle(url)
        }
    }
}

// In AppDelegate: forward the token to your server
func application(_ app: UIApplication,
                didRegisterForRemoteNotificationsWithDeviceToken token: Data) {
    let tokenString = token.map { String(format: "%02x", $0) }.joined()
    Task { await DeviceTokenService.shared.upload(tokenString) }
}
```

## Common Interview Questions

- How does the APNs token lifecycle work?
- Token-based vs certificate-based APNs auth?
- How do silent pushes differ from alert pushes, and their limitations?
- What do notification service/content extensions do?
- How do you route a notification tap to a specific screen?

## AI Implementation Notes

- Request permission in context; always upload and refresh the device token.
- Implement `willPresent` and `didReceive`; route taps through the deep link router.
- Keep payloads non-sensitive; use a service extension for rich content.
- Related: [`fcm.md`](fcm.md), [`deep_links.md`](deep_links.md).
