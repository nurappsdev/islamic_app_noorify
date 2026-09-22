import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/hadith/data/datasources/hadith_library_remote_data_source.dart';
import 'package:islami_app_noorify/features/hadith/data/repositories/hadith_library_repository_impl.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_category.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_library_book.dart';
import 'package:islami_app_noorify/features/hadith/domain/repositories/hadith_library_repository.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/update_hadith_plan.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_edit_plan/hadith_edit_plan_bloc.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_list_scaffold.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_plan_pickers.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

/// Route arguments for [HadithEditPlanScreen] — the plan's current values,
/// so the form opens pre-filled.
class HadithEditPlanArgs {
  const HadithEditPlanArgs({
    required this.planId,
    required this.name,
    required this.bookId,
    required this.bookTitle,
    required this.categoryIds,
    this.targetDays,
  });

  final String planId;
  final String name;

  /// The plan's book and its title (in the app's language), to open on.
  final String bookId;
  final String bookTitle;
  final List<String> categoryIds;
  final int? targetDays;
}

/// Edit-plan form for the Hadith planner, matching [HadithCreatePlanScreen]'s
/// design.
///
/// Reached from the planner's ⋮ > Edit. Pre-filled with the plan's current
/// name, target days, book and categories, all of which can be changed —
/// picking a different book clears the categories, since they belong to it.
/// "Save" sends the whole form to `PATCH /hadiths/plans/{id}` (`{name,
/// bookId, categoryIds, subCategoryIds, targetDays}`). On success the screen
/// pops with `true`, so the planner reloads; on failure it stays open and
/// shows the API's message.
class HadithEditPlanScreen extends StatelessWidget {
  const HadithEditPlanScreen({super.key, required this.args, this.repository});

  final HadithEditPlanArgs args;

  /// Where categories and the edit go; the real API unless a test supplies
  /// one.
  final HadithLibraryRepository? repository;

  @override
  Widget build(BuildContext context) {
    final repo =
        repository ??
        HadithLibraryRepositoryImpl(HadithLibraryRemoteDataSourceImpl());
    return BlocProvider(
      create: (_) => HadithEditPlanBloc(UpdateHadithPlan(repo)),
      child: _EditPlanView(args: args, repository: repo),
    );
  }
}

class _EditPlanView extends StatefulWidget {
  const _EditPlanView({required this.args, required this.repository});

  final HadithEditPlanArgs args;
  final HadithLibraryRepository repository;

  @override
  State<_EditPlanView> createState() => _EditPlanViewState();
}

class _EditPlanViewState extends State<_EditPlanView> {
  late final _nameController = TextEditingController(text: widget.args.name);
  late final _targetDaysController = TextEditingController(
    text: widget.args.targetDays?.toString() ?? '',
  );

  /// The book the plan is built from right now; changed by "Book".
  late String _bookId = widget.args.bookId;
  late String _bookTitle = widget.args.bookTitle;

  /// The category ids on the plan right now; edited by "Add" and each card's
  /// remove button, and cleared when the book changes.
  late final List<String> _categoryIds = [...widget.args.categoryIds];

  /// Titles and hadith counts resolved for ids in [_categoryIds], keyed by
  /// id — filled in from the book's own category list at [initState], and
  /// from whatever the picker returns when "Add" is used. An id with no
  /// entry here still submits normally; its card just falls back to a plain
  /// label instead of the resolved name.
  final _resolved = <String, HadithCategory>{};

  bool _resolvingNames = true;

  @override
  void initState() {
    super.initState();
    _resolveCategoryNames();
  }

  Future<void> _resolveCategoryNames() async {
    final result = await widget.repository.getCategories(
      widget.args.bookId,
      page: 1,
      // Comfortably above a book's usual chapter count; an id that still
      // doesn't resolve just shows the fallback card.
      limit: 100,
    );
    if (!mounted) return;
    result.fold((_) {}, (page) {
      for (final category in page.categories) {
        if (_categoryIds.contains(category.id)) {
          _resolved[category.id] = category;
        }
      }
    });
    setState(() => _resolvingNames = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetDaysController.dispose();
    super.dispose();
  }

  String get _planName {
    final name = _nameController.text.trim();
    return name.isEmpty ? widget.args.name : name;
  }

  /// The days the user aims to finish in, or null when the field is empty (or
  /// not a positive number).
  int? get _targetDays {
    final days = int.tryParse(_targetDaysController.text.trim());
    return days != null && days > 0 ? days : null;
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickBook() async {
    final book = await showModalBottomSheet<HadithLibraryBook>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HadithBookPickerSheet(
        repository: widget.repository,
        selectedId: _bookId,
      ),
    );
    if (book == null || !mounted) return;
    final bangla =
        context.read<LanguageBloc>().state.language == AppLanguage.bangla;
    setState(() {
      // Categories belong to their book, so another book starts over.
      if (_bookId != book.id) {
        _categoryIds.clear();
        _resolved.clear();
      }
      _bookId = book.id;
      _bookTitle = hadithBookTitle(book, bangla: bangla);
    });
  }

  Future<void> _addCategory() async {
    final category = await showModalBottomSheet<HadithCategory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HadithCategoryPickerSheet(
        repository: widget.repository,
        bookId: _bookId,
      ),
    );
    if (category == null || !mounted) return;
    setState(() {
      _resolved[category.id] = category;
      if (!_categoryIds.contains(category.id)) _categoryIds.add(category.id);
    });
  }

  void _removeCategory(String id) {
    setState(() {
      _categoryIds.remove(id);
      _resolved.remove(id);
    });
  }

  /// "Save": at least one category must stay on the plan.
  void _save() {
    if (_categoryIds.isEmpty) {
      _snack(AppText.readOf(context).selectCategory);
      return;
    }
    context.read<HadithEditPlanBloc>().add(
      SubmitHadithPlanEdit(
        id: widget.args.planId,
        name: _planName,
        bookId: _bookId,
        categoryIds: _categoryIds,
        subCategoryIds: const [],
        targetDays: _targetDays,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final submitting = context.watch<HadithEditPlanBloc>().state.isSubmitting;

    return BlocListener<HadithEditPlanBloc, HadithEditPlanState>(
      listener: (context, state) {
        if (state.status == HadithEditPlanStatus.success) {
          // The planner reloads both lists on a truthy result.
          Navigator.of(context).pop(true);
        } else if (state.status == HadithEditPlanStatus.failure) {
          _snack(state.failure?.message ?? '');
        }
      },
      child: Scaffold(
        backgroundColor: context.pageColor(Colors.white),
        body: SafeArea(
          child: Column(
            children: [
              _EditPlanHeader(
                title: appText.planEditTitle,
                onBack: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: _EditPlanForm(
                  nameController: _nameController,
                  targetDaysController: _targetDaysController,
                  bookTitle: _bookTitle,
                  categoryIds: _categoryIds,
                  resolved: _resolved,
                  resolvingNames: _resolvingNames,
                  onPickBook: _pickBook,
                  onAdd: _addCategory,
                  onRemove: _removeCategory,
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 9.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: FilledButton(
                    // Off while the request runs, so a second tap can't send
                    // the edit twice.
                    onPressed: submitting ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFA1AD59),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFA1AD59),
                      disabledForegroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28.r),
                      ),
                    ),
                    child: submitting
                        ? SizedBox.square(
                            dimension: 22.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            appText.saveAction,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditPlanForm extends StatelessWidget {
  const _EditPlanForm({
    required this.nameController,
    required this.targetDaysController,
    required this.bookTitle,
    required this.categoryIds,
    required this.resolved,
    required this.resolvingNames,
    required this.onPickBook,
    required this.onAdd,
    required this.onRemove,
  });

  final TextEditingController nameController;
  final TextEditingController targetDaysController;

  /// The plan's current book; tapping opens the book picker.
  final String bookTitle;

  final List<String> categoryIds;
  final Map<String, HadithCategory> resolved;

  /// Whether [resolved] is still being filled in from the API.
  final bool resolvingNames;

  final VoidCallback onPickBook;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(15.w, 5.h, 15.w, 20.h),
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(appText.planNameLabel, style: TextStyle(fontSize: 14.sp)),
        ),
        SizedBox(height: 9.h),
        TextField(
          key: const Key('edit-plan-name-field'),
          controller: nameController,
          style: TextStyle(fontSize: 13.sp),
          decoration: _fieldDecoration(context, appText.writeHereHint),
        ),
        SizedBox(height: 16.h),
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            appText.planTargetDaysLabel,
            style: TextStyle(fontSize: 14.sp),
          ),
        ),
        SizedBox(height: 9.h),
        // Whole days only: digits, up to four of them.
        TextFormField(
          key: const Key('edit-target-days-field'),
          controller: targetDaysController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          style: TextStyle(fontSize: 13.sp),
          decoration: _fieldDecoration(context, appText.planTargetDaysHint),
        ),
        SizedBox(height: 14.h),
        Container(
          padding: EdgeInsets.fromLTRB(23.w, 28.h, 23.w, 24.h),
          decoration: BoxDecoration(
            border: Border.all(color: context.lineColor(Color(0xFFCBD16B))),
            borderRadius: BorderRadius.circular(27.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appText.selectHadithBook,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 16.h),
              _EditSelectionField(value: bookTitle, onTap: onPickBook),
              SizedBox(height: 22.h),
              Text(
                appText.selectCategory,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 16.h),
              if (resolvingNames)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: const Center(child: CircularProgressIndicator()),
                )
              else if (categoryIds.isEmpty)
                Text(
                  appText.selectCategory,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFFB8B8B8),
                  ),
                )
              else
                for (final id in categoryIds) ...[
                  _EditCategoryCard(
                    category: resolved[id],
                    onRemove: () => onRemove(id),
                  ),
                  SizedBox(height: 10.h),
                ],
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(top: 14.h, right: 2.w),
            child: OutlinedButton(
              onPressed: onAdd,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFA1AD59),
                minimumSize: Size(69.w, 38.h),
                padding: EdgeInsets.zero,
                side: const BorderSide(color: Color(0xFFA1AD59)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
              child: Text(appText.add, style: TextStyle(fontSize: 14.sp)),
            ),
          ),
        ),
      ],
    );
  }
}

/// One category already on the plan, with a remove button. [category] is
/// null when its name hasn't resolved (still shown, still removable).
class _EditCategoryCard extends StatelessWidget {
  const _EditCategoryCard({required this.category, required this.onRemove});

  final HadithCategory? category;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final category = this.category;
    final bangla =
        context.watch<LanguageBloc>().state.language == AppLanguage.bangla;
    return Container(
      constraints: BoxConstraints(minHeight: 76.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        border: Border.all(color: context.lineColor(Color(0xFFDDE8C1))),
        borderRadius: BorderRadius.circular(21.r),
      ),
      child: Row(
        children: [
          Container(
            width: 47.w,
            height: 47.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: context.lineColor(Color(0xFFDDE8C1))),
            ),
            child: Icon(
              Icons.menu_book_outlined,
              color: context.inkColor(Color(0xFF8B9865)),
              size: 22.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category == null
                      ? appText.selectCategory
                      : hadithCategoryTitle(category, bangla: bangla),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.inkColor(Color(0xFF332B57)),
                    fontSize: 14.sp,
                  ),
                ),
                if (category != null) ...[
                  SizedBox(height: 7.h),
                  Text(
                    '${formatHadithCount(category.totalHadiths)} '
                    '${appText.categoryHadith}',
                    style: TextStyle(
                      color: const Color(0xFFA1AD59),
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: Icon(
              Icons.close_rounded,
              size: 18.sp,
              color: const Color(0xFFC15B4B),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditPlanHeader extends StatelessWidget {
  const _EditPlanHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 14.w),
              child: IconButton(
                onPressed: onBack,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFCBD16B),
                  foregroundColor: context.inkColor(Color(0xFF303629)),
                  minimumSize: Size(38.r, 38.r),
                  padding: EdgeInsets.zero,
                ),
                icon: Icon(Icons.arrow_back_ios_new_rounded, size: 15.sp),
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: context.inkColor(Color(0xFF84945F)),
              fontSize: 18.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// The tappable "Book" field: shows the currently picked book and opens the
/// picker on tap.
class _EditSelectionField extends StatelessWidget {
  const _EditSelectionField({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48.h,
        padding: EdgeInsets.symmetric(horizontal: 15.w),
        decoration: BoxDecoration(
          border: Border.all(color: context.lineColor(Color(0xFFDDE8C1))),
          borderRadius: BorderRadius.circular(25.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.inkColor(const Color(0xFF2C3320)),
                  fontSize: 13.sp,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: const Color(0xFFA1AD59),
              size: 22.sp,
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration(BuildContext context, String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFB8B8B8)),
    contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: context.lineColor(Color(0xFFDDE8C1))),
      borderRadius: BorderRadius.circular(25.r),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFFA1AD59)),
      borderRadius: BorderRadius.circular(25.r),
    ),
  );
}
