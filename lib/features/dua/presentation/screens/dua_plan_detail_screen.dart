import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/dua/dua_dependencies.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/bloc/dua_plan_detail_cubit.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/dua_plan_slot.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/dua_route_args.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_plan_status_badge.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_status_view.dart';

/// One plan's duas (design `devImg/img_7.png`'s "My Plan" entry, opened for
/// reading), reached by tapping a plan card on [DuaPlannerScreen].
///
/// Loads `GET /duas/planner/plans/{id}` (which embeds each dua's full
/// content), shows the plan's status, then opens the usual
/// [DuaReaderScreen] on tap.
class DuaPlanDetailScreen extends StatelessWidget {
  const DuaPlanDetailScreen({
    super.key,
    required this.planId,
    this.initialName = '',
  });

  final String planId;
  final String initialName;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => DuaPlanDetailCubit(duaRepository, planId: planId)..load(),
    child: _DuaPlanDetailView(initialName: initialName),
  );
}

class _DuaPlanDetailView extends StatelessWidget {
  const _DuaPlanDetailView({required this.initialName});
  final String initialName;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 6.h),
            BlocBuilder<DuaPlanDetailCubit, DuaPlanDetailState>(
              buildWhen: (previous, current) =>
                  previous.planName != current.planName ||
                  previous.planStatus != current.planStatus ||
                  previous.status != current.status,
              builder: (context, state) => _Header(
                title: state.planName.isEmpty ? initialName : state.planName,
                status: state.status == DuaPlanDetailStatus.success
                    ? state.planStatus
                    : null,
              ),
            ),
            Expanded(
              child: BlocBuilder<DuaPlanDetailCubit, DuaPlanDetailState>(
                builder: (context, state) {
                  if (state.status == DuaPlanDetailStatus.initial ||
                      state.status == DuaPlanDetailStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.status == DuaPlanDetailStatus.failure) {
                    return DuaErrorRetry(
                      message: state.error ?? '',
                      onRetry: () => context.read<DuaPlanDetailCubit>().load(),
                    );
                  }
                  if (state.entries.isEmpty) {
                    return Center(
                      child: Text(
                        appText.noResultsFound,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: context.inkColor(const Color(0xFF5D6B44)),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
                    itemCount: state.entries.length,
                    separatorBuilder: (_, _) => SizedBox(height: 10.h),
                    itemBuilder: (context, index) =>
                        _DuaEntryTile(entry: state.entries[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DuaEntryTile extends StatelessWidget {
  const _DuaEntryTile({required this.entry});
  final DuaPlanDetailEntry entry;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final item = entry.item;
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(
        RouteNames.duaReader,
        arguments: DuaReaderArgs.real(entry.dua),
      ),
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          border: Border.all(color: context.lineColor(const Color(0xFFD5E59B))),
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 21.r,
              backgroundColor: const Color(0xFFA5B657),
              child: const Icon(
                Icons.menu_book_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.localized(entry.dua.title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    '${context.localizedDigits('${item.count}/${item.targetCount}')} '
                    '· ${duaSlotLabel(appText, item.slot)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFFA5B657),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20.sp,
              color: context.inkColor(const Color(0xFFA5B657)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, this.status});
  final String title;

  /// `in_progress` / `completed` / `abandoned` — shown as a pill on the
  /// right once the plan has loaded. Null while still loading.
  final String? status;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44.h,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 12.w),
            child: IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.chevron_left),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFE1E56A),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 56.w),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17.sp,
              color: context.inkColor(const Color(0xFF7D8E54)),
            ),
          ),
        ),
        if (status != null)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: DuaPlanStatusBadge(status: status!),
            ),
          ),
      ],
    ),
  );
}
