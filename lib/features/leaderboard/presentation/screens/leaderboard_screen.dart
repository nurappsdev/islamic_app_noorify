import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/home_bottom_nav.dart';
import 'package:islami_app_noorify/features/leaderboard/data/services/leaderboard_service.dart';
import 'package:islami_app_noorify/features/leaderboard/domain/entities/leaderboard_board.dart';
import 'package:islami_app_noorify/features/leaderboard/domain/entities/leaderboard_entry.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  static const _periods = ['daily', 'weekly', 'monthly', 'yearly'];

  String _period = 'monthly';
  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;
  LeaderboardBoard? _board;

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
    final result = await LeaderboardService.instance.fetchTop(
      period: _period,
    );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _isLoading = false;
        _errorMessage = failure.message;
      }),
      (board) => setState(() {
        _isLoading = false;
        _board = board;
      }),
    );
  }

  void _changePeriod(String period) {
    if (period == _period) return;
    setState(() => _period = period);
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _load,
              color: AppColor.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 92.h),
                children: [
                  Center(
                    child: Text(
                      appText.leaderboardTitle,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColor.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  if (_isLoading && _board == null)
                    const _LeaderboardLoading()
                  else if (_errorMessage != null && _board == null)
                    _LeaderboardError(message: _errorMessage!, onRetry: _load)
                  else if (_board != null)
                    ..._buildContent(context, appText, _board!),
                ],
              ),
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: HomeBottomNav(selectedIndex: 2),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContent(
    BuildContext context,
    AppText appText,
    LeaderboardBoard board,
  ) {
    final podium = board.entries.take(3).toList();
    final query = _searchQuery.trim().toLowerCase();
    final rest = board.entries
        .skip(3)
        .where((e) => query.isEmpty || e.name.toLowerCase().contains(query))
        .toList();
    final showYourRank = !board.meta.isCurrentUserInTop &&
        board.myPosition != null;

    return [
      Align(
        alignment: Alignment.centerRight,
        child: _PeriodDropdown(
          period: _period,
          periods: _periods,
          onChanged: _changePeriod,
        ),
      ),
      SizedBox(height: 18.h),
      if (podium.isNotEmpty) _LeaderboardPodium(entries: podium),
      SizedBox(height: 22.h),
      _SearchField(onChanged: (value) => setState(() => _searchQuery = value)),
      SizedBox(height: 16.h),
      for (final entry in rest) ...[
        _LeaderboardRow(entry: entry),
        SizedBox(height: 10.h),
      ],
      if (showYourRank) ...[
        SizedBox(height: 6.h),
        _YourRankCard(position: board.myPosition!, appText: appText),
      ],
    ];
  }
}

class _LeaderboardLoading extends StatelessWidget {
  const _LeaderboardLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 80.h),
      child: const Center(
        child: CircularProgressIndicator(color: AppColor.primary),
      ),
    );
  }
}

class _LeaderboardError extends StatelessWidget {
  const _LeaderboardError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 60.h),
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

class _PeriodDropdown extends StatelessWidget {
  const _PeriodDropdown({
    required this.period,
    required this.periods,
    required this.onChanged,
  });

  final String period;
  final List<String> periods;
  final ValueChanged<String> onChanged;

  String _label(AppText appText, String key) {
    switch (key) {
      case 'daily':
        return appText.daily;
      case 'weekly':
        return appText.weekly;
      case 'yearly':
        return appText.yearly;
      case 'monthly':
      default:
        return appText.monthly;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final textColor = context.inkColor(const Color(0xFF3A3A3A));
    return PopupMenuButton<String>(
      initialValue: period,
      onSelected: onChanged,
      offset: Offset(0, 42.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      itemBuilder: (context) => periods
          .map(
            (p) => PopupMenuItem<String>(value: p, child: Text(_label(appText, p))),
          )
          .toList(),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: context.surfaceColor(Colors.white),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: context.lineColor(const Color(0xFFDDE8C1))),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _label(appText, period),
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(Icons.keyboard_arrow_down_rounded, size: 16.sp, color: textColor),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardPodium extends StatelessWidget {
  const _LeaderboardPodium({required this.entries});

  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    final first = entries.isNotEmpty ? entries[0] : null;
    final second = entries.length > 1 ? entries[1] : null;
    final third = entries.length > 2 ? entries[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (second != null)
          Expanded(
            child: _PodiumSlot(
              entry: second,
              dimension: 64.r,
              ringColor: const Color(0xFFB9C6DA),
            ),
          ),
        if (first != null)
          Expanded(
            child: _PodiumSlot(
              entry: first,
              dimension: 88.r,
              ringColor: const Color(0xFFF2994A),
              isWinner: true,
            ),
          ),
        if (third != null)
          Expanded(
            child: _PodiumSlot(
              entry: third,
              dimension: 64.r,
              ringColor: const Color(0xFFCE9A7B),
            ),
          ),
      ],
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot({
    required this.entry,
    required this.dimension,
    required this.ringColor,
    this.isWinner = false,
  });

  final LeaderboardEntry entry;
  final double dimension;
  final Color ringColor;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    final badgeSize = 22.r;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: dimension + badgeSize,
          height: dimension + badgeSize,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: dimension,
                height: dimension,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ringColor, width: 3),
                ),
                child: ClipOval(
                  child: _LeaderboardAvatar(
                    url: entry.avatarUrl,
                    fallbackName: entry.name,
                  ),
                ),
              ),
              if (isWinner)
                Positioned(
                  top: -badgeSize / 2,
                  child: Container(
                    width: badgeSize,
                    height: badgeSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ringColor,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      Icons.star_rounded,
                      size: 13.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              Positioned(
                bottom: -badgeSize / 2,
                child: Container(
                  width: badgeSize,
                  height: badgeSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.surfaceColor(Colors.white),
                    border: Border.all(color: ringColor, width: 2),
                  ),
                  child: Text(
                    '${entry.rank}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: context.inkColor(const Color(0xFF3A3A3A)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          constraints: BoxConstraints(maxWidth: dimension + 26.w),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: context.surfaceColor(AppColor.lightTint),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: context.inkColor(const Color(0xFF3A3A3A)),
                ),
              ),
              SizedBox(height: 3.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.monetization_on,
                    size: 12.sp,
                    color: const Color(0xFFFFC83D),
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    '${entry.points}',
                    style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44.h,
            child: TextField(
              onChanged: onChanged,
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
                    color: context.lineColor(const Color(0xFFDDE8C1)),
                  ),
                  borderRadius: BorderRadius.circular(22.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColor.primary),
                  borderRadius: BorderRadius.circular(22.r),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: context.lineColor(const Color(0xFFDDE8C1)),
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
            onPressed: null,
            style: IconButton.styleFrom(
              backgroundColor: context.surfaceColor(AppColor.lightTint),
              foregroundColor: AppColor.primary,
            ),
            icon: Icon(Icons.search_rounded, size: 20.sp),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? context.surfaceColor(AppColor.lightTint)
            : context.surfaceColor(const Color(0xFFF3F5E4)),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Text(
            '#${entry.rank}',
            style: TextStyle(
              fontSize: 13.sp,
              color: context.inkColor(const Color(0xFF6B7551)),
            ),
          ),
          SizedBox(width: 10.w),
          SizedBox(
            width: 30.r,
            height: 30.r,
            child: ClipOval(
              child: _LeaderboardAvatar(
                url: entry.avatarUrl,
                fallbackName: entry.name,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              entry.name,
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
            '${entry.points}',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _YourRankCard extends StatelessWidget {
  const _YourRankCard({required this.position, required this.appText});

  final LeaderboardMyPosition position;
  final AppText appText;

  double get _progress {
    final gap = position.pointsToNextRank;
    if (gap == null || gap <= 0) return 1;
    final total = position.points + gap;
    if (total <= 0) return 0;
    return (position.points / total).clamp(0, 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final gap = position.pointsToNextRank;
    final nextRank = position.nextRank;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.surfaceColor(AppColor.lightTint),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: context.surfaceColor(Colors.white),
                child: Text(
                  '${position.rank}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColor.primary,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  appText.yourRank,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: context.inkColor(const Color(0xFF3A3A3A)),
                  ),
                ),
              ),
              Text(
                '${position.points} ${appText.pointsLabel}',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8.h,
              backgroundColor: context.surfaceColor(const Color(0xFFE0E0E0)),
              valueColor: const AlwaysStoppedAnimation(AppColor.primary),
            ),
          ),
          if (gap != null && nextRank != null) ...[
            SizedBox(height: 6.h),
            Text(
              '$gap ${appText.ptsToRank} #$nextRank',
              style: TextStyle(
                fontSize: 11.sp,
                color: context.inkColor(const Color(0xFF6B7551)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Network avatar with an initial-letter fallback, used for podium slots and
/// list rows alike. Unlike [ProfileAvatarCircle], this renders any entry's
/// [url] rather than the signed-in user's own photo notifiers.
class _LeaderboardAvatar extends StatelessWidget {
  const _LeaderboardAvatar({required this.url, required this.fallbackName});

  final String? url;
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    final trimmed = (url ?? '').trim();
    if (trimmed.isEmpty) return _initialCircle(context);
    return Image.network(
      trimmed,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _initialCircle(context),
    );
  }

  Widget _initialCircle(BuildContext context) {
    final trimmedName = fallbackName.trim();
    final initial = trimmedName.isNotEmpty ? trimmedName[0].toUpperCase() : '?';
    return Container(
      color: context.surfaceColor(const Color(0xFFCFCFEA)),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: context.inkColor(const Color(0xFF5B5B8C)),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
