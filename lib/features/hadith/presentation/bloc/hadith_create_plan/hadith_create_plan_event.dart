import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_plan_draft.dart';

abstract class HadithCreatePlanEvent {
  const HadithCreatePlanEvent();
}

/// The "Create" button: sends [draft] to `POST /hadiths/plans`.
class SubmitHadithPlan extends HadithCreatePlanEvent {
  const SubmitHadithPlan(this.draft);

  final HadithPlanDraft draft;
}
