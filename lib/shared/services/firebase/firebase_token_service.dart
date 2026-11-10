import 'package:flutter/foundation.dart';

import 'package:tuhfatul_muslim/features/auth/data/datasources/fcm_token_remote_data_source.dart';
import 'package:tuhfatul_muslim/shared/services/firebase/firebase_messaging_service.dart';

/// The seam between Firebase Cloud Messaging and the app's own backend: gets
/// this device's current token and pushes it to (or removes it from) the
/// signed-in user's account.
///
/// [FirebaseMessagingService] owns everything Firebase-SDK-related; this
/// service is the only place that talks to the backend about the token, kept
/// separate so neither Firebase service ever calls the API directly.
class FirebaseTokenService {
  FirebaseTokenService._({FcmTokenRemoteDataSource? remote})
    : _remote = remote ?? FcmTokenRemoteDataSourceImpl();

  static final FirebaseTokenService instance = FirebaseTokenService._();

  final FcmTokenRemoteDataSource _remote;

  /// This device's current FCM token, or `null` when it isn't available.
  Future<String?> getToken() => FirebaseMessagingService.instance.getToken();

  /// Pushes this device's token to the backend for the signed-in user.
  /// Called after every sign-in/sign-up. Never throws — a failed
  /// registration must not block authentication.
  Future<void> registerCurrentToken() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return;
    try {
      await _remote.registerToken(token);
    } catch (e) {
      if (kDebugMode) debugPrint('FirebaseTokenService.register failed: $e');
    }
  }

  /// Removes this device's token from the backend before sign-out, so it
  /// stops receiving this user's pushes.
  Future<void> removeCurrentToken() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return;
    try {
      await _remote.removeToken(token);
    } catch (e) {
      if (kDebugMode) debugPrint('FirebaseTokenService.remove failed: $e');
    }
  }
}
