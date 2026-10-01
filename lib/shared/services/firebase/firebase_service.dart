import 'package:flutter/foundation.dart';

import 'package:tuhfatul_muslim/shared/services/firebase/firebase_messaging_service.dart';
import 'package:tuhfatul_muslim/shared/services/firebase/local_notification_service.dart';

/// Central Firebase bootstrap for everything beyond `Firebase.initializeApp()`
/// (already called in `main.dart` with the generated options). Wires the
/// local-notification plugin and Firebase Cloud Messaging together.
///
/// Named `AppFirebaseService` (not `FirebaseService`) because the
/// `firebase_core` package already exports its own `FirebaseService` marker
/// class, which the plain name collides with.
///
/// Call once, right after `Firebase.initializeApp()`, before `runApp`.
class AppFirebaseService {
  const AppFirebaseService._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // Local notifications first: FirebaseMessagingService's foreground
      // listener posts through it.
      await LocalNotificationService.instance.initialize();
      await FirebaseMessagingService.instance.initialize();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('AppFirebaseService.initialize failed: $e\n$st');
      }
    }
  }
}
