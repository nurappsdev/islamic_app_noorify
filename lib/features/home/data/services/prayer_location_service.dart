import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geocoding/geocoding.dart' as geocoding show setLocaleIdentifier;
import 'package:geolocator/geolocator.dart';

import 'package:tuhfatul_muslim/features/home/domain/prayer_location.dart';

/// Resolves the device's current GPS position to the local administrative
/// address used on prayer cards. Native reverse geocoding is used, so no
/// Google Maps key is required.
class PrayerLocationService extends ChangeNotifier {
  PrayerLocationService({
    Future<bool> Function()? isServiceEnabled,
    Future<LocationPermission> Function()? checkPermission,
    Future<LocationPermission> Function()? requestPermission,
    Future<Position> Function()? currentPosition,
    Stream<Position> Function(LocationSettings settings)? positionStream,
    Future<List<Placemark>> Function(double latitude, double longitude)?
    reverseGeocode,
    Future<void> Function(String localeIdentifier)? setGeocodingLocale,
  }) : _isServiceEnabled =
           isServiceEnabled ?? Geolocator.isLocationServiceEnabled,
       _checkPermission = checkPermission ?? Geolocator.checkPermission,
       _requestPermission = requestPermission ?? Geolocator.requestPermission,
       _currentPosition = currentPosition ?? _defaultCurrentPosition,
       _positionStream = positionStream ?? _defaultPositionStream,
       _reverseGeocode = reverseGeocode ?? placemarkFromCoordinates,
       _setGeocodingLocale =
           setGeocodingLocale ?? geocoding.setLocaleIdentifier;

  static final PrayerLocationService instance = PrayerLocationService();

  final Future<bool> Function() _isServiceEnabled;
  final Future<LocationPermission> Function() _checkPermission;
  final Future<LocationPermission> Function() _requestPermission;
  final Future<Position> Function() _currentPosition;
  final Stream<Position> Function(LocationSettings settings) _positionStream;
  final Future<List<Placemark>> Function(double latitude, double longitude)
  _reverseGeocode;
  final Future<void> Function(String localeIdentifier) _setGeocodingLocale;

  PrayerLocationState _state = const PrayerLocationState();
  Future<void>? _starting;
  DateTime? _lastResolvedAt;
  StreamSubscription<Position>? _positionSubscription;
  String? _localeIdentifier;

  PrayerLocationState get state => _state;

  static Future<Position> _defaultCurrentPosition() =>
      Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

  static Stream<Position> _defaultPositionStream(LocationSettings settings) =>
      Geolocator.getPositionStream(locationSettings: settings);

  /// Requests permission the first time it is needed, resolves the current
  /// fix immediately. Callers refresh this when their route becomes visible
  /// or the app resumes, which keeps the label current without an always-on
  /// GPS subscription.
  Future<void> start({bool force = false}) {
    // Moving from the home card into the full prayer-times screen should reuse
    // the fix that was just resolved. A resume deliberately bypasses this
    // short window so a device that moved while backgrounded is refreshed.
    final lastResolvedAt = _lastResolvedAt;
    if (!force &&
        _state.status == PrayerLocationStatus.ready &&
        lastResolvedAt != null &&
        DateTime.now().difference(lastResolvedAt) <
            const Duration(minutes: 1)) {
      return Future.value();
    }
    final existing = _starting;
    if (existing != null) return existing;
    final future = _start();
    _starting = future;
    return future.whenComplete(() => _starting = null);
  }

  /// Makes future native reverse-geocoding responses match the app language.
  /// If an address has already been resolved, it is immediately re-geocoded
  /// at the same coordinate so the visible district/country also changes.
  Future<void> setLocaleIdentifier(String localeIdentifier) async {
    if (_localeIdentifier == localeIdentifier) return;
    try {
      await _setGeocodingLocale(localeIdentifier);
      _localeIdentifier = localeIdentifier;
      final location = _state.location;
      if (location != null) {
        await _resolveCoordinates(
          location.latitude,
          location.longitude,
          force: true,
        );
      }
    } catch (_) {
      // A platform that cannot set a geocoder locale still returns its
      // verified native address instead of a fabricated translation.
    }
  }

  Future<void> _start() async {
    try {
      if (!await _isServiceEnabled()) {
        await stopMonitoring();
        _setState(
          const PrayerLocationState(
            status: PrayerLocationStatus.serviceDisabled,
          ),
        );
        return;
      }

      var permission = await _checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        await stopMonitoring();
        _setState(
          const PrayerLocationState(
            status: PrayerLocationStatus.permissionDeniedForever,
          ),
        );
        return;
      }
      if (permission == LocationPermission.denied) {
        await stopMonitoring();
        _setState(
          const PrayerLocationState(
            status: PrayerLocationStatus.permissionDenied,
          ),
        );
        return;
      }

      _setState(
        PrayerLocationState(
          status: PrayerLocationStatus.locating,
          location: _state.location,
        ),
      );
      await _resolvePosition(await _currentPosition());
      await _startMonitoring();
    } catch (_) {
      await stopMonitoring();
      _setState(
        const PrayerLocationState(status: PrayerLocationStatus.unavailable),
      );
    }
  }

  /// Watches for meaningful movement while the app is foregrounded. Reverse
  /// geocoding only runs after at least 100m, so this does not continuously
  /// query GPS or geocode the same district.
  Future<void> _startMonitoring() async {
    await stopMonitoring();
    _positionSubscription =
        _positionStream(
          const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 100,
          ),
        ).listen(
          (position) => unawaited(_resolvePosition(position)),
          onError: (_) {},
        );
  }

  /// Stops foreground movement monitoring while the application is paused.
  Future<void> stopMonitoring() async {
    final subscription = _positionSubscription;
    _positionSubscription = null;
    await subscription?.cancel();
  }

  Future<void> _resolvePosition(Position position) =>
      _resolveCoordinates(position.latitude, position.longitude);

  Future<void> _resolveCoordinates(
    double latitude,
    double longitude, {
    bool force = false,
  }) async {
    final previous = _state.location;
    if (!force &&
        previous != null &&
        Geolocator.distanceBetween(
              previous.latitude,
              previous.longitude,
              latitude,
              longitude,
            ) <
            100) {
      _setState(
        PrayerLocationState(
          status: PrayerLocationStatus.ready,
          location: previous,
        ),
      );
      _lastResolvedAt = DateTime.now();
      return;
    }
    try {
      final placemarks = await _reverseGeocode(latitude, longitude);
      if (placemarks.isEmpty) throw const FormatException('No address found');
      final placemark = placemarks.first;
      _setState(
        PrayerLocationState(
          status: PrayerLocationStatus.ready,
          location: PrayerLocation(
            latitude: latitude,
            longitude: longitude,
            localArea: _firstNonEmpty([
              placemark.subLocality,
              placemark.locality,
            ]),
            district: _firstNonEmpty([
              placemark.subAdministrativeArea,
              placemark.locality,
            ]),
            division: placemark.administrativeArea,
            country: placemark.country,
          ),
        ),
      );
      _lastResolvedAt = DateTime.now();
    } catch (_) {
      _setState(
        const PrayerLocationState(status: PrayerLocationStatus.unavailable),
      );
    }
  }

  static String? _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  void _setState(PrayerLocationState value) {
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(stopMonitoring());
    super.dispose();
  }
}
