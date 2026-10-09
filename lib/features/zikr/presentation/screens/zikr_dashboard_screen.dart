import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/zikr/data/zikr_catalog.dart';
import 'package:tuhfatul_muslim/features/zikr/data/models/zikr_api_models.dart';
import 'package:tuhfatul_muslim/features/zikr/presentation/bloc/zikr_home_cubit.dart';
import 'package:tuhfatul_muslim/features/zikr/presentation/zikr_api_mappers.dart';
import 'package:tuhfatul_muslim/features/zikr/presentation/zikr_login_dialog.dart';
import 'package:tuhfatul_muslim/features/zikr/presentation/widgets/zikr_bottom_nav.dart';
import 'package:tuhfatul_muslim/features/zikr/presentation/widgets/zikr_gradient_header.dart';
import 'package:tuhfatul_muslim/features/zikr/presentation/zikr_localized_name.dart';
import 'package:tuhfatul_muslim/features/zikr/presentation/zikr_route_args.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/zikr/zikr_dependencies.dart';

/// Zikr dashboard — the home of the Zikr flow, reached from "Let's Get Start"
/// on [ZikrIntroScreen].
///
/// Profile, routines, and catalog data are loaded from the Zikr API. Tapping
/// a zikr opens [ZikrCounterScreen]; the `+` button opens the "New Zikr"
/// screen.
class ZikrDashboardScreen extends StatelessWidget {
  const ZikrDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ZikrHomeCubit(zikrRepository)..load(),
      child: const _ZikrDashboardView(),
    );
  }
}

class _ZikrDashboardView extends StatelessWidget {
  const _ZikrDashboardView();

  void _openCounter(BuildContext context, ZikrCounterArgs args) {
    Navigator.of(context).pushNamed(RouteNames.zikrCounter, arguments: args);
  }

  Future<void> _openCreateZikr(BuildContext context) async {
    if (!await requireZikrSignIn(context) || !context.mounted) return;
    Navigator.of(context).pushNamed(RouteNames.zikrCreate);
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: Stack(
        children: [
          BlocBuilder<ZikrHomeCubit, ZikrHomeState>(
            builder: (context, state) {
              if (state.status == ZikrLoadStatus.loading &&
                  state.profile == null) {
                return const Center(child: CircularProgressIndicator());
              }
              final latestItem = _resolveLatestItem(
                state.profile,
                state.catalog,
              );
              final presets = [
                for (final routine in state.routines.where(
                  (routine) => routine.isPreset,
                ))
                  routine.toUiPreset(),
              ];
              final customRoutines = [
                for (final routine in state.routines.where(
                  (routine) => !routine.isPreset,
                ))
                  routine.toUiPreset(),
              ];

              return ListView(
                padding: EdgeInsets.only(bottom: 150.h + bottomInset),
                children: [
                  ZikrGradientHeader(
                    title: appText.zikrTitle,
                    total: state.profile?.lifetimeTotalCount ?? 0,
                    trailing: Column(
                      children: [
                        _LastZikrPill(
                          appText: appText,
                          item: latestItem,
                          done: state.profile?.mostPerformedCount ?? 0,
                          onTap: latestItem == null
                              ? null
                              : () => _openCounter(
                                  context,
                                  ZikrCounterArgs.fromItem(latestItem),
                                ),
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            for (
                              var i = 0;
                              i < presets.length && i < 2;
                              i++
                            ) ...[
                              if (i > 0) SizedBox(width: 12.w),
                              Expanded(
                                child: _PresetPill(
                                  preset: presets[i],
                                  onTap: () => _openCounter(
                                    context,
                                    ZikrCounterArgs.fromPreset(presets[i]),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
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
                  for (final routine in customRoutines)
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                      child: _CreatedZikrCard(
                        title: routine.name,
                        items: routine.items,
                        onOpenItem: (item) => _openCounter(
                          context,
                          ZikrCounterArgs.fromItem(item),
                        ),
                        // Home routines are recitation sequences, not Planner
                        // challenges. Guests go straight to the counter and
                        // this never calls the plan-enrol endpoint.
                        onGetStart: () => _openCounter(
                          context,
                          ZikrCounterArgs.fromPreset(routine),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          Positioned(
            right: 24.w,
            bottom: 74.h + bottomInset,
            child: _AddButton(onTap: () => _openCreateZikr(context)),
          ),
          const SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ZikrBottomNav(selectedIndex: 0),
            ),
          ),
        ],
      ),
    );
  }

  ZikrItem? _resolveLatestItem(
    UserTasbihProfile? profile,
    List<ZikrCatalogItem> catalog,
  ) {
    if (profile == null || profile.mostPerformedZikrName.isEmpty) {
      return null;
    }
    for (final item in catalog) {
      if (item.zikrName == profile.mostPerformedZikrName) {
        return item.toUiItem();
      }
    }
    return ZikrItem(
      name: profile.mostPerformedZikrName,
      arabic: '',
      transliteration: profile.mostPerformedZikrName,
      target: 33,
      zikrKey: profile.mostPerformedZikrKey,
    );
  }
}

class _LastZikrPill extends StatelessWidget {
  const _LastZikrPill({
    required this.appText,
    required this.item,
    required this.done,
    required this.onTap,
  });

  final AppText appText;

  /// The most recently performed zikr, or `null` before the user has
  /// counted anything.
  final ZikrItem? item;
  final int done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final item = this.item;
    final name = item == null
        ? null
        : localizedTrackedZikrName(appText, item.trackingKey) ?? item.name;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30.r),
      child: Container(
        padding: EdgeInsets.fromLTRB(18.w, 8.h, 8.w, 8.h),
        decoration: BoxDecoration(
          border: Border.all(
            color: context.lineColor(Colors.white.withValues(alpha: .55)),
          ),
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
                name ?? '—',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white, fontSize: 15.sp),
              ),
            ),
            if (item != null) ...[
              SizedBox(width: 6.w),
              Text(
                context.localizedDigits('$done/${item.target}'),
                style: TextStyle(
                  color: context.inkColor(Colors.white.withValues(alpha: .9)),
                  fontSize: 12.sp,
                ),
              ),
            ],
            SizedBox(width: 8.w),
            Container(
              width: 30.r,
              height: 30.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.lineColor(Colors.white.withValues(alpha: .7)),
                ),
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

  /// Routine progress is recorded on the server by the counter session.
  /// The list endpoint has no per-routine current count, so this card starts
  /// from zero until that field is supplied by the backend.
  int get _done => 0;

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
              color: context.surfaceColor(Colors.white.withValues(alpha: .18)),
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: context.lineColor(Colors.white.withValues(alpha: .35)),
              ),
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
            color: context.inkColor(Colors.white.withValues(alpha: .85)),
            fontSize: 11.sp,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          context.localizedDigits('$_done/${preset.total}'),
          style: TextStyle(
            color: context.inkColor(Colors.white.withValues(alpha: .7)),
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CreatedZikrCard extends StatelessWidget {
  const _CreatedZikrCard({
    required this.title,
    required this.items,
    required this.onOpenItem,
    required this.onGetStart,
  });

  final String title;
  final List<ZikrItem> items;
  final ValueChanged<ZikrItem> onOpenItem;
  final VoidCallback? onGetStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: context.surfaceColor(Color(0xFFDCE8C4)),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: context.lineColor(Color(0xFFC7D6A6))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: context.inkColor(Color(0xFF3C4A28)),
            ),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              for (final item in items)
                InkWell(
                  onTap: () => onOpenItem(item),
                  borderRadius: BorderRadius.circular(20.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 9.h,
                    ),
                    decoration: BoxDecoration(
                      color: context.surfaceColor(Colors.white),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: context.lineColor(Color(0xFFCBD9AF)),
                      ),
                    ),
                    child: Text(
                      '${item.name} ('
                      '${context.localizedDigits(_doneFor(item))}'
                      '/${context.localizedDigits('${item.target}')})',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.inkColor(Color(0xFF3C4A28)),
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
                AppText.of(context).zikrGetStart,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _doneFor(ZikrItem item) => '0';
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
