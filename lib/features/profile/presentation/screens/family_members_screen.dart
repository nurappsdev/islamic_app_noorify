import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';

class FamilyMembersScreen extends StatelessWidget {
  const FamilyMembersScreen({super.key});

  static List<_FamilyMember> _members(AppText appText) => [
    _FamilyMember(rank: 4, name: appText.familyMemberNameAbdullah, points: 831),
    _FamilyMember(rank: 5, name: appText.familyMemberNameSabit, points: 812),
    _FamilyMember(rank: 6, name: appText.familyMemberNameAli, points: 786),
    _FamilyMember(
      rank: 7,
      name: appText.familyMemberNameZulfikur,
      points: 769,
    ),
    _FamilyMember(rank: 8, name: appText.familyMemberNameAsif, points: 720),
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
              padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 90.h),
              children: [
                _FamilyMembersHeader(onBack: () => Navigator.maybePop(context)),
                SizedBox(height: 16.h),
                const _SearchField(),
                SizedBox(height: 18.h),
                for (final member in members) ...[
                  _FamilyMemberCard(member: member),
                  SizedBox(height: 10.h),
                ],
              ],
            ),
            Positioned(
              right: 4.w,
              bottom: 16.h,
              child: const _AddFamilyMemberButton(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilyMembersHeader extends StatelessWidget {
  const _FamilyMembersHeader({required this.onBack});

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
            appText.allFamilyMembers,
            style: TextStyle(
              color: AppColor.primary,
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44.h,
            child: TextField(
              style: TextStyle(fontSize: 13.sp),
              decoration: InputDecoration(
                hintText: AppText.of(context).searchHere,
                hintStyle: TextStyle(
                  color: const Color(0xFFB8B8B8),
                  fontSize: 13.sp,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 18.w),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFFDDE8C1)),
                  borderRadius: BorderRadius.circular(22.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColor.primary),
                  borderRadius: BorderRadius.circular(22.r),
                ),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFFDDE8C1)),
                  borderRadius: BorderRadius.circular(22.r),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        SizedBox.square(
          dimension: 44.r,
          child: IconButton(
            onPressed: () {},
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFDDE8AE),
              foregroundColor: AppColor.primary,
            ),
            icon: Icon(Icons.search_rounded, size: 20.sp),
          ),
        ),
      ],
    );
  }
}

class _FamilyMember {
  const _FamilyMember({
    required this.rank,
    required this.name,
    required this.points,
  });

  final int rank;
  final String name;
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
              member.name,
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
        heroTag: 'family-members-add',
        onPressed: () {},
        backgroundColor: const Color(0xFF6FA83E),
        elevation: 3,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
