import 'package:flutter/foundation.dart';

final profileNameNotifier = ValueNotifier<String?>(null);
final profilePhotoUrlNotifier = ValueNotifier<String?>(null);
final profilePhotoBase64Notifier = ValueNotifier<String?>(null);
final skipAuthGateNotifier = ValueNotifier<bool>(false);

Future<void> saveAppPreferences() async {
  // Persistence can be wired here when the preferences store is available.
}
