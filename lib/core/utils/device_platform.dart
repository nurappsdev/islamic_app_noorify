import 'package:flutter/foundation.dart';

/// The platform name the backend expects alongside an FCM token
/// (`android`, `ios` or `web`).
String get devicePlatform {
  if (kIsWeb) return 'web';
  return defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
}
