import 'package:flutter/foundation.dart';

final profileNameNotifier = ValueNotifier<String?>(null);
final profilePhotoUrlNotifier = ValueNotifier<String?>(null);
final profilePhotoBase64Notifier = ValueNotifier<String?>(null);
final skipAuthGateNotifier = ValueNotifier<bool>(false);

/// The signed-in user's unread notification count, kept in sync by
/// `NotificationBadgeService` and shown on the Home AppBar's bell icon.
final unreadNotificationCountNotifier = ValueNotifier<int>(0);

Future<void> saveAppPreferences() async {
  // Persistence can be wired here when the preferences store is available.
}
