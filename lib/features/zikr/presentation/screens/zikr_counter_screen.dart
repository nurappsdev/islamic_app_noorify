import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/zikr/presentation/zikr_route_args.dart';

/// Simple tap-to-count screen for a single zikr.
///
/// Not part of the provided designs — a lightweight counter that the dashboard
/// chips, "Get start" and the "All Zikr" list open. The count lives only in
/// memory and is lost when the screen is popped.
class ZikrCounterScreen extends StatefulWidget {
  const ZikrCounterScreen({super.key, required this.args});

  final ZikrCounterArgs args;

  @override
  State<ZikrCounterScreen> createState() => _ZikrCounterScreenState();
}

class _ZikrCounterScreenState extends State<ZikrCounterScreen> {
  int _count = 0;
  int _rounds = 0;

  int get _target => widget.args.target;

  void _increment() {
    HapticFeedback.selectionClick();
    setState(() {
      _count++;
      if (_target > 0 && _count % _target == 0) {
        _rounds++;
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _reset() {
    HapticFeedback.lightImpact();
    setState(() {
      _count = 0;
      _rounds = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final progress = _target > 0 ? (_count % _target) / _target : 0.0;
    final inRound = _target > 0 ? _count % _target : _count;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFDFEFB),
              Color(0xFFF1F5E4),
              Color(0xFFD8E5BC),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 8.h),
              Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 12.w),
                    child: IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFDFDE68),
                        foregroundColor: const Color(0xFF303629),
                      ),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.args.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColor.authLogo,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: 60.w),
                ],
              ),
              if (widget.args.arabic.isNotEmpty) ...[
                SizedBox(height: 18.h),
                Text(
                  widget.args.arabic,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 26.sp,
                    height: 1.8,
                    color: const Color(0xFF283016),
                  ),
                ),
              ],
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _increment,
                  child: Center(
                    child: SizedBox(
                      width: 240.r,
                      height: 240.r,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 240.r,
                            height: 240.r,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 10.r,
                              backgroundColor: Colors.white.withValues(
                                alpha: .6,
                              ),
                              valueColor: const AlwaysStoppedAnimation(
                                AppColor.primary,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$inRound',
                                style: TextStyle(
                                  fontSize: 64.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2C3320),
                                ),
                              ),
                              Text(
                                '$inRound / $_target',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: const Color(0xFF5D6B44),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                'Total  $_count   •   Rounds  $_rounds',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF5D6B44),
                ),
              ),
              SizedBox(height: 14.h),
              TextButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4C5A34),
                ),
                label: Text(
                  appText.zikrCounterReset,
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
