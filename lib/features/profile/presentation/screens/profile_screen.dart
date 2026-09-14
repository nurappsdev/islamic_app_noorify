import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/auth/data/repositories/account_repository_impl.dart';
import 'package:islami_app_noorify/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:islami_app_noorify/features/auth/domain/usecases/logout_user.dart';
import 'package:islami_app_noorify/features/auth/presentation/bloc/logout/logout_bloc.dart';
import 'package:islami_app_noorify/features/profile/data/services/family_service.dart';
import 'package:islami_app_noorify/features/profile/data/services/profile_service.dart';
import 'package:islami_app_noorify/features/profile/domain/entities/badge_entity.dart';
import 'package:islami_app_noorify/features/profile/domain/entities/family_member_entity.dart';
import 'package:islami_app_noorify/features/profile/domain/entities/profile_entity.dart';
import 'package:islami_app_noorify/shared/services/app_globals.dart';
import 'package:islami_app_noorify/shared/widgets/profile_avatar_circle.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileEntity? _profile;
  List<FamilyMemberEntity> _familyMembers = const [];

  @override
  void initState() {
    super.initState();
    _profile = ProfileService.instance.cachedProfile;
    unawaited(_loadProfile());
    unawaited(_loadFamilyMembers());
  }

  Future<void> _loadProfile() async {
    final profile = await ProfileService.instance.fetchProfile();
    if (!mounted || profile == null) return;
    setState(() => _profile = profile);
  }

  Future<void> _loadFamilyMembers() async {
    final members = await FamilyService.instance.fetchFamilyMembers();
    if (!mounted) return;
    setState(() => _familyMembers = members);
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final profile = _profile;
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
                _ProfileHeroCard(profile: profile),
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
                for (final member in _familyMembers) ...[
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
              left: 16.w,
              right: 16.w,
              bottom: 12.h,
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
  const _ProfileHeroCard({required this.profile});

  final ProfileEntity? profile;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final progress = (profile?.profileCompletionPercentage ?? 0) / 100;
    final badges = profile?.badges ?? const <BadgeEntity>[];
    final currentBadge = profile?.currentBadge;
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
          ValueListenableBuilder<String?>(
            valueListenable: profileNameNotifier,
            builder: (context, name, _) {
              return Text(
                (name == null || name.isEmpty) ? appText.competitorName : name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19.sp,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
          SizedBox(height: 4.h),
          Text(
            '${appText.trishal}, ${appText.mymensingh}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .85),
              fontSize: 12.sp,
            ),
          ),
          if (currentBadge != null) ...[
            SizedBox(height: 18.h),
            _CurrentBadge(badge: currentBadge),
          ],
          if (badges.isNotEmpty) ...[
            SizedBox(height: 18.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final badge in badges) _BadgeCircle(badge: badge),
              ],
            ),
          ],
          SizedBox(height: 18.h),
          _PositionPointsPill(
            position: profile?.globalRankPosition ?? 0,
            points: profile?.totalPoints ?? 0,
          ),
        ],
      ),
    );
  }
}

class _CurrentBadge extends StatelessWidget {
  const _CurrentBadge({required this.badge});

  final BadgeEntity badge;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BadgeAvatar(iconUrl: badge.iconUrl, dimension: 56.r),
        SizedBox(height: 6.h),
        Text(
          badge.name,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _BadgeAvatar extends StatelessWidget {
  const _BadgeAvatar({required this.iconUrl, required this.dimension});

  final String? iconUrl;
  final double dimension;

  @override
  Widget build(BuildContext context) {
    final url = iconUrl;
    return Container(
      width: dimension,
      height: dimension,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFB9C36E),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: (url == null || url.isEmpty)
          ? _BadgePlaceholderIcon(size: dimension * .5)
          : Image.network(
              url,
              width: dimension,
              height: dimension,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _BadgePlaceholderIcon(size: dimension * .5),
            ),
    );
  }
}

class _BadgePlaceholderIcon extends StatelessWidget {
  const _BadgePlaceholderIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.emoji_events_rounded, size: size, color: Colors.white);
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
          ProfileAvatarCircle(
            dimension: 84.r,
            backgroundColor: Colors.white,
            placeholderIconColor: const Color(0xFFB7C17E),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () =>
                  Navigator.of(context).pushNamed(RouteNames.editProfile),
              child: Container(
                width: 26.r,
                height: 26.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColor.primary,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  Icons.edit_rounded,
                  size: 13.sp,
                  color: Colors.white,
                ),
              ),
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
  const _BadgeCircle({required this.badge});

  final BadgeEntity badge;

  @override
  Widget build(BuildContext context) {
    return _BadgeAvatar(iconUrl: badge.iconUrl, dimension: 46.r);
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

class _FamilyMemberCard extends StatelessWidget {
  const _FamilyMemberCard({required this.member});

  final FamilyMemberEntity member;

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
            '#${member.globalRank}',
            style: TextStyle(fontSize: 13.sp, color: const Color(0xFF6B7551)),
          ),
          SizedBox(width: 10.w),
          _FamilyMemberAvatar(
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

class _FamilyMemberAvatar extends StatelessWidget {
  const _FamilyMemberAvatar({required this.avatarUrl, required this.name});

  final String? avatarUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final trimmedName = name.trim();
    final placeholder = CircleAvatar(
      radius: 15.r,
      backgroundColor: const Color(0xFFCFCFEA),
      child: Text(
        trimmedName.isEmpty ? '?' : trimmedName[0].toUpperCase(),
        style: TextStyle(color: const Color(0xFF5B5B8C), fontSize: 12.sp),
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
    return BlocProvider<LogoutBloc>(
      create: (_) => LogoutBloc(
        LogoutUser(AccountRepositoryImpl(AuthRemoteDataSourceImpl())),
      ),
      child: const _LogoutButtonView(),
    );
  }
}

class _LogoutButtonView extends StatelessWidget {
  const _LogoutButtonView();

  void _onLogoutState(BuildContext context, LogoutState state) {
    if (!state.isDone) return;
    // Token was removed from Hive by the bloc; clear the rest of the session
    // and send the user back to the sign-in screen.
    skipAuthGateNotifier.value = false;
    unawaited(ProfileService.instance.clear());
    Navigator.of(context).pushNamedAndRemoveUntil(
      RouteNames.signIn,
      (route) => false,
    );
  }

  Future<void> _confirmLogout(BuildContext context, AppText appText) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          appText.logout,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
        ),
        content: Text(appText.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(appText.no),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColor.forgotPassword,
            ),
            child: Text(appText.yes),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<LogoutBloc>().add(const LogoutRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LogoutBloc, LogoutState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _onLogoutState,
      builder: (context, state) {
        final appText = AppText.of(context);
        return SizedBox(
          height: 52.h,
          child: OutlinedButton(
            onPressed: state.inProgress
                ? null
                : () => _confirmLogout(context, appText),
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
                      appText.logout,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (state.inProgress)
                  SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
