import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/features/home/data/models/highlight_card_model.dart';
import 'package:islami_app_noorify/features/home/data/models/pillar_card_model.dart';
import 'package:islami_app_noorify/features/home/data/models/user_summary_model.dart';
import 'package:islami_app_noorify/features/home/domain/entities/home_dashboard.dart';

/// Data-layer representation of [HomeDashboard], parsed from the `data`
/// payload of `GET /home/dashboard`.
class HomeDashboardModel extends HomeDashboard {
  const HomeDashboardModel({
    required super.userSummary,
    required super.topHighlightCards,
    required super.pillarCards,
  });

  factory HomeDashboardModel.fromJson(Map<String, dynamic> json) {
    final userSummaryJson = json['userSummary'];
    if (userSummaryJson is! Map<String, dynamic>) {
      throw ParsingException('Dashboard response is missing "userSummary".');
    }

    final cards = json['topHighlightCards'];
    final pillars = json['pillarCards'];

    return HomeDashboardModel(
      userSummary: UserSummaryModel.fromJson(userSummaryJson),
      topHighlightCards: cards is List
          ? cards
                .whereType<Map>()
                .map(
                  (e) =>
                      HighlightCardModel.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
      pillarCards: pillars is List
          ? pillars
                .whereType<Map>()
                .map(
                  (e) => PillarCardModel.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
    );
  }
}
