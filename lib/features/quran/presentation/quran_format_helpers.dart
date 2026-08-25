import 'package:islami_app_noorify/core/utils/app_text.dart';

String revelationPlaceLabel(AppText appText, String rawPlace) {
  final normalized = rawPlace.toLowerCase();
  if (normalized.startsWith('mecc') || normalized.startsWith('makk')) {
    return appText.meccan;
  }
  if (normalized.startsWith('madin') || normalized.startsWith('medin')) {
    return appText.medinian;
  }
  return rawPlace;
}

String formatReadingTime(AppText appText, List<String> arabicAyahs) {
  final wordCount = arabicAyahs.fold<int>(
    0,
    (sum, ayah) => sum + ayah.trim().split(RegExp(r'\s+')).length,
  );
  final totalSeconds = (wordCount * 0.45).round();
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes ${appText.minLabel} $seconds ${appText.secLabel}';
}
