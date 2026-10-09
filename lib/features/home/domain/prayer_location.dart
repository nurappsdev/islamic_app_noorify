/// A resolved device location used to calculate and label prayer times.
///
/// Address fields are deliberately separate: a Bangladesh address can have an
/// upazila, district, and division, none of which should be replaced with a
/// fixed city name.
class PrayerLocation {
  const PrayerLocation({
    required this.latitude,
    required this.longitude,
    this.localArea,
    this.district,
    this.division,
    this.country,
  });

  final double latitude;
  final double longitude;
  final String? localArea;
  final String? district;
  final String? division;
  final String? country;

  /// A de-duplicated, human-readable address, e.g.
  /// “Bhaluka, Mymensingh, Bangladesh”.
  String get displayName {
    final parts = <String>[];
    for (final value in [localArea, district, division, country]) {
      final normalized = value?.trim();
      if (normalized != null &&
          normalized.isNotEmpty &&
          !parts.any(
            (part) =>
                _administrativeKey(part) == _administrativeKey(normalized),
          )) {
        parts.add(normalized);
      }
    }
    return parts.join(', ');
  }

  /// The most precise verified administrative name available. This is used in
  /// compact contexts such as the sunrise/sunset labels; it intentionally
  /// falls back to a district or city instead of inventing an upazila.
  String get shortDisplayName {
    for (final value in [localArea, district, division, country]) {
      final normalized = value?.trim();
      if (normalized != null && normalized.isNotEmpty) return normalized;
    }
    return '';
  }

  /// The location format used by the Amal tracker: the verified district (or
  /// city when a district is unavailable) and country only. It deliberately
  /// excludes sub-districts and divisions.
  String get districtCountryDisplayName {
    final parts = <String>[];
    for (final value in [district, country]) {
      final normalized = value?.trim();
      if (normalized != null &&
          normalized.isNotEmpty &&
          !parts.any(
            (part) =>
                _administrativeKey(part) == _administrativeKey(normalized),
          )) {
        parts.add(normalized);
      }
    }
    return parts.join(', ');
  }

  static String _administrativeKey(String value) => value
      .toLowerCase()
      .replaceFirst(RegExp(r'\s+(district|division)$'), '')
      .trim();

  String get cacheKey =>
      '${latitude.toStringAsFixed(3)},${longitude.toStringAsFixed(3)}';
}

enum PrayerLocationStatus {
  idle,
  locating,
  ready,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class PrayerLocationState {
  const PrayerLocationState({
    this.status = PrayerLocationStatus.idle,
    this.location,
  });

  final PrayerLocationStatus status;
  final PrayerLocation? location;
}
