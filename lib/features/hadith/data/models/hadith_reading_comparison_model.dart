import 'package:islami_app_noorify/features/hadith/data/models/hadith_reading_history_model.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_reading_comparison.dart';

class HadithCompetitorModel extends HadithCompetitor {
  const HadithCompetitorModel({
    required super.name,
    required super.avatarUrl,
    required super.rank,
    required super.totalPoints,
    required super.days,
  });

  /// [json] is one entry of `data.users`.
  factory HadithCompetitorModel.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'];
    final totalPoints = json['totalPoints'] is num
        ? json['totalPoints'] as num
        : (totals is Map && totals['totalPoints'] is num
              ? totals['totalPoints'] as num
              : 0);
    final days = json['days'];
    return HadithCompetitorModel(
      name: json['name']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString() ?? '',
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      totalPoints: totalPoints.toDouble(),
      days: [
        if (days is List)
          for (final day in days.whereType<Map<String, dynamic>>())
            ?HadithReadingDayModel.tryParse(day),
      ],
    );
  }
}

class HadithReadingComparisonModel extends HadithReadingComparison {
  const HadithReadingComparisonModel({
    required super.comparedWith,
    required super.competitor,
  });

  /// [data] is the envelope's `data`; the competitor is the first entry of
  /// `users` that isn't the current user.
  factory HadithReadingComparisonModel.fromJson(Map<String, dynamic> data) {
    final users = data['users'];
    final others = [
      if (users is List)
        for (final user in users.whereType<Map<String, dynamic>>())
          if (user['isCurrentUser'] != true) user,
    ];
    return HadithReadingComparisonModel(
      comparedWith: data['comparedWith']?.toString() ?? '',
      competitor: others.isEmpty
          ? null
          : HadithCompetitorModel.fromJson(others.first),
    );
  }
}
