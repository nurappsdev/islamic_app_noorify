import 'dart:io';

import 'package:flutter/services.dart';

/// Android's rotation-vector sensor (what `flutter_compass` reads there)
/// reports heading relative to *magnetic* north with no correction; iOS's
/// `CLHeading.trueHeading` (what `flutter_compass` already surfaces there)
/// is corrected to *true* north already via Core Location's own geomagnetic
/// model. The Qiblah bearing from the dashboard API is a true-north
/// bearing, so on Android the raw magnetic heading must be corrected by the
/// local declination first, or the compass reads off by however many
/// degrees magnetic north differs from true north at that location —
/// several degrees almost everywhere, and 15-20+ in some regions.
abstract final class MagneticDeclinationService {
  static const _channel = MethodChannel('islami_app_noorify/geomagnetic');

  /// Degrees to add to a magnetic heading to get true heading at
  /// [latitude]/[longitude]. Always `0` on iOS, where the heading `flutter_compass`
  /// reports is already true.
  static Future<double> declinationAt({
    required double latitude,
    required double longitude,
    double altitude = 0,
  }) async {
    if (!Platform.isAndroid) return 0;
    try {
      final result = await _channel.invokeMethod<double>('declination', {
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
      });
      return result ?? 0;
    } on PlatformException {
      return 0;
    } on MissingPluginException {
      return 0;
    }
  }
}
