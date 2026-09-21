import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_reading_history.dart';

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : const <String, dynamic>{};

double _double(Object? value) => (value as num?)?.toDouble() ?? 0;

String _text(Object? value) => value?.toString() ?? '';

/// `YYYY-MM-DD...` -> that calendar date; null when it isn't one.
DateTime? _date(Object? value) {
  final s = _text(value);
  if (s.length < 10) return null;
  final parsed = DateTime.tryParse(s.substring(0, 10));
  return parsed == null
      ? null
      : DateTime(parsed.year, parsed.month, parsed.day);
}

class HadithReadingDayModel extends HadithReadingDay {
  const HadithReadingDayModel({
    required super.date,
    required super.readMinutes,
    required super.goalMinutes,
    required super.hadithsRead,
    super.points,
  });

  static HadithReadingDayModel? tryParse(Map<String, dynamic> json) {
    final date = _date(json['date'] ?? json['day']);
    if (date == null) return null;
    return HadithReadingDayModel(
      date: date,
      readMinutes: _double(json['readMinutes']),
      goalMinutes: _double(json['goalMinutes']),
      hadithsRead: (json['hadithsRead'] as num?)?.toInt() ?? 0,
      points: _points(json),
    );
  }

  /// The day's points, under whichever key the backend uses; null if absent.
  static double? _points(Map<String, dynamic> json) {
    for (final key in const ['points', 'totalPoints', 'pointsEarned']) {
      final value = json[key];
      if (value is num) return value.toDouble();
    }
    return null;
  }
}

class HadithReadingHistoryModel extends HadithReadingHistory {
  const HadithReadingHistoryModel({required super.days, required super.totals});

  /// [data] is the envelope's `data`. The per-day list is found under
  /// `days` / `history` / `items` / `data` (or, failing those, the first list
  /// of objects), and `totals` supplies the totals.
  factory HadithReadingHistoryModel.fromJson(Map<String, dynamic> data) {
    final days = [
      for (final item in _dayList(data)) ?HadithReadingDayModel.tryParse(item),
    ]..sort((a, b) => a.date.compareTo(b.date));

    final totals = _map(data['totals']);
    // Where the backend leaves a total out, derive it from the days.
    final totalMinutes = totals['totalMinutes'] != null
        ? _double(totals['totalMinutes'])
        : days.fold<double>(0, (sum, d) => sum + d.readMinutes);
    final hadithsRead = totals['hadithsRead'] != null
        ? (totals['hadithsRead'] as num).toInt()
        : days.fold<int>(0, (sum, d) => sum + d.hadithsRead);

    // Same for the points: null only when nothing carries any.
    final dayPoints = [for (final d in days) ?d.points];
    final totalPoints = totals['totalPoints'] is num
        ? (totals['totalPoints'] as num).toDouble()
        : dayPoints.isEmpty
        ? null
        : dayPoints.fold<double>(0, (sum, p) => sum + p);

    return HadithReadingHistoryModel(
      days: days,
      totals: HadithReadingTotals(
        totalMinutes: totalMinutes,
        totalPoints: totalPoints,
        hadithsRead: hadithsRead,
        pointsText: _text(totals['pointsText'] ?? data['pointsText']),
        progressText: _text(totals['progressText'] ?? data['progressText']),
      ),
    );
  }

  static List<Map<String, dynamic>> _dayList(Map<String, dynamic> data) {
    for (final key in const ['days', 'history', 'items', 'data']) {
      final value = data[key];
      if (value is List) {
        return value.whereType<Map<String, dynamic>>().toList();
      }
    }
    for (final value in data.values) {
      if (value is List && value.isNotEmpty && value.first is Map) {
        return value.whereType<Map<String, dynamic>>().toList();
      }
    }
    return const [];
  }
}
