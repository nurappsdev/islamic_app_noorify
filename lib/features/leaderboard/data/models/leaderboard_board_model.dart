import 'package:islami_app_noorify/features/leaderboard/data/models/leaderboard_entry_model.dart';
import 'package:islami_app_noorify/features/leaderboard/domain/entities/leaderboard_board.dart';

class LeaderboardPeriodModel extends LeaderboardPeriod {
  const LeaderboardPeriodModel({
    required super.type,
    required super.key,
    required super.label,
    required super.from,
    required super.to,
  });

  factory LeaderboardPeriodModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardPeriodModel(
      type: json['type']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
    );
  }
}

class LeaderboardMetaModel extends LeaderboardMeta {
  const LeaderboardMetaModel({
    required super.limit,
    required super.totalParticipants,
    required super.isCurrentUserInTop,
  });

  factory LeaderboardMetaModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardMetaModel(
      limit: (json['limit'] as num?)?.toInt() ?? 10,
      totalParticipants: (json['totalParticipants'] as num?)?.toInt() ?? 0,
      isCurrentUserInTop: json['isCurrentUserInTop'] == true,
    );
  }
}

class LeaderboardMyPositionModel extends LeaderboardMyPosition {
  const LeaderboardMyPositionModel({
    required super.rank,
    required super.points,
    super.name,
    super.avatarUrl,
    super.pointsToNextRank,
    super.nextRank,
  });

  /// The exact key names the server uses for the point-gap-to-next-rank
  /// figure aren't pinned down yet, so a few plausible ones are tried;
  /// missing keys just leave the caption off the "Your Rank" card.
  factory LeaderboardMyPositionModel.fromJson(Map<String, dynamic> json) {
    num? readNum(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is num) return value;
      }
      return null;
    }

    return LeaderboardMyPositionModel(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      points: (json['points'] as num?) ?? 0,
      name: json['name']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      pointsToNextRank: readNum([
        'pointsToNextRank',
        'gapToNextRank',
        'nextRankPoints',
        'pointsToNextRankGap',
      ]),
      nextRank: readNum(['nextRank', 'nextRankPosition'])?.toInt(),
    );
  }
}

class LeaderboardBoardModel extends LeaderboardBoard {
  const LeaderboardBoardModel({
    required super.period,
    required super.meta,
    required super.entries,
    required super.isRanked,
    super.myPosition,
  });

  factory LeaderboardBoardModel.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['data'];
    final entries = rawEntries is List
        ? rawEntries
              .whereType<Map>()
              .map(
                (e) => LeaderboardEntryModel.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
        : const <LeaderboardEntryModel>[];

    final rawPeriod = json['period'];
    final period = rawPeriod is Map
        ? LeaderboardPeriodModel.fromJson(Map<String, dynamic>.from(rawPeriod))
        : const LeaderboardPeriodModel(
            type: '',
            key: '',
            label: '',
            from: '',
            to: '',
          );

    final rawMeta = json['meta'];
    final meta = rawMeta is Map
        ? LeaderboardMetaModel.fromJson(Map<String, dynamic>.from(rawMeta))
        : const LeaderboardMetaModel(
            limit: 10,
            totalParticipants: 0,
            isCurrentUserInTop: false,
          );

    final rawMyPosition = json['myPosition'];
    final myPosition = rawMyPosition is Map
        ? LeaderboardMyPositionModel.fromJson(
            Map<String, dynamic>.from(rawMyPosition),
          )
        : null;

    return LeaderboardBoardModel(
      period: period,
      meta: meta,
      entries: entries,
      isRanked: json['isRanked'] == true,
      myPosition: myPosition,
    );
  }
}
