import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_text.dart';

/// Create-plan form for the Hadith planner.
///
/// Reached from the "Create Plan" action on [HadithPlannerScreen]. "Create"
/// pops with the entered plan name so the planner can append the new plan.
class HadithCreatePlanScreen extends StatefulWidget {
  const HadithCreatePlanScreen({super.key});

  @override
  State<HadithCreatePlanScreen> createState() => _HadithCreatePlanScreenState();
}

class _HadithCreatePlanScreenState extends State<HadithCreatePlanScreen> {
  final _planNameController = TextEditingController();
  bool _added = false;

  @override
  void dispose() {
    _planNameController.dispose();
    super.dispose();
  }

  String get _planName {
    final name = _planNameController.text.trim();
    return name.isEmpty ? 'Plan 1' : name;
  }

  void _create() => Navigator.of(context).pop(_planName);

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
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
                      onAddMore: () => setState(() => _added = false),
                    )
                  : _PlanForm(
                      controller: _planNameController,
                      onAdd: () => setState(() => _added = true),
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 9.h),
              child: SizedBox(
                width: double.infinity,
                height: 56.h,
                child: FilledButton(
                  onPressed: _create,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFA1AD59),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.r),
                    ),
                  ),
                  child: Text(
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
    );
  }
}

class _PlanForm extends StatelessWidget {
  const _PlanForm({required this.controller, required this.onAdd});

  final TextEditingController controller;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(15.w, 5.h, 15.w, 20.h),
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            appText.planNameLabel,
            style: TextStyle(fontSize: 14.sp),
          ),
        ),
        SizedBox(height: 9.h),
        TextField(
          controller: controller,
          style: TextStyle(fontSize: 13.sp),
          decoration: _fieldDecoration(appText.writeHereHint),
        ),
        SizedBox(height: 14.h),
        Container(
          padding: EdgeInsets.fromLTRB(23.w, 28.h, 23.w, 28.h),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFCBD16B)),
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
              _SelectionField(hint: appText.egSahihBukhariHint),
              SizedBox(height: 22.h),
              Text(
                appText.selectCategory,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 16.h),
              _SelectionField(hint: appText.egHadithCategoryHint),
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

class _AddedView extends StatelessWidget {
  const _AddedView({required this.planName, required this.onAddMore});

  final String planName;
  final VoidCallback onAddMore;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 7.h, 16.w, 20.h),
      children: [
        Text(planName, style: TextStyle(fontSize: 14.sp)),
        SizedBox(height: 16.h),
        Container(
          height: 76.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFDDE8C1)),
            borderRadius: BorderRadius.circular(21.r),
          ),
          child: Row(
            children: [
              Container(
                width: 47.w,
                height: 47.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFDDE8C1)),
                ),
                child: Icon(
                  Icons.menu_book_outlined,
                  color: const Color(0xFF8B9865),
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appText.hadithCategorySample,
                    style: TextStyle(
                      color: const Color(0xFF332B57),
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 7.h),
                  Text(
                    appText.hadithCountSample,
                    style: TextStyle(
                      color: const Color(0xFFA1AD59),
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(top: 11.h, right: 1.w),
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
      height: 62.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 19.w,
            top: 6.h,
            child: IconButton(
              onPressed: onBack,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFCBD16B),
                foregroundColor: const Color(0xFF303629),
                minimumSize: Size(38.r, 38.r),
                padding: EdgeInsets.zero,
              ),
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 15.sp),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: const Color(0xFF84945F),
              fontSize: 18.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _fieldDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFB8B8B8)),
    contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFFDDE8C1)),
      borderRadius: BorderRadius.circular(25.r),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFFA1AD59)),
      borderRadius: BorderRadius.circular(25.r),
    ),
  );
}

class _SelectionField extends StatelessWidget {
  const _SelectionField({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.h,
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDDE8C1)),
        borderRadius: BorderRadius.circular(25.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hint,
              style: TextStyle(color: const Color(0xFFB8B8B8), fontSize: 13.sp),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: const Color(0xFFA1AD59),
            size: 22.sp,
          ),
        ],
      ),
    );
  }
}
