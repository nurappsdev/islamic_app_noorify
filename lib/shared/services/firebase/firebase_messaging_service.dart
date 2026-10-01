import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:tuhfatul_muslim/firebase_options.dart';
import 'package:tuhfatul_muslim/shared/services/firebase/local_notification_service.dart';

/// Firebase Messaging's background isolate entrypoint. Must stay a top-level
/// function (not a class method): the OS can launch it in a fresh isolate
/// where `main()` never ran, so Firebase is (re-)initialized here before
/// touching anything Firebase-related.
///
/// Nothing shows a notification here — Android/iOS already display the
/// system notification for the payload while the app is backgrounded or
/// terminated; this is only a hook for app-specific bookkeeping.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  if (kDebugMode) {
    debugPrint('[FCM][background] ${message.messageId}: ${message.data}');
  }
}

/// Wraps `FirebaseMessaging.instance`: permission, the device token, and the
/// foreground/opened-app message streams.
///
/// This never talks to the app's own backend — [FirebaseTokenService] (in
/// `firebase_token_service.dart`) owns pushing the token there, and whoever
/// needs to react to a tapped notification listens to [onNotificationTap].
class FirebaseMessagingService {
  FirebaseMessagingService._();

  static final FirebaseMessagingService instance =
      FirebaseMessagingService._();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  bool _initialized = false;

  final _notificationTapController =
      StreamController<RemoteMessage>.broadcast();

  /// Fires when the user taps a push notification while the app is running
  /// in the background (`onMessageOpenedApp`), or when a tap is what
  /// launched the app from a terminated state (`getInitialMessage`, replayed
  /// once [initialize] resolves).
  Stream<RemoteMessage> get onNotificationTap =>
      _notificationTapController.stream;

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;

  /// Requests permission and wires up every message listener. Safe to call
  /// once; later calls are ignored. Never throws — a push-notification setup
  /// failure must not block app startup.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await requestPermission();

      // The system tray already shows the notification while backgrounded;
      // this only stops iOS from presenting its own banner on top of the one
      // LocalNotificationService posts for a foreground message.
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: false,
      );

      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );

      _foregroundSub = FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );
      _openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen(
        _notificationTapController.add,
      );

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _notificationTapController.add(initialMessage);
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('FirebaseMessagingService.initialize failed: $e\n$st');
      }
    }
  }

  /// Asks the user for notification permission. Required on iOS/macOS/web;
  /// a no-op that reports "authorized" on Android below 13, where none is
  /// needed (Android 13+'s runtime permission is requested separately by
  /// [LocalNotificationService]).
  Future<NotificationSettings> requestPermission() {
    return _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// This device's current FCM token, or `null` when it isn't available yet
  /// (no Play Services, permission denied, still provisioning, or the
  /// Firebase Installations service is unreachable). Never throws.
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      if (kDebugMode) debugPrint('FirebaseMessagingService.getToken failed: $e');
      return null;
    }
  }

  /// Fires whenever the OS rotates this device's token (reinstall, cleared
  /// app data, token expiry).
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    final idSeed =
        message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();
    await LocalNotificationService.instance.showNotification(
      id: idSeed.hashCode & 0x7fffffff,
      title: notification.title ?? '',
      body: notification.body ?? '',
      payload: message.data.isEmpty ? null : message.data.toString(),
    );
  }

  /// Cancels every listener. There is exactly one instance for the app's
  /// lifetime, so normal app code never needs this — it exists for tests.
  Future<void> dispose() async {
    await _foregroundSub?.cancel();
    await _openedAppSub?.cancel();
    await _notificationTapController.close();
  }
}
