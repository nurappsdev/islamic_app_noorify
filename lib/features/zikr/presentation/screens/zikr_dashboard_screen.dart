import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/zikr/data/zikr_catalog.dart';
import 'package:islami_app_noorify/features/zikr/presentation/widgets/zikr_bottom_nav.dart';
import 'package:islami_app_noorify/features/zikr/presentation/zikr_route_args.dart';

/// Zikr dashboard, reached from "Let's Get Start" on [ZikrIntroScreen].
///
/// UI only — the totals and the "My Created Zikr" card are mock data. Tapping a
/// zikr opens [ZikrCounterScreen].
class ZikrDashboardScreen extends StatelessWidget {
  const ZikrDashboardScreen({super.key});

  void _openCounter(BuildContext context, ZikrCounterArgs args) {
    Navigator.of(context).pushNamed(RouteNames.zikrCounter, arguments: args);
  }

  Future<void> _showCreateSheet(BuildContext context) async {
    final appText = AppText.of(context);
    final nameController = TextEditingController();
    final targetController = TextEditingController(text: '33');

    final args = await showModalBottomSheet<ZikrCounterArgs>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20.w,
            16.h,
            20.w,
            16.h + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCE3C4),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                appText.zikrCreateTitle,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 14.h),
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: appText.zikrCreateNameHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: appText.zikrCreateTargetHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                  ),
                  onPressed: () {
                    final name = nameController.text.trim();
                    final target = int.tryParse(targetController.text.trim());
                    Navigator.pop(
                      sheetContext,
                      ZikrCounterArgs(
                        title: name.isEmpty ? appText.zikrTitle : name,
                        arabic: '',
                        target: (target == null || target <= 0) ? 33 : target,
                      ),
                    );
                  },
                  child: Text(
                    appText.zikrCreateAdd,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 6.h),
            ],
          ),
        );
      },
    );

    nameController.dispose();
    targetController.dispose();
    if (args != null && context.mounted) _openCounter(context, args);
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(bottom: 150.h + bottomInset),
            children: [
              _Header(appText: appText, onOpenCounter: _openCounter),
              SizedBox(height: 22.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                child: Text(
                  appText.zikrMyCreatedZikr,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _CreatedZikrCard(
                  preset: ZikrCatalog.createdSample,
                  appText: appText,
                  onOpenItem: (item) =>
                      _openCounter(context, ZikrCounterArgs.fromItem(item)),
                  onGetStart: () => _openCounter(
                    context,
                    ZikrCounterArgs.fromPreset(ZikrCatalog.createdSample),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 24.w,
            bottom: 74.h + bottomInset,
            child: _AddButton(onTap: () => _showCreateSheet(context)),
          ),
          const SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ZikrBottomNav(selectedIndex: 1),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.appText, required this.onOpenCounter});

  final AppText appText;
  final void Function(BuildContext, ZikrCounterArgs) onOpenCounter;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8FA45C), Color(0xFF4F7A43)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26.r)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 20.h),
          child: Column(
            children: [
              SizedBox(
                height: 40.h,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFEDE7A6),
                          foregroundColor: AppColor.authLogo,
                        ),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                        ),
                      ),
                    ),
                    Text(
                      appText.zikrTitle,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Image.asset(
                'assets/images/bismillah.png',
                height: 26.h,
                fit: BoxFit.contain,
                color: Colors.white,
              ),
              SizedBox(height: 16.h),
              Text(
                appText.zikrTotalZikr,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .9),
                  fontSize: 14.sp,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                ZikrCatalog.formatIndian(ZikrCatalog.mockTotalCount),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 16.h),
              _LastZikrPill(
                appText: appText,
                onTap: () => onOpenCounter(
                  context,
                  ZikrCounterArgs.fromItem(ZikrCatalog.mockLastZikr),
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  for (var i = 0; i < ZikrCatalog.prayerPresets.length; i++) ...[
                    if (i > 0) SizedBox(width: 12.w),
                    Expanded(
                      child: _PresetPill(
                        preset: ZikrCatalog.prayerPresets[i],
                        onTap: () => onOpenCounter(
                          context,
                          ZikrCounterArgs.fromPreset(
                            ZikrCatalog.prayerPresets[i],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LastZikrPill extends StatelessWidget {
  const _LastZikrPill({required this.appText, required this.onTap});

  final AppText appText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30.r),
      child: Container(
        padding: EdgeInsets.fromLTRB(18.w, 8.h, 8.w, 8.h),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: .55)),
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: Row(
          children: [
            Text(
              '${appText.zikrLastZikr}   ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.sp,
                fontStyle: FontStyle.italic,
              ),
            ),
            Expanded(
              child: Text(
                ZikrCatalog.mockLastZikr.arabic,
                style: TextStyle(color: Colors.white, fontSize: 15.sp),
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              '${ZikrCatalog.mockLastZikrDone}/'
              '${ZikrCatalog.mockLastZikr.target}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .9),
                fontSize: 12.sp,
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              width: 30.r,
              height: 30.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: .7)),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 18.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetPill extends StatelessWidget {
  const _PresetPill({required this.preset, required this.onTap});

  final ZikrPreset preset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22.r),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 11.h, horizontal: 10.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(color: Colors.white.withValues(alpha: .35)),
            ),
            child: Text(
              preset.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          preset.formula,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .85),
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }
}

class _CreatedZikrCard extends StatelessWidget {
  const _CreatedZikrCard({
    required this.preset,
    required this.appText,
    required this.onOpenItem,
    required this.onGetStart,
  });

  final ZikrPreset preset;
  final AppText appText;
  final ValueChanged<ZikrItem> onOpenItem;
  final VoidCallback onGetStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFFDCE8C4),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFC7D6A6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preset.name,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3C4A28),
            ),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              for (final item in preset.items)
                InkWell(
                  onTap: () => onOpenItem(item),
                  borderRadius: BorderRadius.circular(20.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 9.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: const Color(0xFFCBD9AF)),
                    ),
                    child: Text(
                      item.labelWithTarget,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF3C4A28),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: onGetStart,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF9AAA63),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
              child: Text(
                appText.zikrGetStart,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF9AAA63),
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Icon(Icons.add_rounded, color: Colors.white, size: 26.sp),
        ),
      ),
    );
  }
}
