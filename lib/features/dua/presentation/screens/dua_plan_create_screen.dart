import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_plan_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/dua_dependencies.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/dua_login_dialog.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/dua_plan_slot.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_plan_pickers.dart';

/// One dua added to the plan being built, before "Create" sends it.
///
/// No target count here — the API falls back to the dua's own
/// `recommendedRepeatCount` when it's left out.
class _PlanItemEntry {
  const _PlanItemEntry({required this.dua, required this.slot});

  final DuaFeaturedModel dua;
  final String slot;

  DuaPlanItemDraft toDraft() => DuaPlanItemDraft(duaId: dua.id, slot: slot);
}

/// "Create plan" screen (design `devImg/img_8.png`), reached from the
/// "Create Plan" action on [DuaPlannerScreen].
///
/// Names the plan, adds one or more duas ("Add" / "Add More" — each with its
/// own time slot), picks which days of the week it repeats on, then sends
/// `POST /duas/planner/plans`. On success the screen pops with the created
/// [DuaPlan], so the planner can show it right away without a full reload.
class DuaPlanCreateScreen extends StatefulWidget {
  const DuaPlanCreateScreen({super.key});

  @override
  State<DuaPlanCreateScreen> createState() => _DuaPlanCreateScreenState();
}

class _DuaPlanCreateScreenState extends State<DuaPlanCreateScreen> {
  final _nameController = TextEditingController();

  DuaCategoryModel? _category;

  /// Duas picked from [_category] (multi-select, design change: several
  /// duas from one category can be added in a single "Add") but not yet
  /// added to [_entries].
  List<DuaFeaturedModel> _pendingDuas = const [];
  String _slot = 'anytime';

  final List<_PlanItemEntry> _entries = [];

  /// Whether the "added" list is showing instead of the form.
  bool _adding = true;

  /// 0 = Sunday ... 6 = Saturday; every day by default (the API's own
  /// default when `daysOfWeek` is left out).
  final Set<int> _days = {0, 1, 2, 3, 4, 5, 6};

  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String get _planName => _nameController.text.trim();

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickCategory() async {
    FocusScope.of(context).unfocus();
    final category = await showModalBottomSheet<DuaCategoryModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DuaCategoryPickerSheet(selectedId: _category?.id),
    );
    if (category == null || !mounted) return;
    setState(() {
      // Duas belong to their category, so switching categories clears them.
      if (_category?.id != category.id) _pendingDuas = const [];
      _category = category;
    });
  }

  Future<void> _pickDua() async {
    final category = _category;
    if (category == null) {
      _snack(AppText.readOf(context).selectCategoryFirst);
      return;
    }
    FocusScope.of(context).unfocus();
    final duas = await showModalBottomSheet<List<DuaFeaturedModel>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DuaItemPickerSheet(
        category: category,
        initialSelectedIds: {for (final dua in _pendingDuas) dua.id},
      ),
    );
    if (duas == null || !mounted) return;
    setState(() => _pendingDuas = duas);
  }

  /// The entries already added via "Add", plus whatever duas are still
  /// picked on the form but weren't explicitly added yet — so tapping
  /// "Create" right after picking a category/duas (without tapping the
  /// small "Add" first) still saves them, instead of the selection being
  /// silently dropped.
  List<_PlanItemEntry> _resolvedEntries() {
    final entries = List.of(_entries);
    for (final dua in _pendingDuas) {
      entries.add(_PlanItemEntry(dua: dua, slot: _slot));
    }
    return entries;
  }

  void _add() {
    final appText = AppText.readOf(context);
    if (_category == null) {
      _snack(appText.selectCategoryFirst);
      return;
    }
    if (_pendingDuas.isEmpty) {
      _snack(appText.selectDuaFirst);
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      for (final dua in _pendingDuas) {
        _entries.add(_PlanItemEntry(dua: dua, slot: _slot));
      }
      _pendingDuas = const [];
      _slot = 'anytime';
      _adding = false;
    });
  }

  void _addMore() => setState(() => _adding = true);

  void _removeEntry(int index) {
    HapticFeedback.selectionClick();
    setState(() => _entries.removeAt(index));
  }

  void _toggleDay(int day) {
    HapticFeedback.selectionClick();
    setState(() {
      // At least one day stays selected — the plan has to run sometime.
      if (_days.contains(day)) {
        if (_days.length > 1) _days.remove(day);
      } else {
        _days.add(day);
      }
    });
  }

  Future<void> _create() async {
    final appText = AppText.readOf(context);
    final entries = _resolvedEntries();
    if (entries.isEmpty) {
      _snack(appText.selectDuaFirst);
      return;
    }
    if (_planName.isEmpty) {
      _snack(appText.planNameRequired);
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _submitting = true);
    try {
      final plan = await duaRepository.createPlan(
        DuaPlanDraft(
          name: _planName,
          items: [for (final entry in entries) entry.toDraft()],
          daysOfWeek: _days.toList()..sort(),
        ),
      );
      if (mounted) Navigator.of(context).pop(plan);
    } catch (error) {
      if (error is AuthenticationRequiredException) {
        if (mounted) await showDuaLoginRequiredDialog(context);
        return;
      }
      if (mounted) _snack('$error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);

    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 6.h),
            _Header(title: appText.createPlanHeader),
            Expanded(
              child: _adding ? _buildForm(appText) : _buildAddedList(appText),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 14.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 54.h,
                  child: FilledButton(
                    onPressed: _submitting ? null : _create,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColor.primary,
                      disabledForegroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28.r),
                      ),
                    ),
                    child: _submitting
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
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(AppText appText) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 20.h),
      children: [
        Text(
          appText.planNameLabel,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(fontSize: 13.sp),
          decoration: InputDecoration(
            hintText: appText.writeHereHint,
            hintStyle: TextStyle(color: AppColor.authHint, fontSize: 12.sp),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 18.w,
              vertical: 15.h,
            ),
            enabledBorder: _fieldBorder(context),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(26.r),
              borderSide: const BorderSide(color: AppColor.primary),
            ),
          ),
        ),
        SizedBox(height: 18.h),
        Container(
          padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 18.h),
          decoration: BoxDecoration(
            border: Border.all(
              color: context.lineColor(const Color(0xFFD5E59B)),
            ),
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appText.selectCategory,
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 10.h),
              _SelectionField(
                hint: appText.selectCategory,
                value: _category == null
                    ? null
                    : context.localized(_category!.name),
                onTap: _pickCategory,
              ),
              SizedBox(height: 18.h),
              Text(
                appText.selectDua,
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 10.h),
              _SelectionField(
                hint: appText.selectDua,
                value: _pendingDuas.isEmpty
                    ? null
                    : _pendingDuas.length == 1
                    ? context.localized(_pendingDuas.first.title)
                    : appText.duaSelectedCount.replaceAll(
                        '{n}',
                        context.localizedDigits('${_pendingDuas.length}'),
                      ),
                onTap: _pickDua,
              ),
              SizedBox(height: 18.h),
              Text(
                appText.duaPlanSlotLabel,
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  for (final slot in duaPlanSlots)
                    _SlotChip(
                      label: duaSlotLabel(appText, slot),
                      selected: _slot == slot,
                      onTap: () => setState(() => _slot = slot),
                    ),
                ],
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(top: 12.h),
            child: OutlinedButton(
              onPressed: _add,
              style: OutlinedButton.styleFrom(
                foregroundColor: context.inkColor(AppColor.primary),
                side: const BorderSide(color: AppColor.primary),
                padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22.r),
                ),
              ),
              child: Text(
                appText.add,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        SizedBox(height: 22.h),
        Text(
          appText.repeatLabel,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 12.h),
        _DaysOfWeekRow(selected: _days, onToggle: _toggleDay),
      ],
    );
  }

  Widget _buildAddedList(AppText appText) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 20.h),
      children: [
        Text(
          _planName.isEmpty ? appText.writeHereHint : _planName,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 14.h),
        for (var i = 0; i < _entries.length; i++) ...[
          _EntryRow(
            entry: _entries[i],
            appText: appText,
            onRemove: () => _removeEntry(i),
          ),
          SizedBox(height: 10.h),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton(
            onPressed: _addMore,
            style: OutlinedButton.styleFrom(
              foregroundColor: context.inkColor(AppColor.primary),
              side: const BorderSide(color: AppColor.primary),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22.r),
              ),
            ),
            child: Text(
              appText.addMore,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        SizedBox(height: 22.h),
        Text(
          appText.repeatLabel,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 12.h),
        _DaysOfWeekRow(selected: _days, onToggle: _toggleDay),
      ],
    );
  }

  OutlineInputBorder _fieldBorder(BuildContext context) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(26.r),
    borderSide: BorderSide(color: context.lineColor(AppColor.authFieldBorder)),
  );
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.entry,
    required this.appText,
    required this.onRemove,
  });

  final _PlanItemEntry entry;
  final AppText appText;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
    decoration: BoxDecoration(
      border: Border.all(color: context.lineColor(const Color(0xFFD5E59B))),
      borderRadius: BorderRadius.circular(18.r),
    ),
    child: Row(
      children: [
        CircleAvatar(radius: 17.r, backgroundColor: const Color(0xFFA5B657)),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.localized(entry.dua.title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 3.h),
              Text(
                duaSlotLabel(appText, entry.slot),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFFA5B657),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onRemove,
          icon: Icon(
            Icons.close_rounded,
            size: 18.sp,
            color: context.inkColor(const Color(0xFF9BA85B)),
          ),
        ),
      ],
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44.h,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 12.w),
            child: IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.chevron_left),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFE1E56A),
              ),
            ),
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 17.sp,
            color: context.inkColor(const Color(0xFF7D8E54)),
          ),
        ),
      ],
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
          border: Border.all(
            color: context.lineColor(AppColor.authFieldBorder),
          ),
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
                      ? AppColor.authHint
                      : context.inkColor(const Color(0xFF2C3320)),
                  fontSize: 13.sp,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.inkColor(const Color(0xFFA5B657)),
              size: 22.sp,
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: selected ? AppColor.primary : context.surfaceColor(Colors.white),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: selected
              ? AppColor.primary
              : context.lineColor(AppColor.authFieldBorder),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: selected
              ? Colors.white
              : context.inkColor(const Color(0xFF5D6B44)),
        ),
      ),
    ),
  );
}

/// The seven weekday toggle chips for `daysOfWeek` (0 = Sunday ... 6 =
/// Saturday, matching the API).
class _DaysOfWeekRow extends StatelessWidget {
  const _DaysOfWeekRow({required this.selected, required this.onToggle});

  final Set<int> selected;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final names = [
      appText.weekdaySunday,
      appText.weekdayMonday,
      appText.weekdayTuesday,
      appText.weekdayWednesday,
      appText.weekdayThursday,
      appText.weekdayFriday,
      appText.weekdaySaturday,
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var day = 0; day < 7; day++)
          _DayChip(
            label: names[day].isEmpty ? '' : names[day].substring(0, 1),
            selected: selected.contains(day),
            onTap: () => onToggle(day),
          ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36.r,
      height: 36.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColor.primary : context.surfaceColor(Colors.white),
        border: Border.all(
          color: selected
              ? AppColor.primary
              : context.lineColor(AppColor.authFieldBorder),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: selected
              ? Colors.white
              : context.inkColor(const Color(0xFF5D6B44)),
        ),
      ),
    ),
  );
}
