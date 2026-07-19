# complete code

"""
Push Notifications (FCM) skill for Android

This skill mirrors the iOS Push Notifications (FCM) skill and adds platform-specific details for Android.
"""

import os

def create_android_skill():
    """
    Create a new Android skill for Push Notifications (FCM) mirroring the iOS skill's section template.
    """
    # Create the skill file
    with open("skills/notifications/android/fcm.md", "w") as f:
        f.write("# Push Notifications (FCM) skill for Android\n\n")
        f.write("This skill mirrors the iOS Push Notifications (FCM) skill and adds platform-specific details for Android.\n\n")
        f.write("## Platform equivalents\n\n")
        f.write("- APNs/FCM on iOS → **Firebase Cloud Messaging** on Android (`FirebaseMessagingService`)\n")
        f.write("- Token handling → `onNewToken`\n")
        f.write("- Channels → `NotificationChannel` (Android 8+), POST_NOTIFICATIONS permission (13+)\n\n")
        f.write("## Scope\n\n")
        f.write("- [ ] Mirror the iOS skill's section template\n")
        f.write("- [ ] Add `platform: android` front-matter\n")
        f.write("- [ ] Kotlin code blocks labeled `kotlin`\n")
        f.write("- [ ] Cover foreground/background/data messages and notification channels\n")
        f.write("- [ ] Cross-link the iOS counterpart; add an Android entry to `skills/README.md`\n\n")

def add_platform_specific_details():
    """
    Add platform-specific details for Android, including Firebase Cloud Messaging and NotificationChannel.
    """
    # Add Firebase Cloud Messaging
    with open("skills/notifications/android/fcm.md", "a") as f:
        f.write("\n## Firebase Cloud Messaging\n\n")
        f.write("To use Firebase Cloud Messaging, add the following dependencies to your `build.gradle` file:\n")
        f.write("