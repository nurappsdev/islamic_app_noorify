import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/home/data/home_feature_order_store.dart';
import 'package:tuhfatul_muslim/features/home/presentation/screens/home_screen.dart';
import 'package:tuhfatul_muslim/features/zikr/data/zikr_progress_store.dart';

/// The Home Screen's feature shortcuts (Quran, Hadith, Dua, Quiz, Zikr,
/// Asma-ul-Husna).
///
/// The tiles can be rearranged in place: long-press one, drag it onto the
/// tile whose place it should take, and let go. The order is kept on the
/// device by [HomeFeatureOrderStore], so it is the same after a restart, and
/// a plain tap still opens the feature.
class HomeFeatureGrid extends StatelessWidget {
  const HomeFeatureGrid({
    super.key,
    this.columnMajor = false,
    this.webStyle = false,
    this.reorderable = true,
  });

  /// Web's reference design reads each vertical column top-to-bottom before
  /// moving to the next one. Android/iOS retain their existing row order.
  final bool columnMajor;

  /// Uses the reference Web dashboard's six compact, horizontal shortcuts.
  /// Mobile retains its original two-column, portrait cards.
  final bool webStyle;

  /// Long-press-and-drop reordering. Pass `false` for a fixed grid.
  final bool reorderable;

  static List<_HomeFeature> _features(AppText appText) => [
    _HomeFeature(
      appText.categoryQuran,
      Icons.menu_book_outlined,
      const Color(0xFFA5B58F),
      imagePath: 'assets/homeImg/quranImg.png',
      routeName: RouteNames.quran,
    ),
    _HomeFeature(
      appText.categoryHadith,
      Icons.local_library,
      const Color(0xFF20B20F),
      imagePath: 'assets/homeImg/haditImg.png',
      routeName: RouteNames.hadith,
    ),
    _HomeFeature(
      appText.featureDua,
      Icons.volunteer_activism,
      const Color(0xFFFF7D67),
      imagePath: 'assets/homeImg/duaImg.png',
      routeName: RouteNames.dua,
    ),
    _HomeFeature(
      appText.featureQuizAndLearn,
      Icons.quiz_outlined,
      const Color(0xFFFF9D13),
      imagePath: 'assets/homeImg/quizImg.png',
      routeName: RouteNames.winQuiz,
    ),
    _HomeFeature(
      appText.featureDijpr,
      Icons.nightlight_round,
      const Color(0xFFFFD21E),
      imagePath: 'assets/homeImg/zikrImg.png',
      routeName: RouteNames.zikr,
    ),

    _HomeFeature(
      appText.featureAsmaUlHusna,
      Icons.workspace_premium,
      const Color(0xFF37C915),
      imagePath: 'assets/homeImg/asmaImg.png',
      routeName: RouteNames.asma,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final baseFeatures = _features(appText);
    final defaultIds = [for (final feature in baseFeatures) feature.id];

    return ValueListenableBuilder<List<String>>(
      valueListenable: HomeFeatureOrderStore.instance,
      builder: (context, _, _) {
        final byId = {for (final feature in baseFeatures) feature.id: feature};
        final userOrder = [
          for (final id in HomeFeatureOrderStore.instance.ordered(defaultIds))
            byId[id]!,
        ];
        // GridView fills left-to-right by rows, so Web's column-first
        // reference reading order needs the two columns interleaved.
        final features = columnMajor ? _asColumnMajor(userOrder) : userOrder;

        return LayoutBuilder(
          builder: (context, constraints) {
            final webColumns = constraints.maxWidth >= 880 ? 3 : 2;
            final columns = webStyle ? webColumns : 2;
            final spacing = webStyle ? 18.0 : 11.w;
            final tileHeight = webStyle ? 128.0 : 128.h;
            // The dragged card is painted in the overlay, where the grid's
            // constraints no longer apply, so its size is measured here.
            final tileWidth = constraints.maxWidth.isFinite
                ? (constraints.maxWidth - spacing * (columns - 1)) / columns
                : 160.0;

            return Column(
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: features.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisExtent: tileHeight,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: webStyle ? 18 : 12.h,
                  ),
                  itemBuilder: (context, index) {
                    final feature = features[index];
                    final tile = webStyle
                        ? _WebFeatureTile(feature: feature)
                        : _FeatureTile(feature: feature);
                    if (!reorderable) return tile;
                    return _ReorderableFeatureTile(
                      feature: feature,
                      defaultIds: defaultIds,
                      size: Size(tileWidth, tileHeight),
                      radius: webStyle ? 18 : 11.r,
                      child: tile,
                    );
                  },
                ),
                SizedBox(height: webStyle ? 0 : 12.h),
                // _LinkTile(
                //   title: appText.zakatCalculator,
                //   icon: Icons.price_check,
                //   iconColor: context.inkColor(Color(0xFF0DA334)),
                //   onTap: () => _openComingSoon(context, appText.zakatCalculator),
                // ),
                // SizedBox(height: 6.h),
                // _LinkTile(
                //   title: appText.ageCalculate,
                //   icon: Icons.calculate,
                //   iconColor: const Color(0xFFAAB781),
                //   onTap: () => _openComingSoon(context, appText.ageCalculate),
                // ),
              ],
            );
          },
        );
      },
    );
  }

  /// Reads the list down the first column and then down the second, so a
  /// row-filling GridView still shows it column-first.
  static List<_HomeFeature> _asColumnMajor(List<_HomeFeature> features) {
    final rows = (features.length / 2).ceil();
    return [
      for (var row = 0; row < rows; row++)
        for (final index in [row, row + rows])
          if (index < features.length) features[index],
    ];
  }
}

/// One grid tile that can be picked up and dropped onto another one.
///
/// A long press lifts the card; dropping it on a tile puts it in that tile's
/// place and pushes the others along. The order is written to
/// [HomeFeatureOrderStore] the instant the finger lifts, and a short tap is
/// untouched, so navigation still works exactly as before.
class _ReorderableFeatureTile extends StatelessWidget {
  const _ReorderableFeatureTile({
    required this.feature,
    required this.defaultIds,
    required this.size,
    required this.radius,
    required this.child,
  });

  final _HomeFeature feature;
  final List<String> defaultIds;
  final Size size;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The lifted card lives in the app's overlay, outside this subtree, so
    // the inherited values it reads (dark-mode colors, text direction) are
    // captured here and handed to it.
    final theme = Theme.of(context);
    final textDirection = Directionality.of(context);

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data != feature.id,
      onAcceptWithDetails: (details) {
        HomeFeatureOrderStore.instance.moveTo(
          id: details.data,
          targetId: feature.id,
          defaultIds: defaultIds,
        );
        HapticFeedback.mediumImpact();
      },
      builder: (context, candidates, _) {
        final isDropTarget = candidates.isNotEmpty;
        return LongPressDraggable<String>(
          data: feature.id,
          delay: const Duration(milliseconds: 220),
          onDragStarted: HapticFeedback.selectionClick,
          feedback: Directionality(
            textDirection: textDirection,
            child: Theme(
              data: theme,
              child: Material(
                color: Colors.transparent,
                child: Opacity(
                  opacity: .94,
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: Transform.scale(scale: 1.06, child: child),
                  ),
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: .3,
            child: IgnorePointer(child: child),
          ),
          // The highlight is painted over the card instead of around it: a
          // border would shrink the fixed-height tile and overflow it.
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              child,
              if (isDropTarget)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius),
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                        color: theme.colorScheme.primary.withValues(alpha: .06),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeFeature {
  const _HomeFeature(
    this.title,
    this.icon,
    this.color, {
    this.imagePath,
    this.routeName,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String? imagePath;
  final String? routeName;

  /// Stable key for the saved order: the route never changes with the
  /// app language, unlike [title].
  String get id => routeName ?? title;
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.feature});

  final _HomeFeature feature;

  @override
  Widget build(BuildContext context) {
    final navigate = feature.routeName == null
        ? null
        : () => Navigator.of(context).pushNamed(feature.routeName!);
    final isZikr = feature.routeName == RouteNames.zikr;

    return InkWell(
      onTap: navigate,
      borderRadius: BorderRadius.circular(11.r),
      child: HomeCard(
        // Ubuntu's glyph metrics are slightly taller than the previous default
        // font. Keeping one extra logical pixel of vertical room prevents the
        // fixed-height grid tile from overflowing on compact devices.
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isZikr
                ? _ZikrIconWithBadge(
                    icon: feature.icon,
                    color: feature.color,
                    imagePath: feature.imagePath,
                  )
                : _FeatureImage(
                    imagePath: feature.imagePath,
                    fallbackIcon: feature.icon,
                    color: feature.color,
                  ),
            SizedBox(height: 9.h),
            Text(
              feature.title,
              style: homeSerifStyle(
                context: context,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 10.h),
            HomeCircleButton(icon: Icons.chevron_right, onPressed: navigate),
          ],
        ),
      ),
    );
  }
}

/// The wide-screen shortcut cards echo the reference composition: artwork on
/// the left, a clear destination label, and a single directional affordance.
/// This is intentionally separate from [_FeatureTile] so phone dimensions and
/// typography are never affected by a Web-only polish pass.
class _WebFeatureTile extends StatelessWidget {
  const _WebFeatureTile({required this.feature});

  final _HomeFeature feature;

  @override
  Widget build(BuildContext context) {
    final navigate = feature.routeName == null
        ? null
        : () => Navigator.of(context).pushNamed(feature.routeName!);
    final isZikr = feature.routeName == RouteNames.zikr;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: navigate,
        borderRadius: BorderRadius.circular(18),
        child: HomeCard(
          radius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          borderColor: context.lineColor(const Color(0xFFD7E7B7)),
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          child: Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Center(
                  child: isZikr
                      ? _ZikrIconWithBadge(
                          icon: feature.icon,
                          color: feature.color,
                          imagePath: feature.imagePath,
                        )
                      : _FeatureImage(
                          imagePath: feature.imagePath,
                          fallbackIcon: feature.icon,
                          color: feature.color,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  feature.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: homeSerifStyle(
                    context: context,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              HomeCircleButton(icon: Icons.chevron_right, onPressed: navigate),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureImage extends StatelessWidget {
  const _FeatureImage({
    required this.imagePath,
    required this.fallbackIcon,
    required this.color,
  });

  final String? imagePath;
  final IconData fallbackIcon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      fallbackIcon,
      color: context.inkColor(color),
      size: 28.sp,
    );
    if (imagePath == null) return fallback;

    return SizedBox(
      width: 36.w,
      height: 36.h,
      child: Image.asset(
        imagePath!,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

/// The grid's Zikr icon with a live badge of the Home Screen Zikr section's
/// total count (Prayer Zikr 1 & 2, from Hive). Reacts immediately to a new
/// count or a reset, with no restart or manual refresh.
class _ZikrIconWithBadge extends StatelessWidget {
  const _ZikrIconWithBadge({
    required this.icon,
    required this.color,
    this.imagePath,
  });

  final IconData icon;
  final Color color;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, int>>(
      valueListenable: ZikrProgressStore.instance,
      builder: (context, _, _) {
        final total = ZikrProgressStore.instance.totalCount;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _FeatureImage(
              imagePath: imagePath,
              fallbackIcon: icon,
              color: color,
            ),
            if (total > 0)
              Positioned(
                right: -8.w,
                top: -4.h,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6E8B3D),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    context.localizedDigits('$total'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
