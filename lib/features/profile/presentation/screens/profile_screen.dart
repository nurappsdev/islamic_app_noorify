import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _progress = .67;

  static List<_FamilyMember> _members(AppText appText) => [
    _FamilyMember(
      rank: 4,
      name: appText.familyMemberNameAbdullah,
      relation: appText.brother,
      points: 831,
    ),
    _FamilyMember(
      rank: 5,
      name: appText.familyMemberNameSabit,
      relation: appText.brother,
      points: 812,
    ),
    _FamilyMember(
      rank: 6,
      name: appText.familyMemberNameAli,
      relation: appText.brother,
      points: 786,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final members = _members(appText);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 100.h),
              children: [
                _ProfileHeader(onBack: () => Navigator.maybePop(context)),
                SizedBox(height: 14.h),
                const _ProfileHeroCard(progress: _progress),
                SizedBox(height: 24.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      appText.familyMember,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(RouteNames.familyMembers),
                      child: Text(
                        appText.seeAll,
                        style: TextStyle(
                          fontSize: 13.sp,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                for (final member in members) ...[
                  _FamilyMemberCard(member: member),
                  SizedBox(height: 10.h),
                ],
              ],
            ),
            Positioned(
              right: 4.w,
              bottom: 76.h,
              child: const _AddFamilyMemberButton(),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 8.h,
              child: const _LogoutButton(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return SizedBox(
      height: 44.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: appText.back,
              onPressed: onBack,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFDFDE68),
                foregroundColor: const Color(0xFF303629),
              ),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            ),
          ),
          Text(
            appText.profileTitle,
            style: TextStyle(
              color: AppColor.primary,
              fontSize: 19.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(RouteNames.settings),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFDFDE68),
                foregroundColor: const Color(0xFF303629),
              ),
              icon: const Icon(Icons.settings_outlined, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18.w, 28.h, 18.w, 22.h),
      decoration: BoxDecoration(
        color: const Color(0xFFA7B462),
        borderRadius: BorderRadius.circular(28.r),
      ),
      child: Column(
        children: [
          _AvatarWithProgress(progress: progress),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: const Color(0xFFDCE7AC),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Text(
              '${(progress * 100).round()}% ${appText.percentCompleteSuffix}',
              style: TextStyle(
                fontSize: 11.sp,
                color: const Color(0xFF3F4A2C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            appText.competitorName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 19.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '${appText.trishal}, ${appText.mymensingh}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .85),
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 18.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var index = 1; index <= 4; index++)
                _BadgeCircle(label: '${appText.badgeLabel} $index'),
              const _BadgeCircle(label: '+2'),
            ],
          ),
          SizedBox(height: 18.h),
          _PositionPointsPill(position: 24, points: 831),
        ],
      ),
    );
  }
}

class _AvatarWithProgress extends StatelessWidget {
  const _AvatarWithProgress({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final dimension = 104.r;
    return SizedBox(
      width: dimension,
      height: dimension,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(dimension, dimension),
            painter: _ProfileRingPainter(progress: progress),
          ),
          Container(
            width: 84.r,
            height: 84.r,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Icon(
              Icons.person_rounded,
              size: 46.sp,
              color: const Color(0xFFB7C17E),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRingPainter extends CustomPainter {
  const _ProfileRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.shortestSide * .09;
    final rect =
        Offset(strokeWidth / 2, strokeWidth / 2) &
        Size(size.width - strokeWidth, size.height - strokeWidth);

    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: .28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = const Color(0xFF6FCF3E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, trackPaint);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProfileRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _BadgeCircle extends StatelessWidget {
  const _BadgeCircle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46.r,
      height: 46.r,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFB9C36E),
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: EdgeInsets.all(5.r),
        child: FittedBox(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _PositionPointsPill extends StatelessWidget {
  const _PositionPointsPill({required this.position, required this.points});

  final int position;
  final int points;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Container(
      height: 46.h,
      decoration: BoxDecoration(
        color: const Color(0xFF8B9B5A),
        borderRadius: BorderRadius.circular(23.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                '${appText.position} : $position',
                style: TextStyle(color: Colors.white, fontSize: 12.sp),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 20.h,
            color: Colors.white.withValues(alpha: .4),
          ),
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${appText.pointsWord} : ',
                    style: TextStyle(color: Colors.white, fontSize: 12.sp),
                  ),
                  Icon(
                    Icons.monetization_on,
                    color: const Color(0xFFFFC83D),
                    size: 15.sp,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    '$points',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyMember {
  const _FamilyMember({
    required this.rank,
    required this.name,
    required this.relation,
    required this.points,
  });

  final int rank;
  final String name;
  final String relation;
  final int points;
}

class _FamilyMemberCard extends StatelessWidget {
  const _FamilyMemberCard({required this.member});

  final _FamilyMember member;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5E4),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Text(
            '#${member.rank}',
            style: TextStyle(fontSize: 13.sp, color: const Color(0xFF6B7551)),
          ),
          SizedBox(width: 10.w),
          CircleAvatar(
            radius: 15.r,
            backgroundColor: const Color(0xFFCFCFEA),
            child: Text(
              'Z',
              style: TextStyle(color: const Color(0xFF5B5B8C), fontSize: 12.sp),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              '${member.name} ( ${member.relation} )',
              style: TextStyle(fontSize: 13.sp),
            ),
          ),
          Icon(
            Icons.monetization_on,
            color: const Color(0xFFFFC83D),
            size: 14.sp,
          ),
          SizedBox(width: 4.w),
          Text(
            '${member.points}',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _AddFamilyMemberButton extends StatelessWidget {
  const _AddFamilyMemberButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 52.r,
      child: FloatingActionButton(
        heroTag: 'profile-add-family-member',
        onPressed: () {},
        backgroundColor: const Color(0xFF6FA83E),
        elevation: 3,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52.h,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFFBEAEA),
          foregroundColor: AppColor.forgotPassword,
          side: const BorderSide(color: AppColor.forgotPassword),
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.logout_rounded, size: 18),
                SizedBox(width: 8.w),
                Text(
                  AppText.of(context).logout,
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}
