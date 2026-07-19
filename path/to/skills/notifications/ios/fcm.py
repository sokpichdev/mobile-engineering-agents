# complete code

"""
Push Notifications (FCM) skill for iOS

This skill provides a template for implementing Push Notifications (FCM) on iOS.
"""

import os

def create_ios_skill():
    """
    Create a new iOS skill for Push Notifications (FCM) mirroring the Android skill's section template.
    """
    # Create the skill file
    with open("skills/notifications/ios/fcm.md", "w") as f:
        f.write("# Push Notifications (FCM) skill for iOS\n\n")
        f.write("This skill provides a template for implementing Push Notifications (FCM) on iOS.\n\n")
        f.write("## Platform equivalents\n\n")
        f.write("- APNs/FCM on iOS → **Firebase Cloud Messaging** on Android (`FirebaseMessagingService`)\n")
        f.write("- Token handling → `onNewToken`\n")
        f.write("- Channels → `NotificationChannel` (Android 8+), POST_NOTIFICATIONS permission (13+)\n\n")
        f.write("## Scope\n\n")
        f.write("- [ ] Mirror the Android skill's section template\n")
        f.write("- [ ] Add `platform: ios` front-matter\n")
        f.write("- [ ] Swift code blocks labeled `swift`\n")
        f.write("- [ ] Cover foreground/background/data messages and notification channels\n")
        f.write("- [ ] Cross-link the Android counterpart; add an iOS entry to `skills/README.md`\n\n")

def add_platform_specific_details():
    """
    Add platform-specific details for iOS, including APNs and NotificationService.
    """
    # Add APNs
    with open("skills/notifications/ios/fcm.md", "a") as f:
        f.write("\n## APNs\n\n")
        f.write("To use APNs, add the following code to your `AppDelegate` file:\n")
        f.write("