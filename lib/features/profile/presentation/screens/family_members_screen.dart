import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/profile/data/services/family_service.dart';
import 'package:islami_app_noorify/features/profile/domain/entities/family_member_entity.dart';

class FamilyMembersScreen extends StatefulWidget {
  const FamilyMembersScreen({super.key});

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  List<FamilyMemberEntity> _members = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  /// Same request the profile screen makes.
  Future<void> _load() async {
    final members = await FamilyService.instance.fetchFamilyMembers();
    if (!mounted) return;
    setState(() {
      _members = members;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
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
                if (!_loaded)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: const Center(child: CircularProgressIndicator()),
                  )
                else if (_members.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: Center(
                      child: Text(
                        'No data here',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: context.inkColor(const Color(0xFF6B7551)),
                        ),
                      ),
                    ),
                  )
                else
                  for (final member in _members) ...[
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
                foregroundColor: Color(0xFF303629),
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
                  borderSide: BorderSide(
                    color: context.lineColor(Color(0xFFDDE8C1)),
                  ),
                  borderRadius: BorderRadius.circular(22.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColor.primary),
                  borderRadius: BorderRadius.circular(22.r),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: context.lineColor(Color(0xFFDDE8C1)),
                  ),
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
              backgroundColor: context.surfaceColor(Color(0xFFDDE8AE)),
              foregroundColor: AppColor.primary,
            ),
            icon: Icon(Icons.search_rounded, size: 20.sp),
          ),
        ),
      ],
    );
  }
}

class _FamilyMemberCard extends StatelessWidget {
  const _FamilyMemberCard({required this.member});

  final FamilyMemberEntity member;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: context.surfaceColor(Color(0xFFF3F5E4)),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Text(
            '#${member.globalRank}',
            style: TextStyle(
              fontSize: 13.sp,
              color: context.inkColor(Color(0xFF6B7551)),
            ),
          ),
          SizedBox(width: 10.w),
          _MemberAvatar(
            avatarUrl: member.memberAvatarUrl,
            name: member.memberName,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              member.memberName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
            '${member.memberTotalPoints}',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.avatarUrl, required this.name});

  final String? avatarUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final placeholder = CircleAvatar(
      radius: 15.r,
      backgroundColor: context.surfaceColor(Color(0xFFCFCFEA)),
      child: Text(
        trimmed.isEmpty ? '?' : trimmed[0].toUpperCase(),
        style: TextStyle(
          color: context.inkColor(Color(0xFF5B5B8C)),
          fontSize: 12.sp,
        ),
      ),
    );
    final url = avatarUrl;
    if (url == null || url.isEmpty) return placeholder;
    return ClipOval(
      child: Image.network(
        url,
        width: 30.r,
        height: 30.r,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
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
