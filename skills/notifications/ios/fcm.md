---
platform: ios
---

# Skill: Firebase Cloud Messaging (FCM)

## Overview

Firebase Cloud Messaging is a cross-platform push layer that, on iOS, sits **on top of
APNs** — FCM still requires an APNs key and device token, but gives you a unified API,
**topic subscriptions**, and easier multi-platform targeting. Use it when you need
cross-platform parity or topic/segment messaging. The same iOS notification handling
(permissions, foreground, tap routing) applies; FCM just manages token mapping and delivery.

## Use Cases

- Cross-platform (iOS + Android) apps wanting one messaging backend.
- Topic-based broadcast (e.g. "sports-news" subscribers).
- Teams already invested in Firebase.

## Best Practices

- Configure **APNs auth key in Firebase**; FCM delegates actual delivery to APNs on iOS.
- Use the **FCM registration token** (not the raw APNs token) for sending; handle
  `messaging(_:didReceiveRegistrationToken:)` refresh.
- Prefer **topic subscriptions** for broadcast instead of managing huge token lists.
- Keep the standard `UNUserNotificationCenter` handling for foreground + taps.
- **Don't put secrets/PII** in `data`/`notification` payloads.

## Anti-Patterns

- ❌ Forgetting the APNs key, so iOS pushes silently fail.
- ❌ Sending to stale FCM tokens; not handling token refresh.
- ❌ Managing per-device sends when a topic would do.
- ❌ Trusting `data` payload contents as authenticated/sensitive.
- ❌ Mixing FCM and direct APNs handling inconsistently.

## Checklist

- [ ] APNs auth key configured in Firebase.
- [ ] FCM registration token used and refreshed.
- [ ] Topics used for broadcast where appropriate.
- [ ] Foreground + tap handling implemented.
- [ ] No sensitive data in payloads.

## Swift Examples

```swift
import FirebaseMessaging
import UserNotifications

final class FCMManager: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {
    func configure() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
    }

    // FCM token refresh — upload to your server
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        Task { await DeviceTokenService.shared.upload(fcmToken) }
    }

    func subscribe(toTopic topic: String) {
        Messaging.messaging().subscribe(toTopic: topic)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let info = response.notification.request.content.userInfo
        if let link = info["deep_link"] as? String, let url = URL(string: link) {
            await DeepLinkRouter.shared.handle(url)
        }
    }
}
```

## Common Interview Questions

- How does FCM relate to APNs on iOS?
- FCM registration token vs APNs device token?
- When are topics better than token lists?
- How do you handle FCM token refresh?
- Trade-offs of FCM vs direct APNs?

## AI Implementation Notes

- Remember FCM still needs an APNs key; use and refresh the FCM registration token.
- Reuse the standard notification handling and deep link router.
- Prefer topics for broadcast; keep payloads non-sensitive.
- Related: [`apns.md`](apns.md), [`deep_links.md`](deep_links.md).
