/// Pulls the Qiblah bearing (degrees clockwise from true north) out of the
/// dashboard API's `kiblahAngle` field, which arrives pre-formatted as
/// e.g. `"Kiblah 277.6° West"` rather than a bare number.
double? parseQiblahBearing(String? raw) {
  if (raw == null) return null;
  final match = RegExp(r'-?\d+(\.\d+)?').firstMatch(raw);
  if (match == null) return null;
  return double.tryParse(match.group(0)!);
}

/// Signed degrees to turn from [heading] to face [qiblahAngle], normalized
/// to (-180, 180]. Negative means turn left (counter-clockwise); positive
/// means turn right — the live "Kiblah -45° Left" readout on the full-screen
/// compass (design `img_41.png`).
double relativeQiblahBearing(double qiblahAngle, double heading) {
  var diff = (qiblahAngle - heading) % 360;
  if (diff > 180) diff -= 360;
  if (diff < -180) diff += 360;
  return diff;
}
