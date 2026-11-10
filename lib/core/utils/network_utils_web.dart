import 'package:web/web.dart' as web;

class NetworkUtils {
  const NetworkUtils._();

  /// Browser connectivity is only a hint. It must never be used to label a
  /// failed API request as "No Internet" because CORS, DNS, TLS, and server
  /// failures can all fail a fetch while this remains true.
  static Future<bool> hasInternet({
    Duration timeout = const Duration(seconds: 4),
  }) async => web.window.navigator.onLine;
}
