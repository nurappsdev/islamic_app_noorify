import 'package:islami_app_noorify/features/home/domain/entities/highlight_card.dart';
import 'package:islami_app_noorify/features/home/domain/entities/pillar_card.dart';
import 'package:islami_app_noorify/features/home/domain/entities/user_summary.dart';

/// The full payload of `GET /home/dashboard`.
class HomeDashboard {
  const HomeDashboard({
    required this.userSummary,
    required this.topHighlightCards,
    required this.pillarCards,
  });

  final UserSummary userSummary;
  final List<HighlightCard> topHighlightCards;
  final List<PillarCard> pillarCards;
}
