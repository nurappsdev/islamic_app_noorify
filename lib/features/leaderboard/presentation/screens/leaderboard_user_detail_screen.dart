import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/leaderboard/data/services/leaderboard_service.dart';
import 'package:tuhfatul_muslim/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:tuhfatul_muslim/features/leaderboard/domain/entities/leaderboard_user_detail.dart';
import 'package:tuhfatul_muslim/features/leaderboard/presentation/widgets/leaderboard_avatar.dart';
import 'package:tuhfatul_muslim/features/leaderboard/presentation/widgets/leaderboard_compare_chart.dart';

/// One user's standing (design `devImg/img_61.png`), opened by tapping a user
/// on [LeaderboardScreen]. Loads `GET /leaderboard/users/:userId` for the
/// [period] that was selected there, and for that period's [date] key
/// (`2026-09`) as the list's own response reported it.
class LeaderboardUserDetailScreen extends StatefulWidget {
  const LeaderboardUserDetailScreen({
    super.key,
    required this.userId,
    required this.period,
    this.date,
    this.isCurrentUser = false,
  });

  final String userId;

  /// `daily`, `weekly`, `monthly` or `yearly`.
  final String period;

  /// The period's key from the list's response; `null` lets the server use the
  /// current period.
  final String? date;

  /// Whether this is the signed-in user, so the card says "Your Rank".
  final bool isCurrentUser;

  @override
  State<LeaderboardUserDetailScreen> createState() =>
      _LeaderboardUserDetailScreenState();
}

class _LeaderboardUserDetailScreenState
    extends State<LeaderboardUserDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  LeaderboardUserDetail? _detail;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final result = await LeaderboardService.instance.fetchUserPosition(
      userId: widget.userId,
      period: widget.period,
      date: widget.date,
    );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _isLoading = false;
        _errorMessage = failure.message;
      }),
      (detail) => setState(() {
        _isLoading = false;
        _detail = detail;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final detail = _detail;
    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 6.h),
            _Header(title: appText.leaderboardTitle),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                color: AppColor.primary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
                  children: [
                    if (detail != null)
                      ..._content(context, appText, detail)
                    else if (_isLoading)
                      const _Loading()
                    else
                      _Error(
                        message: _errorMessage ?? appText.failureUnknown,
                        onRetry: _load,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    AppText appText,
    LeaderboardUserDetail d,
  ) {
    final rank = d.rank;
    final ranked = d.isRanked && rank != null && rank > 0;
    final competitor = ranked && !d.isFirst && d.pointsBehindNext != null
        ? d.points + d.pointsBehindNext!
        : null;
    return [
      _Profile(detail: d),
      SizedBox(height: 18.h),
      _RankCard(
        detail: d,
        ranked: ranked,
        isCurrentUser: widget.isCurrentUser,
        appText: appText,
      ),
      if (ranked) ...[
        SizedBox(height: 22.h),
        Wrap(
          spacing: 20.w,
          runSpacing: 8.h,
          children: [
            _LegendDot(color: leaderboardMyColor, label: appText.myPosition),
            if (competitor != null)
              _LegendDot(
                color: leaderboardCompetitorColor,
                label: appText.myNearestOrCompetitor,
              ),
          ],
        ),
        SizedBox(height: 14.h),
        LeaderboardCompareChart(
          myPoints: d.points,
          competitorPoints: competitor,
        ),
        SizedBox(height: 8.h),
        Center(
          child: Text(
            context.localizedDigits(d.period.label),
            style: TextStyle(
              fontSize: 12.sp,
              color: context.inkColor(const Color(0xFF3B4430)),
            ),
          ),
        ),
      ],
      SizedBox(height: 22.h),
      // The leaderboard API carries no Quran reading stats, so these two cards
      // show a dash rather than made-up numbers.
      _InfoCard(label: appText.leaderboardTotalQuranTime, value: '—'),
      SizedBox(height: 14.h),
      _InfoCard(label: appText.leaderboardMostReadingSura, value: '—'),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 14.w),
              child: IconButton(
                onPressed: () => Navigator.maybePop(context),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFCBD16B),
                  foregroundColor: context.inkColor(const Color(0xFF303629)),
                  minimumSize: Size(38.r, 38.r),
                ),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: AppColor.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar in an orange ring over the green name / points box.
class _Profile extends StatelessWidget {
  const _Profile({required this.detail});

  final LeaderboardUserDetail detail;

  @override
  Widget build(BuildContext context) {
    final badge = detail.badge;
    final ink = context.inkColor(const Color(0xFF3A3A3A));
    return Column(
      children: [
        Container(
          width: 104.r,
          height: 104.r,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE07B00), width: 4),
          ),
          child: ClipOval(
            child: LeaderboardAvatar(
              url: detail.avatarUrl,
              fallbackName: detail.name,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          constraints: BoxConstraints(minWidth: 150.w, maxWidth: 260.w),
          padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: context.surfaceColor(const Color(0xFFDCE8B8)),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                detail.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w500,
                  color: context.inkColor(const Color(0xFF6B7551)),
                ),
              ),
              SizedBox(height: 6.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.monetization_on,
                    size: 14.sp,
                    color: const Color(0xFFFFC83D),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    context.localizedDigits(
                      formatLeaderboardPoints(detail.points),
                    ),
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                ],
              ),
              if (badge != null && badge.name.isNotEmpty) ...[
                SizedBox(height: 8.h),
                _BadgeChip(badge: badge),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge});

  final LeaderboardBadge badge;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      Icons.workspace_premium_rounded,
      size: 16.sp,
      color: const Color(0xFF7E8C61),
    );
    final url = badge.iconUrl.trim();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (url.isEmpty)
          icon
        else
          Image.network(
            url,
            width: 16.r,
            height: 16.r,
            errorBuilder: (_, _, _) => icon,
          ),
        SizedBox(width: 5.w),
        Flexible(
          child: Text(
            badge.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.sp,
              color: context.inkColor(const Color(0xFF5F6B45)),
            ),
          ),
        ),
      ],
    );
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard({
    required this.detail,
    required this.ranked,
    required this.isCurrentUser,
    required this.appText,
  });

  final LeaderboardUserDetail detail;
  final bool ranked;
  final bool isCurrentUser;
  final AppText appText;

  /// How far along the way to the next rank: points earned out of points
  /// earned plus the gap left. Full for the leader.
  double get _progress {
    if (!ranked) return 0;
    final gap = detail.pointsBehindNext;
    if (detail.isFirst || gap == null || gap <= 0) return 1;
    final total = detail.points + gap;
    return total <= 0 ? 0 : (detail.points / total).clamp(0, 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final rank = detail.rank;
    final behindNext = detail.pointsBehindNext;
    final behindFirst = detail.pointsBehindFirst;
    final first = detail.firstPlace;
    final muted = context.inkColor(const Color(0xFF8A9A5B));

    String gapToNext() =>
        '${formatLeaderboardPoints(behindNext!)} ${appText.ptsToRank} '
        '#${rank! - 1}';

    String gapToFirst() {
      final points = formatLeaderboardPoints(behindFirst!);
      return first == null || first.name.isEmpty
          ? appText.leaderboardPointsBehindFirst.replaceAll('{points}', points)
          : appText.leaderboardPointsBehindFirstNamed
                .replaceAll('{points}', points)
                .replaceAll('{name}', first.name);
    }

    final lines = <String>[
      if (ranked && detail.isFirst) appText.leaderboardFirstPlace,
      if (ranked && !detail.isFirst && behindNext != null && rank! > 1)
        gapToNext(),
    ];
    final showFirstLine = ranked && !detail.isFirst && behindFirst != null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 16.h),
      decoration: BoxDecoration(
        color: context.surfaceColor(const Color(0xFFF7F7E7)),
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: isCurrentUser
                            ? appText.yourRank
                            : appText.leaderboardRankLabel,
                        style: TextStyle(fontSize: 17.sp, color: muted),
                      ),
                      if (ranked)
                        TextSpan(
                          text: context.localizedDigits('   #$rank'),
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w600,
                            color: context.inkColor(const Color(0xFF5F6B45)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    context.localizedDigits(
                      '${formatLeaderboardPoints(detail.points)} '
                      '${appText.pointsLabel}',
                    ),
                    style: TextStyle(fontSize: 13.sp, color: muted),
                  ),
                  if (detail.totalParticipants > 0)
                    Text(
                      context.localizedDigits(
                        appText.leaderboardParticipants.replaceAll(
                          '{n}',
                          '${detail.totalParticipants}',
                        ),
                      ),
                      style: TextStyle(fontSize: 10.sp, color: muted),
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: 14.h),
          if (ranked) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 14.h,
                backgroundColor: context.surfaceColor(const Color(0xFFECEFD8)),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFCBD79A)),
              ),
            ),
            for (final line in lines) ...[
              SizedBox(height: 10.h),
              Text(
                context.localizedDigits(line),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: context.inkColor(const Color(0xFF5F6B45)),
                ),
              ),
            ],
            if (showFirstLine) ...[
              SizedBox(height: 12.h),
              Row(
                children: [
                  if (first != null) ...[
                    SizedBox.square(
                      dimension: 22.r,
                      child: ClipOval(
                        child: LeaderboardAvatar(
                          url: first.avatarUrl,
                          fallbackName: first.name,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                  ],
                  Expanded(
                    child: Text(
                      context.localizedDigits(gapToFirst()),
                      style: TextStyle(fontSize: 12.sp, color: muted),
                    ),
                  ),
                ],
              ),
            ],
          ] else
            Text(
              appText.leaderboardNotRanked,
              style: TextStyle(
                fontSize: 12.sp,
                color: context.inkColor(const Color(0xFF5F6B45)),
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14.r,
          height: 14.r,
          decoration: BoxDecoration(
            color: context.surfaceColor(color),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5.sp,
            color: context.inkColor(const Color(0xFF6A7350)),
          ),
        ),
      ],
    );
  }
}

/// A dashed-outline card with a centred [label] and [value].
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: context.lineColor(const Color(0xFFC7D2A0)),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 22.h, horizontal: 14.w),
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: context.inkColor(const Color(0xFF2C3320)),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: context.inkColor(const Color(0xFF2C3320)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)),
      );
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) => old.color != color;
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 120.h),
      child: const Center(
        child: CircularProgressIndicator(color: AppColor.primary),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 100.h),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.sp),
          ),
          SizedBox(height: 12.h),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(backgroundColor: AppColor.primary),
            child: Text(AppText.of(context).tryAgain),
          ),
        ],
      ),
    );
  }
}
