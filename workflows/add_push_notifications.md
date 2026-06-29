# Workflow: Add Push Notifications

## Objective

Add remote push notifications (APNs directly or via FCM) with in-context permission, token
upload, foreground handling, and deep-link tap routing.

## Inputs

- Push provider choice (APNs vs FCM), payload schema, deep-link targets.
- Backend endpoint to receive device tokens.

## Outputs

- Registration + permission flow, token upload, notification handling, deep-link routing, tests.

## Step-by-Step Process

1. **Enable capabilities** ([DevOps Expert](../agents/devops_expert.md)) — Push Notifications
   capability, APNs auth key (.p8); for FCM, configure the APNs key in Firebase.
2. **Request permission in context** — explain value first, then
   `UNUserNotificationCenter.requestAuthorization`
   (see [`skills/notifications/ios/apns.md`](../skills/notifications/ios/apns.md) or
   [`fcm.md`](../skills/notifications/ios/fcm.md)).
3. **Upload the token** — device token (APNs) or registration token (FCM); handle refresh.
4. **Handle presentation** — `willPresent` for foreground banners.
5. **Route taps** — parse `userInfo` deep link through the
   [router](../skills/notifications/ios/deep_links.md); handle cold start.
6. **Security** ([Security Expert](../agents/security_expert.md)) — ensure no PII/secrets in
   payloads; don't authorize off payload contents.
7. **Test** registration, foreground, and tap routing (use a stub router); document silent-push
   limits if used.

## Validation Steps

- Permission prompt appears in context; denial handled gracefully.
- Token uploaded and refreshed; pushes arrive on device.
- Foreground banners shown; taps route to the correct screen (incl. cold start).

## Failure Scenarios

- **Missing APNs key (FCM)** → iOS delivery fails silently; verify configuration.
- **Stale tokens** → handle refresh + server cleanup.
- **Permission denied** → degrade gracefully; offer Settings deep link.
- **Malformed payload** → router returns `.unknown`; no crash.

## AI Agent Instructions

- Request permission in context, never on first launch with no explanation.
- Always upload + refresh tokens; route taps through the centralized deep-link router.
- Keep payloads non-sensitive; handle cold-start launches from notifications.

## Acceptance Criteria

- [ ] Capability + APNs key configured.
- [ ] In-context permission; token uploaded/refreshed.
- [ ] Foreground handling + tap routing (incl. cold start).
- [ ] No sensitive data in payloads.
- [ ] Handling covered by tests.
