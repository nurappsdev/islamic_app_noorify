abstract class HadithEditPlanEvent {
  const HadithEditPlanEvent();
}

/// "Save": sends the edited fields of the plan [id] to
/// `PATCH /hadiths/plans/{id}`.
class SubmitHadithPlanEdit extends HadithEditPlanEvent {
  const SubmitHadithPlanEdit({
    required this.id,
    required this.name,
    required this.bookId,
    required this.categoryIds,
    required this.subCategoryIds,
    this.targetDays,
  });

  final String id;
  final String name;
  final String bookId;
  final List<String> categoryIds;
  final List<String> subCategoryIds;
  final int? targetDays;
}
