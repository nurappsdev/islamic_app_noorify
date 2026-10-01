/// A hadith reading plan as the user filled it in, ready to be created
/// (`POST /hadiths/plans`).
///
/// A plan belongs to one book and is built from that book's categories
/// (sections) and/or sub-categories (chapters); at least one must be given.
class HadithPlanDraft {
  const HadithPlanDraft({
    required this.name,
    required this.bookId,
    this.categoryIds = const [],
    this.subCategoryIds = const [],
    this.description,
    this.targetDays,
  });

  /// Unique per user; the API answers 409 when the name is taken.
  final String name;
  final String bookId;
  final List<String> categoryIds;
  final List<String> subCategoryIds;
  final String? description;

  /// Days the user aims to finish the plan in.
  final int? targetDays;

  /// The request body: only what was given, as the API treats the rest as
  /// optional.
  Map<String, dynamic> toJson() => {
    'name': name,
    'bookId': bookId,
    if (categoryIds.isNotEmpty) 'categoryIds': categoryIds,
    if (subCategoryIds.isNotEmpty) 'subCategoryIds': subCategoryIds,
    if (description != null && description!.trim().isNotEmpty)
      'description': description!.trim(),
    'targetDays': ?targetDays,
  };
}
