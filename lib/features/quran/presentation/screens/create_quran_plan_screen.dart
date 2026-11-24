import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/core/localization/localized_failure_message.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import '../../data/repositories/quran_plan_repository_impl.dart';
import '../../data/services/quran_content_service.dart';
import '../../domain/quran_plan.dart';
import '../../domain/repositories/quran_plan_repository.dart';
import '../../domain/surah_summary.dart';
import '../quran_text.dart';
import '../widgets/quran_surah_picker_sheet.dart';

class CreateQuranPlanScreen extends StatefulWidget {
  const CreateQuranPlanScreen({super.key, this.repository, this.initialPlan});

  final QuranPlanRepository? repository;
  final QuranPlan? initialPlan;

  bool get isEditing => initialPlan != null;

  @override
  State<CreateQuranPlanScreen> createState() => _CreateQuranPlanScreenState();
}

class _CreateQuranPlanScreenState extends State<CreateQuranPlanScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _daysController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _startDateController;

  late bool _wholeQuran;
  late String _status;
  SurahSummary? _startSurah;
  SurahSummary? _endSurah;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final plan = widget.initialPlan;
    _nameController = TextEditingController(text: plan?.name ?? '');
    _daysController = TextEditingController(
      text: plan != null ? plan.targetDays.toString() : '',
    );
    _descriptionController = TextEditingController(
      text: plan?.description ?? '',
    );
    _startDateController = TextEditingController(text: plan?.startDate ?? '');
    _wholeQuran = plan?.wholeQuran ?? true;
    _status = plan?.status ?? 'in_progress';

    _initSurahs();
  }

  Future<void> _initSurahs() async {
    final plan = widget.initialPlan;
    if (plan == null) return;

    try {
      final all = await QuranContentService.shared.loadSurahs();
      if (!mounted) return;

      final startNo = plan.surahNumbers.isNotEmpty
          ? plan.surahNumbers.first
          : plan.startSurah;
      final endNo = plan.surahNumbers.isNotEmpty
          ? plan.surahNumbers.last
          : plan.endSurah;

      setState(() {
        _startSurah = all.firstWhere(
          (s) => s.number == startNo,
          orElse: () => SurahSummary(
            number: startNo,
            name: plan.startSurahName,
            nameArabic: '',
            translation: '',
            revelationPlace: '',
            totalAyah: 0,
          ),
        );
        _endSurah = all.firstWhere(
          (s) => s.number == endNo,
          orElse: () => SurahSummary(
            number: endNo,
            name: plan.endSurahName,
            nameArabic: '',
            translation: '',
            revelationPlace: '',
            totalAyah: 0,
          ),
        );
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _daysController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    super.dispose();
  }

  Future<void> _pickStartSurah() async {
    final selected = await QuranSurahPickerSheet.show(
      context,
      selectedSurahNumber: _startSurah?.number,
      title: QuranText.read(context).selectStartSurah,
    );
    if (selected != null) {
      setState(() => _startSurah = selected);
    }
  }

  Future<void> _pickEndSurah() async {
    final selected = await QuranSurahPickerSheet.show(
      context,
      selectedSurahNumber: _endSurah?.number,
      title: QuranText.read(context).selectEndSurah,
    );
    if (selected != null) {
      setState(() => _endSurah = selected);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final name = _nameController.text.trim();
    final daysText = _daysController.text.trim();
    final desc = _descriptionController.text.trim();
    final startDate = _startDateController.text.trim();
    final t = QuranText.read(context);

    // Accept Bengali digits too.
    final days = int.tryParse(
      daysText.replaceAllMapped(
        RegExp('[০-৯]'),
        (m) => '${m[0]!.codeUnitAt(0) - 0x09E6}',
      ),
    );

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.enterPlanName)));
      return;
    }

    if (days == null || days <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.enterValidDays)));
      return;
    }

    final startNo = _startSurah?.number ?? 1;
    final endNo = _endSurah?.number ?? 114;
    final surahs = _wholeQuran
        ? const <int>[]
        : [
            for (
              int i = math.min(startNo, endNo);
              i <= math.max(startNo, endNo);
              i++
            )
              i,
          ];

    setState(() => _submitting = true);

    final repo = widget.repository ?? QuranPlanRepositoryImpl.shared;

    if (widget.isEditing) {
      final updateReq = UpdateQuranPlanRequest(
        name: name,
        description: desc.isNotEmpty ? desc : null,
        targetDays: days,
        startDate: startDate.isNotEmpty ? startDate : null,
        wholeQuran: _wholeQuran,
        surahNumbers: surahs,
        status: _status,
      );

      final result = await repo.updatePlan(widget.initialPlan!.id, updateReq);
      if (!mounted) return;
      setState(() => _submitting = false);

      result.fold(
        (failure) {
          final message =
              (failure is ServerFailure && failure.statusCode == 409)
              ? t.quranPlanDuplicateName
              : localizeFailureMessage(failure.message);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red.shade700,
            ),
          );
        },
        (updatedPlan) {
          Navigator.of(context).pop(updatedPlan);
        },
      );
    } else {
      final createReq = CreateQuranPlanRequest(
        name: name,
        targetDays: days,
        wholeQuran: _wholeQuran,
        surahNumbers: surahs,
      );

      final result = await repo.createPlan(createReq);
      if (!mounted) return;
      setState(() => _submitting = false);

      result.fold(
        (failure) {
          final message =
              (failure is ServerFailure && failure.statusCode == 409)
              ? t.quranPlanDuplicateName
              : localizeFailureMessage(failure.message);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red.shade700,
            ),
          );
        },
        (createdPlan) {
          Navigator.of(context).pop(createdPlan);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const oliveColor = Color(0xFF9EAA52);
    const borderColor = Color(0xFFD2E3A8);
    const titleColor = Color(0xFF7A8D49);
    const labelColor = Color(0xFF282442);
    const hintColor = Color(0xFFB0BAA5);
    const chevronColor = Color(0xFF8A9A70);

    final t = QuranText.of(context);

    // The design's colors, mapped to the active theme once for the whole
    // screen (see ThemeColors: in light mode every call is a no-op).
    final lineColor = context.lineColor(borderColor);
    final focusColor = context.lineColor(oliveColor);
    final labelInk = context.textInkColor(labelColor);
    final hintInk = context.textInkColor(hintColor);
    final titleInk = context.inkColor(titleColor);
    final chevronInk = context.inkColor(chevronColor);

    InputDecoration fieldDecoration({
      required double radius,
      required double vertical,
    }) {
      OutlineInputBorder border(Color color, double width) =>
          OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius.r),
            borderSide: BorderSide(color: color, width: width),
          );

      return InputDecoration(
        hintText: t.writeHere,
        hintStyle: TextStyle(color: hintInk, fontSize: 13.sp),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 20.w,
          vertical: vertical.h,
        ),
        border: border(lineColor, 1),
        enabledBorder: border(lineColor, 1),
        focusedBorder: border(focusColor, 1.5),
      );
    }

    Widget fieldLabel(String text) => Text(
      text,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: labelInk,
      ),
    );

    String surahLabel(SurahSummary? surah, int fallbackNo, String fallback) =>
        surah != null
        ? t.surahTitle(t.surahName(surah.number, surah.name))
        : t.example(t.surahTitle(t.surahName(fallbackNo, fallback)));

    Widget surahPickerField({
      required SurahSummary? surah,
      required int fallbackNo,
      required String fallback,
      required VoidCallback onTap,
    }) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(color: lineColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                surahLabel(surah, fallbackNo, fallback),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: surah != null ? labelInk : hintInk,
                  fontSize: 13.sp,
                  fontWeight: surah != null
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: chevronInk, size: 22.sp),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header: Circular back button and centered Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20.r),
                      child: Container(
                        width: 40.r,
                        height: 40.r,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDEE99D),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          color: const Color(0xFF5D7133),
                          size: 26.sp,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    widget.isEditing ? t.editQuranPlan : t.createPlanTitle,
                    style: TextStyle(
                      color: titleInk,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Field 1: Plan name
                    fieldLabel(t.planName),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: _nameController,
                      style: TextStyle(fontSize: 14.sp, color: labelInk),
                      cursorColor: focusColor,
                      decoration: fieldDecoration(radius: 28, vertical: 14),
                    ),
                    SizedBox(height: 18.h),

                    // Field 2: Description
                    fieldLabel(t.description),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: _descriptionController,
                      style: TextStyle(fontSize: 14.sp, color: labelInk),
                      cursorColor: focusColor,
                      maxLines: 2,
                      decoration: fieldDecoration(radius: 20, vertical: 12),
                    ),
                    SizedBox(height: 18.h),

                    // Field 3: Completion days
                    fieldLabel(t.completionDays),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: _daysController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 14.sp, color: labelInk),
                      cursorColor: focusColor,
                      decoration: fieldDecoration(radius: 28, vertical: 14),
                    ),
                    SizedBox(height: 20.h),

                    // Whole Quran toggle switch
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: context.surfaceColor(const Color(0xFFF7F9F0)),
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(color: lineColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                color: context.inkColor(
                                  const Color(0xFF6B8042),
                                ),
                                size: 20.sp,
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                t.wholeQuran,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: labelInk,
                                ),
                              ),
                            ],
                          ),
                          Switch.adaptive(
                            value: _wholeQuran,
                            activeTrackColor: oliveColor,
                            inactiveTrackColor: context.surfaceColor(
                              const Color(0xFFEFF2E4),
                            ),
                            inactiveThumbColor: context.surfaceColor(
                              Colors.white,
                            ),
                            trackOutlineColor: WidgetStatePropertyAll(
                              lineColor,
                            ),
                            onChanged: (val) {
                              setState(() => _wholeQuran = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 18.h),

                    // Surah selection if not Whole Quran
                    if (!_wholeQuran) ...[
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24.r),
                          border: Border.all(color: lineColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Select Start Sura
                            fieldLabel(t.selectStartSurah),
                            SizedBox(height: 8.h),
                            surahPickerField(
                              surah: _startSurah,
                              fallbackNo: 1,
                              fallback: 'Al-Fatiha',
                              onTap: _pickStartSurah,
                            ),
                            SizedBox(height: 18.h),

                            // Select End Sura
                            fieldLabel(t.selectEndSurah),
                            SizedBox(height: 8.h),
                            surahPickerField(
                              surah: _endSurah,
                              fallbackNo: 114,
                              fallback: 'An-Nas',
                              onTap: _pickEndSurah,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 18.h),
                    ],

                    // Edit mode extra: Status
                    if (widget.isEditing) ...[
                      fieldLabel(t.planStatus),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: lineColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _status,
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(16.r),
                            dropdownColor: context.surfaceColor(Colors.white),
                            iconEnabledColor: chevronInk,
                            style: TextStyle(fontSize: 14.sp, color: labelInk),
                            items: [
                              DropdownMenuItem(
                                value: 'in_progress',
                                child: Text(t.activePlans),
                              ),
                              DropdownMenuItem(
                                value: 'completed',
                                child: Text(t.completedPlans),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _status = val);
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 18.h),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Full-width Submit button
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 18.h),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: oliveColor,
                    disabledBackgroundColor: oliveColor.withValues(alpha: 0.6),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.r),
                    ),
                  ),
                  child: _submitting
                      ? SizedBox(
                          width: 22.r,
                          height: 22.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.isEditing ? t.save : t.create,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
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
}
