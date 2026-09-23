import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

import 'package:islami_app_noorify/features/qiblah_compass/data/services/magnetic_declination_service.dart';

enum QiblahAccess {
  checking,
  ready,
  serviceDisabled,
  permissionDenied,
  unsupported,
}

/// Owns one `flutter_compass` subscription + location-permission flow and
/// hands the live *true*-north heading to [builder]. Shared by the home
/// card's preview dial and the full-screen compass so both stay in sync
/// with the device's real heading instead of the home card showing a
/// frozen preview.
///
/// The raw sensor heading is magnetic on Android, so it's corrected to true
/// north with [MagneticDeclinationService] before being handed out — the
/// Qiblah bearing it's compared against is a true-north bearing, and
/// skipping this correction is what made the compass read off by the local
/// magnetic declination. The corrected heading is also angle-aware
/// exponentially smoothed to damp raw-sensor jitter, the way native compass
/// apps do rather than redrawing on every noisy sample.
///
/// [heading] and [accuracy] are only meaningful once `access` is
/// [QiblahAccess.ready]. [accuracy] is the sensor's estimated error in
/// degrees (lower is better); `null` means unknown.
class QiblahHeadingListener extends StatefulWidget {
  const QiblahHeadingListener({super.key, required this.builder});

  final Widget Function(
    BuildContext context,
    QiblahAccess access,
    double? heading,
    double? accuracy,
  )
  builder;

  @override
  State<QiblahHeadingListener> createState() => _QiblahHeadingListenerState();
}

class _QiblahHeadingListenerState extends State<QiblahHeadingListener>
    with WidgetsBindingObserver {
  /// Weight given to each new sample, 0-1: higher tracks the sensor more
  /// closely, lower damps jitter more but lags real turns more.
  static const _smoothingAlpha = 0.18;

  QiblahAccess _access = QiblahAccess.checking;
  StreamSubscription<CompassEvent>? _subscription;
  double? _heading;
  double? _accuracy;
  double _declination = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Location services/permission are commonly changed from the OS
    // settings screen the full-screen compass can send the user to.
    final awaitingSettings =
        _access == QiblahAccess.serviceDisabled ||
        _access == QiblahAccess.permissionDenied;
    if (state == AppLifecycleState.resumed && awaitingSettings) {
      _init();
    }
  }

  Future<void> _init() async {
    if (FlutterCompass.events == null) {
      if (mounted) setState(() => _access = QiblahAccess.unsupported);
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _access = QiblahAccess.serviceDisabled);
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _access = QiblahAccess.permissionDenied);
      return;
    }

    _declination = await _resolveDeclination();
    if (!mounted) return;

    await _subscription?.cancel();
    _subscription = FlutterCompass.events!.listen((event) {
      if (!mounted || event.heading == null) return;
      final corrected = (event.heading! + _declination) % 360;
      setState(() {
        _heading = _heading == null
            ? corrected
            : _smoothHeading(_heading!, corrected);
        _accuracy = event.accuracy != null && event.accuracy! >= 0
            ? event.accuracy
            : null;
        _access = QiblahAccess.ready;
      });
    });
  }

  /// Exponential smoothing that's aware headings wrap at 360°, so it always
  /// turns the short way round instead of spinning past 0/360.
  double _smoothHeading(double previous, double next) {
    final shortestDelta = (next - previous + 540) % 360 - 180;
    return (previous + shortestDelta * _smoothingAlpha + 360) % 360;
  }

  /// A single position fix is enough — declination barely moves over a
  /// city-sized area, so this doesn't need to track live location.
  Future<double> _resolveDeclination() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return await MagneticDeclinationService.declinationAt(
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
      );
    } catch (_) {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown == null) return 0;
      return MagneticDeclinationService.declinationAt(
        latitude: lastKnown.latitude,
        longitude: lastKnown.longitude,
        altitude: lastKnown.altitude,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _access, _heading, _accuracy);
}
