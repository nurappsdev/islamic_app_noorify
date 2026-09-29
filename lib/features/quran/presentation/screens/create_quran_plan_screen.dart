import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import '../../domain/quran_plan.dart';
import '../../domain/surah_summary.dart';
import '../../data/services/quran_plan_store.dart';
import '../quran_text.dart';
import '../widgets/quran_surah_picker_sheet.dart';

class CreateQuranPlanScreen extends StatefulWidget {
  const CreateQuranPlanScreen({super.key});

  @override
  State<CreateQuranPlanScreen> createState() => _CreateQuranPlanScreenState();
}

class _CreateQuranPlanScreenState extends State<CreateQuranPlanScreen> {
  final _nameController = TextEditingController();
  final _daysController = TextEditingController();

  SurahSummary? _startSurah;
  SurahSummary? _endSurah;

  @override
  void dispose() {
    _nameController.dispose();
    _daysController.dispose();
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
    final name = _nameController.text.trim();
    final daysText = _daysController.text.trim();
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

    final plan = QuranPlan(
      id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      days: days,
      startSurah: _startSurah?.number ?? 1,
      startSurahName: _startSurah?.name ?? 'Al-Fatiha',
      endSurah: _endSurah?.number ?? 114,
      endSurahName: _endSurah?.name ?? 'An-Nas',
      createdAt: DateTime.now(),
    );

    await QuranPlanStore.savePlan(plan);

    if (!mounted) return;
    Navigator.of(context).pop(plan);
  }

  @override
  Widget build(BuildContext context) {
    const oliveColor = Color(0xFF9EAA52);
    const borderColor = Color(0xFFD2E3A8);
    const titleColor = Color(0xFF7A8D49);
    final t = QuranText.of(context);
    String surahLabel(SurahSummary? surah, int fallbackNo, String fallback) =>
        surah != null
        ? t.surahTitle(t.surahName(surah.number, surah.name))
        : t.example(t.surahTitle(t.surahName(fallbackNo, fallback)));

    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header: Circular back button and centered "Create plan"
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
                    t.createPlanTitle,
                    style: TextStyle(
                      color: titleColor,
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
                    Text(
                      t.planName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF282442),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: _nameController,
                      style: TextStyle(fontSize: 14.sp),
                      decoration: InputDecoration(
                        hintText: t.writeHere,
                        hintStyle: TextStyle(
                          color: const Color(0xFFB0BAA5),
                          fontSize: 13.sp,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 14.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28.r),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28.r),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28.r),
                          borderSide: const BorderSide(
                            color: oliveColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Field 2: Completion days
                    Text(
                      t.completionDays,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF282442),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: _daysController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 14.sp),
                      decoration: InputDecoration(
                        hintText: t.writeHere,
                        hintStyle: TextStyle(
                          color: const Color(0xFFB0BAA5),
                          fontSize: 13.sp,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 14.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28.r),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28.r),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28.r),
                          borderSide: const BorderSide(
                            color: oliveColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Group Container with rounded green border
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Select Start Sura
                          Text(
                            t.selectStartSurah,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF282442),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          InkWell(
                            onTap: _pickStartSurah,
                            borderRadius: BorderRadius.circular(28.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 18.w,
                                vertical: 14.h,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28.r),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      surahLabel(_startSurah, 1, 'Al-Fatiha'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: _startSurah != null
                                            ? const Color(0xFF282442)
                                            : const Color(0xFFB0BAA5),
                                        fontSize: 13.sp,
                                        fontWeight: _startSurah != null
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: const Color(0xFF8A9A70),
                                    size: 22.sp,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 18.h),

                          // Select End Sura
                          Text(
                            t.selectEndSurah,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF282442),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          InkWell(
                            onTap: _pickEndSurah,
                            borderRadius: BorderRadius.circular(28.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 18.w,
                                vertical: 14.h,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28.r),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      surahLabel(_endSurah, 114, 'An-Nas'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: _endSurah != null
                                            ? const Color(0xFF282442)
                                            : const Color(0xFFB0BAA5),
                                        fontSize: 13.sp,
                                        fontWeight: _endSurah != null
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: const Color(0xFF8A9A70),
                                    size: 22.sp,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Full-width Create button
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 18.h),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: oliveColor,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.r),
                    ),
                  ),
                  child: Text(
                    t.create,
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
