import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/profile/domain/entities/badge_entity.dart';
import 'package:tuhfatul_muslim/features/profile/domain/entities/profile_entity.dart';

/// The badges on the profile card: the one worn (or, before any is reached,
/// the first as a goal), how far off the next one is, and every tier in a
/// row, reached ones in full and the rest dimmed. Tapping lists them all.
/// Nothing shows until an admin has set badges up.
class ProfileBadges extends StatelessWidget {
  const ProfileBadges({super.key, required this.profile});

  final ProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final badges = profile.badges;
    if (badges.isEmpty) return const SizedBox.shrink();
    final current = profile.currentBadge;
    final next = profile.nextBadge;
    final from = current?.startPoints ?? 0;
    final to = next?.startPoints;
    final progress = to == null || to <= from
        ? 1.0
        : ((profile.totalPoints - from) / (to - from)).clamp(0.0, 1.0);
    return InkWell(
      key: const ValueKey('profile-badges'),
      onTap: () => _showBadges(context, profile),
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Column(
          children: [
            _CurrentBadge(
              badge: current ?? next ?? badges.first,
              locked: current == null,
            ),
            SizedBox(height: 10.h),
            SizedBox(
              width: 180.w,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6.h,
                  color: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: .3),
                ),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              next == null
                  ? appText.badgeTopReached
                  : context.localizedDigits(
                      appText.badgePointsToNext.fill({
                        'points': _formatPoints(profile.pointsToNextBadge),
                        'name': next.name,
                      }),
                    ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.inkColor(Colors.white.withValues(alpha: .9)),
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 14.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final badge in badges.take(4)) _BadgeCircle(badge: badge),
                if (badges.length > 4)
                  _MoreBadgesCircle(count: badges.length - 4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentBadge extends StatelessWidget {
  const _CurrentBadge({required this.badge, this.locked = false});

  final BadgeEntity badge;

  /// Not reached yet: shown as the goal.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BadgeAvatar(iconUrl: badge.iconUrl, dimension: 56.r, locked: locked),
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

/// A badge's icon in a circle. A [locked] one (not reached yet) is grey
/// and faded, with a lock. [onLight] for a light background (the badge
/// list) rather than the green profile card.
class _BadgeAvatar extends StatelessWidget {
  const _BadgeAvatar({
    required this.iconUrl,
    required this.dimension,
    this.locked = false,
    this.onLight = false,
  });

  final String? iconUrl;
  final double dimension;
  final bool locked, onLight;

  // Desaturates a locked badge's icon.
  static const _grey = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final url = iconUrl;
    final placeholder = _BadgePlaceholderIcon(
      size: dimension * .5,
      color: onLight ? AppColor.primary : Colors.white,
    );
    Widget icon = (url == null || url.isEmpty)
        ? placeholder
        : Image.network(
            url,
            width: dimension,
            height: dimension,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => placeholder,
          );
    if (locked) {
      icon = Opacity(
        opacity: .45,
        child: ColorFiltered(colorFilter: _grey, child: icon),
      );
    }
    return SizedBox(
      width: dimension,
      height: dimension,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: dimension,
            height: dimension,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: onLight
                  ? context.surfaceColor(const Color(0xFFEEF2DD))
                  : Colors.white.withValues(alpha: .28),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF8B9B5A).withValues(alpha: .8),
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: icon,
          ),
          if (locked)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xFF7F8F52),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_rounded,
                  size: dimension * .22,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "+N" circle for the badges beyond the first four.
class _MoreBadgesCircle extends StatelessWidget {
  const _MoreBadgesCircle({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46.r,
      height: 46.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .28),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF8B9B5A).withValues(alpha: .8),
          width: 1,
        ),
      ),
      child: Text(
        context.localizedDigits('+$count'),
        style: TextStyle(
          color: Colors.white.withValues(alpha: .8),
          fontSize: 12.sp,
        ),
      ),
    );
  }
}

class _BadgePlaceholderIcon extends StatelessWidget {
  const _BadgePlaceholderIcon({required this.size, this.color = Colors.white});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.emoji_events_rounded, size: size, color: color);
  }
}

class _BadgeCircle extends StatelessWidget {
  const _BadgeCircle({required this.badge});

  final BadgeEntity badge;

  @override
  Widget build(BuildContext context) {
    return _BadgeAvatar(
      iconUrl: badge.iconUrl,
      dimension: 46.r,
      locked: !badge.isUnlocked,
    );
  }
}

/// Points as the user sees them: whole, or with one decimal.
String _formatPoints(num points) => points == points.roundToDouble()
    ? '${points.round()}'
    : points.toStringAsFixed(1);

/// Every badge, lowest first: icon, name, points range, and either that it
/// is reached or how many points it still needs.
Future<void> _showBadges(BuildContext context, ProfileEntity profile) {
  final appText = AppText.of(context);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: context.surfaceColor(Colors.white),
    builder: (sheet) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheet).height * .75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 8.h),
              child: Text(
                appText.badgesTitle,
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.only(bottom: 12.h),
                children: [
                  for (final badge in profile.badges)
                    ListTile(
                      key: ValueKey('badge-${badge.slug}'),
                      leading: _BadgeAvatar(
                        iconUrl: badge.iconUrl,
                        dimension: 44.r,
                        locked: !badge.isUnlocked,
                        onLight: true,
                      ),
                      title: Text(
                        badge.name,
                        style: TextStyle(
                          fontWeight: badge.slug == profile.currentBadge?.slug
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        sheet.localizedDigits(
                          appText.badgePointsRange.fill({
                            'from': _formatPoints(badge.startPoints),
                            'to': _formatPoints(badge.endPoints),
                          }),
                        ),
                      ),
                      trailing: badge.isUnlocked
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColor.primary,
                                  size: 18,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  appText.badgeUnlocked,
                                  style: TextStyle(fontSize: 12.sp),
                                ),
                              ],
                            )
                          : Text(
                              sheet.localizedDigits(
                                appText.badgeMorePoints.fill({
                                  'points': _formatPoints(
                                    badge.startPoints - profile.totalPoints,
                                  ),
                                }),
                              ),
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: sheet.inkColor(Colors.black54),
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
  );
}
