import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// The one channel every push notification is shown on while the app is in
/// the foreground. Background/terminated pushes are shown by the OS itself
/// straight from the FCM payload and never go through this plugin.
const _channelId = 'islami_app_noorify_push_v1';
const _channelName = 'Notifications';
const _channelDescription = 'General app notifications.';

/// Main-isolate handler for a tap on a notification this service posted.
/// Only relays the payload onto [LocalNotificationService.onNotificationTap]
/// — whoever cares about a specific payload subscribes to that.
void _handleForegroundTap(NotificationResponse response) {
  LocalNotificationService.instance._tapController.add(response.payload);
}

/// A tap that reached a background isolate instead of the running app.
/// Nothing app-specific to do for a plain notification (no action buttons),
/// so this only satisfies the plugin's requirement for an entrypoint.
@pragma('vm:entry-point')
void _handleBackgroundTap(NotificationResponse response) {}

/// Wraps `flutter_local_notifications`: the Android channel, and displaying
/// a notification for a foreground FCM message.
class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance =
      LocalNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _tapController = StreamController<String?>.broadcast();

  bool _initialized = false;

  /// The payload of every tapped notification shown by this service.
  Stream<String?> get onNotificationTap => _tapController.stream;

  /// Creates the notification channel and registers tap handling. Safe to
  /// call once; later calls are ignored. Never throws — a notification setup
  /// failure must not block app startup.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
          macOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: _handleForegroundTap,
        onDidReceiveBackgroundNotificationResponse: _handleBackgroundTap,
      );

      if (Platform.isAndroid) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        await android?.requestNotificationsPermission();
        await android?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.high,
          ),
        );
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('LocalNotificationService.initialize failed: $e\n$st');
      }
    }
  }

  /// Shows one notification on the shared channel.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('LocalNotificationService.showNotification failed: $e\n$st');
      }
    }
  }
}
