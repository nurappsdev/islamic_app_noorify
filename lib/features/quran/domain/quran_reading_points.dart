/// Quran Amol awards one point for each complete five minutes of reading.
///
/// Keeping this rule in the reading domain lets the offline projection use
/// the same duration logic as the tracked reading flow.
const kQuranReadingSecondsPerPoint = 5 * 60;

int quranReadingPointsForSeconds(int seconds) =>
    seconds <= 0 ? 0 : seconds ~/ kQuranReadingSecondsPerPoint;
