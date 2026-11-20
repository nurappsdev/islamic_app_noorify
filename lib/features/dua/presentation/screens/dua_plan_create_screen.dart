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
import 'package:tuhfatul_muslim/features/dua/presentation/screens/dua_all_category_screen.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_category_tile.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_plan_pickers.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_plan_status_badge.dart';

/// `in_progress`, `completed` or `abandoned`, in display order.
const List<String> _duaPlanStatuses = ['in_progress', 'completed', 'abandoned'];

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
/// "Create Plan" action on [DuaPlannerScreen] — or, with [editPlan] set, the
/// "Edit" action on one of its plan cards' 3-dot menu.
///
/// Names the plan, adds one or more duas ("Add" / "Add More" — each with its
/// own time slot), picks which days of the week it repeats on, then sends
/// `POST /duas/planner/plans` (create) or `PATCH /duas/planner/plans/{id}`
/// (edit, [editPlan] non-null — pre-fills the form from it, and adds a
/// status selector since `PATCH` can also move the plan between
/// in-progress/completed/abandoned). The screen pops `true` on success, so
/// the planner knows to reload.
class DuaPlanCreateScreen extends StatefulWidget {
  const DuaPlanCreateScreen({super.key, this.editPlan, this.embedded = false});

  final DuaPlanDetail? editPlan;

  /// Renders inside the Planner's create-plan bottom sheet.
  final bool embedded;

  @override
  State<DuaPlanCreateScreen> createState() => _DuaPlanCreateScreenState();
}

class _DuaPlanCreateScreenState extends State<DuaPlanCreateScreen> {
  late final _nameController = TextEditingController(
    text: widget.editPlan?.name ?? '',
  );

  DuaCategoryModel? _category;
  List<DuaCategoryModel> _categories = const [];
  DateTime? _startDate;
  DateTime? _endDate;

  /// Duas picked from [_category] (multi-select, design change: several
  /// duas from one category can be selected for the plan).
  List<DuaFeaturedModel> _pendingDuas = const [];

  late final List<_PlanItemEntry> _entries = [
    for (final item in widget.editPlan?.items ?? const [])
      if (item.dua != null) _PlanItemEntry(dua: item.dua!, slot: item.slot),
  ];

  /// The sheet always keeps the Create Plan form visible, including edits.
  late final bool _adding = widget.embedded || _entries.isEmpty;

  /// `in_progress` / `completed` / `abandoned` — only edited (and shown) in
  /// edit mode.
  late String _status = widget.editPlan?.status ?? 'in_progress';

  bool get _isEditing => widget.editPlan != null;

  bool _submitting = false;
  String _note = '';
  bool _notifyEveryDay = false;
  bool _showDuaDropdown = false;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.tryParse(widget.editPlan?.startDate ?? '');
    _endDate = DateTime.tryParse(widget.editPlan?.endDate ?? '');
    if (_isEditing && _entries.isNotEmpty) {
      _pendingDuas = [for (final entry in _entries) entry.dua];
      _category = _pendingDuas.first.category;
      _entries.clear();
    }
    _loadCategories();
  }

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

  Future<void> _loadCategories() async {
    try {
      final categories = await duaRepository.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        final selectedId =
            _category?.id ??
            (_pendingDuas.isEmpty ? '' : _pendingDuas.first.categoryId);
        if (selectedId.isNotEmpty) {
          for (final category in categories) {
            if (category.id == selectedId) {
              _category = category;
              break;
            }
          }
        }
      });
    } catch (_) {
      // The existing category picker remains available as a fallback.
    }
  }

  Future<void> _pickDate({required bool start}) async {
    FocusScope.of(context).unfocus();
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: start
          ? (_startDate ?? today)
          : (_endDate ?? _startDate ?? today),
      firstDate: start ? today : (_startDate ?? today),
      lastDate: DateTime(today.year + 10),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (start) {
        _startDate = selected;
        if (_endDate != null && _endDate!.isBefore(selected)) {
          _endDate = null;
        }
      } else {
        _endDate = selected;
      }
    });
  }

  Future<void> _editNote() async {
    final note = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .28),
      builder: (_) => _PlanNoteDialog(initialValue: _note),
    );
    if (note != null && mounted) setState(() => _note = note.trim());
  }

  Future<void> _pickCategory() async {
    FocusScope.of(context).unfocus();
    final category = await Navigator.of(context).push<DuaCategoryModel>(
      MaterialPageRoute(
        builder: (_) =>
            DuaAllCategoryScreen(selectMode: true, selectedId: _category?.id),
      ),
    );
    if (category == null || !mounted) return;
    setState(() {
      // Duas belong to their category, so switching categories clears them.
      if (_category?.id != category.id) _pendingDuas = const [];
      _category = category;
      _showDuaDropdown = false;
    });
  }

  Future<void> _pickDua() async {
    final category = _category;
    if (category == null) {
      _snack(AppText.readOf(context).selectCategoryFirst);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _showDuaDropdown = !_showDuaDropdown);
  }

  Future<void> _openAllDuas() async {
    final category = _category;
    if (category == null) {
      _snack(AppText.readOf(context).selectCategoryFirst);
      return;
    }
    FocusScope.of(context).unfocus();
    final duas = await Navigator.of(context).push<List<DuaFeaturedModel>>(
      MaterialPageRoute(
        builder: (_) => DuaPlanDuaPickerScreen(
          category: category,
          initialSelectedIds: {for (final dua in _pendingDuas) dua.id},
        ),
      ),
    );
    if (duas == null || !mounted) return;
    setState(() {
      _pendingDuas = duas;
      _showDuaDropdown = false;
    });
  }

  /// The entries already added via "Add", plus whatever duas are still
  /// picked on the form but weren't explicitly added yet — so tapping
  /// "Create" right after picking a category/duas (without tapping the
  /// small "Add" first) still saves them, instead of the selection being
  /// silently dropped.
  List<_PlanItemEntry> _resolvedEntries() {
    final entries = List.of(_entries);
    for (final dua in _pendingDuas) {
      entries.add(_PlanItemEntry(dua: dua, slot: 'anytime'));
    }
    return entries;
  }

  void _removeEntry(int index) {
    HapticFeedback.selectionClick();
    setState(() => _entries.removeAt(index));
  }

  void _setStatus(String status) {
    HapticFeedback.selectionClick();
    setState(() => _status = status);
  }

  Future<void> _submit() async {
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
      final draft = DuaPlanDraft(
        name: _planName,
        items: [for (final entry in entries) entry.toDraft()],
        daysOfWeek: widget.editPlan?.daysOfWeek.isNotEmpty == true
            ? widget.editPlan!.daysOfWeek
            : const [0, 1, 2, 3, 4, 5, 6],
        startDate: _startDate,
        endDate: _endDate,
        status: _isEditing ? _status : null,
      );
      final editId = widget.editPlan?.id;
      if (editId != null) {
        await duaRepository.editPlan(editId, draft);
      } else {
        await duaRepository.createPlan(draft);
      }
      if (mounted) Navigator.of(context).pop(true);
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

    final content = Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 6.h),
            widget.embedded
                ? _CreatePlanSheetHeader(
                    title: _isEditing
                        ? appText.duaEditPlanTitle
                        : appText.createPlanHeader,
                    hasNote: _note.isNotEmpty,
                    onAddNote: _editNote,
                    onClose: () => Navigator.of(context).maybePop(),
                  )
                : _Header(
                    title: _isEditing
                        ? appText.duaEditPlanTitle
                        : appText.createPlanHeader,
                  ),
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
                    onPressed: _submitting ? null : _submit,
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
                            _isEditing
                                ? appText.duaSaveChanges
                                : appText.create,
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

    if (!widget.embedded) return content;
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(38.r)),
      child: content,
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
        Row(
          children: [
            Text(
              appText.selectCategory,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            IconButton(
              onPressed: _pickCategory,
              tooltip: appText.selectCategory,
              icon: Icon(
                Icons.open_in_new_rounded,
                size: 18.sp,
                color: const Color(0xFFA7B45B),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        if (_categories.isEmpty)
          SizedBox(
            height: 48.h,
            child: _SelectionField(
              hint: appText.selectCategory,
              value: _category == null
                  ? null
                  : context.localized(_category!.name),
              onTap: _pickCategory,
            ),
          )
        else
          SizedBox(
            height: 150.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => SizedBox(width: 12.w),
              itemBuilder: (context, index) {
                final category = _categories[index];
                return SizedBox(
                  width: 150.w,
                  child: DuaCategoryTile(
                    category: category,
                    index: index,
                    selected: _category?.id == category.id,
                    onTap: () => setState(() {
                      if (_category?.id != category.id) {
                        _pendingDuas = const [];
                      }
                      _category = category;
                      _showDuaDropdown = false;
                    }),
                  ),
                );
              },
            ),
          ),
        SizedBox(height: 18.h),
        Row(
          children: [
            Text(
              appText.selectDua,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            IconButton(
              onPressed: _openAllDuas,
              tooltip: appText.selectDua,
              icon: Icon(
                Icons.open_in_new_rounded,
                size: 18.sp,
                color: const Color(0xFFA7B45B),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
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
        if (_pendingDuas.isNotEmpty) ...[
          SizedBox(height: 8.h),
          Wrap(
            spacing: 7.w,
            runSpacing: 7.h,
            children: [
              for (var index = 0; index < _pendingDuas.length; index++)
                Tooltip(
                  message: context.localized(_pendingDuas[index].title),
                  child: Container(
                    width: 30.r,
                    height: 30.r,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4F8E6),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      context.localizedDigits('${index + 1}'),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: context.textInkColor(const Color(0xFF4C5731)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
        if (_showDuaDropdown) ...[
          SizedBox(height: 10.h),
          SizedBox(
            height: 270.h,
            child: DuaPlanDuaDropdown(
              category: _category!,
              selectedIds: {for (final dua in _pendingDuas) dua.id},
              onSelected: (dua) => setState(() {
                final selectedIndex = _pendingDuas.indexWhere(
                  (item) => item.id == dua.id,
                );
                if (selectedIndex >= 0) {
                  _pendingDuas = [
                    for (final item in _pendingDuas)
                      if (item.id != dua.id) item,
                  ];
                } else {
                  _pendingDuas = [..._pendingDuas, dua];
                }
              }),
            ),
          ),
        ],
        SizedBox(height: 18.h),
        Row(
          children: [
            Expanded(
              child: _PlannerDateField(
                label: context.localized(
                  const LocalizedText(en: 'Start Date', bn: 'শুরুর তারিখ'),
                ),
                value: _startDate,
                onTap: () => _pickDate(start: true),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: _PlannerDateField(
                label: context.localized(
                  const LocalizedText(en: 'End Date', bn: 'শেষের তারিখ'),
                ),
                value: _endDate,
                onTap: () => _pickDate(start: false),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        InkWell(
          onTap: () => setState(() => _notifyEveryDay = !_notifyEveryDay),
          borderRadius: BorderRadius.circular(8.r),
          child: Row(
            children: [
              SizedBox(
                width: 28.r,
                height: 28.r,
                child: Checkbox(
                  value: _notifyEveryDay,
                  onChanged: (value) =>
                      setState(() => _notifyEveryDay = value ?? false),
                  activeColor: const Color(0xFFA7B45B),
                  side: const BorderSide(color: Color(0xFFD7E7A4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  context.localized(
                    const LocalizedText(
                      en: 'Are you want to get notification every day',
                      bn: 'আপনি কি প্রতিদিন নোটিফিকেশন পেতে চান?',
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: context.textInkColor(const Color(0xFF2C3320)),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isEditing) ..._statusSection(appText),
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
        if (_isEditing) ..._statusSection(appText),
      ],
    );
  }

  List<Widget> _statusSection(AppText appText) => [
    SizedBox(height: 22.h),
    Text(
      appText.duaPlanStatusLabel,
      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
    ),
    SizedBox(height: 12.h),
    Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        for (final status in _duaPlanStatuses)
          _SlotChip(
            label: duaPlanStatusLabel(appText, status),
            selected: _status == status,
            onTap: () => _setStatus(status),
          ),
      ],
    ),
  ];

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

class _CreatePlanSheetHeader extends StatelessWidget {
  const _CreatePlanSheetHeader({
    required this.title,
    required this.hasNote,
    required this.onAddNote,
    required this.onClose,
  });

  final String title;
  final bool hasNote;
  final VoidCallback onAddNote;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(16.w, 9.h, 16.w, 8.h),
    child: Column(
      children: [
        Container(
          width: 60.w,
          height: 5.h,
          decoration: BoxDecoration(
            color: const Color(0xFFD8D6D4),
            borderRadius: BorderRadius.circular(99.r),
          ),
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                  fontSize: 24.sp,
                  color: context.textInkColor(const Color(0xFFA7B45B)),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onAddNote,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                minimumSize: Size(0, 34.h),
                foregroundColor: const Color(0xFFA7B45B),
                side: const BorderSide(color: Color(0xFFD7E7A4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              icon: Icon(
                hasNote ? Icons.note_alt_rounded : Icons.edit_note_rounded,
                size: 15.sp,
              ),
              label: Text(
                context.localized(
                  const LocalizedText(en: 'Add note', bn: 'নোট যোগ করুন'),
                ),
                style: TextStyle(fontSize: 10.sp),
              ),
            ),
            SizedBox(width: 8.w),
            IconButton(
              onPressed: onClose,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF5F5F5),
              ),
              icon: Icon(
                Icons.close_rounded,
                size: 19.sp,
                color: context.textInkColor(const Color(0xFF777777)),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PlanNoteDialog extends StatefulWidget {
  const _PlanNoteDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_PlanNoteDialog> createState() => _PlanNoteDialogState();
}

class _PlanNoteDialogState extends State<_PlanNoteDialog> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
    child: Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 22.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.localized(
              const LocalizedText(en: 'Add note', bn: 'নোট যোগ করুন'),
            ),
            style: TextStyle(
              fontSize: 19.sp,
              fontWeight: FontWeight.w700,
              color: context.textInkColor(const Color(0xFF182035)),
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _controller,
            minLines: 6,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: AppText.of(context).writeHereHint,
              alignLabelWithHint: true,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: Color(0xFFD7E7A4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: Color(0xFFA7B45B)),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _controller.text),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFA7B45B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(AppText.of(context).planSave),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.textInkColor(
                      const Color(0xFF182035),
                    ),
                    side: const BorderSide(color: Color(0xFFE0E4EB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(AppText.of(context).planCancel),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _PlannerDateField extends StatelessWidget {
  const _PlannerDateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
      ),
      SizedBox(height: 8.h),
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22.r),
          child: Ink(
            height: 45.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD7E7A4)),
              borderRadius: BorderRadius.circular(22.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value == null
                        ? context.localized(
                            const LocalizedText(
                              en: 'Select date',
                              bn: 'তারিখ বাছাই করুন',
                            ),
                          )
                        : context.localizedDigits(
                            MaterialLocalizations.of(
                              context,
                            ).formatMediumDate(value!),
                          ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      color: value == null
                          ? AppColor.authHint
                          : context.textInkColor(const Color(0xFF2C3320)),
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_month_outlined,
                  size: 17.sp,
                  color: const Color(0xFFA7B45B),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
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
