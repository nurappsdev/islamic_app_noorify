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
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_plan_draft.dart';
import 'package:islami_app_noorify/features/hadith/domain/repositories/hadith_library_repository.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/create_hadith_plan.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_create_plan/hadith_create_plan_bloc.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_list_scaffold.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_plan_pickers.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

/// Create-plan form for the Hadith planner.
///
/// Reached from the "Create Plan" action on [HadithPlannerScreen]. The user
/// names the plan, picks a hadith book and one or more of its categories
/// ("Add" / "Add More"), and "Create" sends them to `POST /hadiths/plans`.
/// On success the screen pops with the plan's name, so the planner can show
/// the new plan; on failure it stays open and shows the API's message (e.g.
/// the name is already taken).
class HadithCreatePlanScreen extends StatelessWidget {
  const HadithCreatePlanScreen({super.key, this.repository});

  /// Where books, categories and the new plan go; the real API unless a test
  /// supplies one.
  final HadithLibraryRepository? repository;

  @override
  Widget build(BuildContext context) {
    final repo =
        repository ??
        HadithLibraryRepositoryImpl(HadithLibraryRemoteDataSourceImpl());
    return BlocProvider(
      create: (_) => HadithCreatePlanBloc(CreateHadithPlan(repo)),
      child: _CreatePlanView(repository: repo),
    );
  }
}

class _CreatePlanView extends StatefulWidget {
  const _CreatePlanView({required this.repository});

  final HadithLibraryRepository repository;

  @override
  State<_CreatePlanView> createState() => _CreatePlanViewState();
}

class _CreatePlanViewState extends State<_CreatePlanView> {
  final _planNameController = TextEditingController();
  final _targetDaysController = TextEditingController();

  /// Whether the "added" list is showing instead of the form.
  bool _added = false;

  /// The book the plan is built from. A plan belongs to one book.
  HadithLibraryBook? _book;

  /// The category picked but not yet added with "Add".
  HadithCategory? _pending;

  /// The categories added so far.
  final _categories = <HadithCategory>[];

  @override
  void dispose() {
    _planNameController.dispose();
    _targetDaysController.dispose();
    super.dispose();
  }

  String get _planName {
    final name = _planNameController.text.trim();
    return name.isEmpty ? 'Plan 1' : name;
  }

  /// The days the user aims to finish in, or null when the field is empty (or
  /// not a positive number), in which case it isn't sent.
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
        selectedId: _book?.id,
      ),
    );
    if (book == null || !mounted) return;
    setState(() {
      // Categories belong to their book, so another book starts over.
      if (_book?.id != book.id) {
        _pending = null;
        _categories.clear();
        _added = false;
      }
      _book = book;
    });
  }

  Future<void> _pickCategory() async {
    final book = _book;
    if (book == null) {
      _snack(AppText.readOf(context).selectHadithBook);
      return;
    }
    final category = await showModalBottomSheet<HadithCategory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HadithCategoryPickerSheet(
        repository: widget.repository,
        bookId: book.id,
        selectedId: _pending?.id,
      ),
    );
    if (category == null || !mounted) return;
    setState(() => _pending = category);
  }

  /// "Add": puts the picked category on the plan.
  void _add() {
    final category = _pending;
    if (category == null) {
      final appText = AppText.readOf(context);
      _snack(_book == null ? appText.selectHadithBook : appText.selectCategory);
      return;
    }
    setState(() {
      if (!_categories.any((c) => c.id == category.id)) {
        _categories.add(category);
      }
      _pending = null;
      _added = true;
    });
  }

  /// "Create": sends the plan to the API. A category that was picked but not
  /// added yet is included, so the user needn't press "Add" first.
  void _create() {
    final appText = AppText.readOf(context);
    final book = _book;
    if (book == null) {
      _snack(appText.selectHadithBook);
      return;
    }
    final ids = [for (final c in _categories) c.id];
    final pending = _pending;
    if (pending != null && !ids.contains(pending.id)) ids.add(pending.id);
    if (ids.isEmpty) {
      _snack(appText.selectCategory);
      return;
    }
    context.read<HadithCreatePlanBloc>().add(
      SubmitHadithPlan(
        HadithPlanDraft(
          name: _planName,
          bookId: book.id,
          categoryIds: ids,
          targetDays: _targetDays,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bangla =
        context.watch<LanguageBloc>().state.language == AppLanguage.bangla;
    final submitting = context.watch<HadithCreatePlanBloc>().state.isSubmitting;
    final book = _book;

    return BlocListener<HadithCreatePlanBloc, HadithCreatePlanState>(
      listener: (context, state) {
        if (state.status == HadithCreatePlanStatus.success) {
          // The planner shows the new plan under this name.
          Navigator.of(context).pop(state.planName);
        } else if (state.status == HadithCreatePlanStatus.failure) {
          _snack(state.failure?.message ?? '');
        }
      },
      child: Scaffold(
        backgroundColor: context.pageColor(Colors.white),
        body: SafeArea(
          child: Column(
            children: [
              _CreatePlanHeader(
                title: appText.hadithCreatePlanTitle,
                onBack: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: _added
                    ? _AddedView(
                        planName: _planName,
                        bookTitle: book == null
                            ? ''
                            : hadithBookTitle(book, bangla: bangla),
                        categories: [
                          for (final c in _categories)
                            (
                              hadithCategoryTitle(c, bangla: bangla),
                              c.totalHadiths,
                            ),
                        ],
                        onAddMore: () => setState(() => _added = false),
                      )
                    : _PlanForm(
                        controller: _planNameController,
                        targetDaysController: _targetDaysController,
                        bookLabel: book == null
                            ? null
                            : hadithBookTitle(book, bangla: bangla),
                        categoryLabel: _pending == null
                            ? null
                            : hadithCategoryTitle(_pending!, bangla: bangla),
                        onPickBook: _pickBook,
                        onPickCategory: _pickCategory,
                        onAdd: _add,
                      ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 9.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: FilledButton(
                    // Off while the request runs, so a second tap can't send
                    // the plan twice.
                    onPressed: submitting ? null : _create,
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
                            appText.create,
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

class _PlanForm extends StatelessWidget {
  const _PlanForm({
    required this.controller,
    required this.targetDaysController,
    required this.bookLabel,
    required this.categoryLabel,
    required this.onPickBook,
    required this.onPickCategory,
    required this.onAdd,
  });

  final TextEditingController controller;

  /// The optional "Target Days" number.
  final TextEditingController targetDaysController;

  /// The picked book / category, or null while none is picked (the field then
  /// shows its hint).
  final String? bookLabel;
  final String? categoryLabel;
  final VoidCallback onPickBook;
  final VoidCallback onPickCategory;
  final VoidCallback onAdd;

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
          key: const Key('plan-name-field'),
          controller: controller,
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
          key: const Key('target-days-field'),
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
          padding: EdgeInsets.fromLTRB(23.w, 28.h, 23.w, 28.h),
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
              _SelectionField(
                hint: appText.egSahihBukhariHint,
                value: bookLabel,
                onTap: onPickBook,
              ),
              SizedBox(height: 22.h),
              Text(
                appText.selectCategory,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 16.h),
              _SelectionField(
                hint: appText.egHadithCategoryHint,
                value: categoryLabel,
                onTap: onPickCategory,
              ),
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

/// The plan as built so far: its name, its book and the categories added.
class _AddedView extends StatelessWidget {
  const _AddedView({
    required this.planName,
    required this.bookTitle,
    required this.categories,
    required this.onAddMore,
  });

  final String planName;
  final String bookTitle;

  /// Each added category's name and how many hadiths it has.
  final List<(String, int)> categories;
  final VoidCallback onAddMore;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 7.h, 16.w, 20.h),
      children: [
        Text(planName, style: TextStyle(fontSize: 14.sp)),
        if (bookTitle.isNotEmpty) ...[
          SizedBox(height: 4.h),
          Text(
            bookTitle,
            style: TextStyle(
              fontSize: 12.sp,
              color: context.inkColor(const Color(0xFF8B9865)),
            ),
          ),
        ],
        SizedBox(height: 16.h),
        for (final (name, hadithCount) in categories) ...[
          Container(
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
                    border: Border.all(
                      color: context.lineColor(Color(0xFFDDE8C1)),
                    ),
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
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.inkColor(Color(0xFF332B57)),
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 7.h),
                      Text(
                        '${formatHadithCount(hadithCount)} ${appText.categoryHadith}',
                        style: TextStyle(
                          color: const Color(0xFFA1AD59),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(top: 1.h, right: 1.w),
            child: OutlinedButton(
              onPressed: onAddMore,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFA1AD59),
                minimumSize: Size(99.w, 38.h),
                padding: EdgeInsets.zero,
                side: const BorderSide(color: Color(0xFFA1AD59)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
              child: Text(appText.addMore, style: TextStyle(fontSize: 14.sp)),
            ),
          ),
        ),
      ],
    );
  }
}

class _CreatePlanHeader extends StatelessWidget {
  const _CreatePlanHeader({required this.title, required this.onBack});

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

/// A tappable field that opens a picker. Shows the picked [value], or the
/// [hint] while nothing is picked.
class _SelectionField extends StatelessWidget {
  const _SelectionField({required this.hint, required this.onTap, this.value});

  final String hint;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final picked = value;
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
                picked ?? hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: picked == null
                      ? const Color(0xFFB8B8B8)
                      : context.inkColor(const Color(0xFF2C3320)),
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
