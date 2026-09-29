import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/localization/localized_failure_message.dart';
import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import '../../data/repositories/quran_plan_repository_impl.dart';
import '../../domain/quran_plan.dart';
import '../../domain/repositories/quran_plan_repository.dart';
import '../bloc/quran_plan/quran_plan_bloc.dart';
import '../quran_route_args.dart';
import '../quran_text.dart';
import 'create_quran_plan_screen.dart';
import 'quran_plan_ayahs_screen.dart';

class QuranPlanDetailsScreen extends StatefulWidget {
  const QuranPlanDetailsScreen({
    super.key,
    required this.planId,
    this.initialPlan,
    this.repository,
    this.bloc,
  });

  final String planId;
  final QuranPlan? initialPlan;
  final QuranPlanRepository? repository;
  final QuranPlanBloc? bloc;

  @override
  State<QuranPlanDetailsScreen> createState() => _QuranPlanDetailsScreenState();
}

class _QuranPlanDetailsScreenState extends State<QuranPlanDetailsScreen> {
  late final QuranPlanBloc _bloc =
      widget.bloc ??
      QuranPlanBloc(
        repository: widget.repository ?? QuranPlanRepositoryImpl.shared,
      );

  @override
  void initState() {
    super.initState();
    _bloc.add(LoadQuranPlanDetails(planId: widget.planId, forceRefresh: true));
  }

  @override
  void dispose() {
    if (widget.bloc == null) {
      _bloc.close();
    }
    super.dispose();
  }

  Future<void> _openEditPlan(QuranPlan plan) async {
    final updated = await Navigator.of(context).push<QuranPlan>(
      MaterialPageRoute(
        builder: (_) => CreateQuranPlanScreen(
          repository: widget.repository,
          initialPlan: plan,
        ),
      ),
    );
    if (updated != null && mounted) {
      _bloc.add(
        LoadQuranPlanDetails(planId: widget.planId, forceRefresh: true),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(QuranText.read(context).planUpdatedSuccessfully),
          backgroundColor: const Color(0xFF6B8042),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmDelete(QuranPlan plan) async {
    final t = QuranText.read(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: dialogCtx.surfaceColor(Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Text(
            t.deletePlanConfirmTitle,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF282442),
            ),
          ),
          content: Text(
            t.deletePlanConfirmMessage,
            style: TextStyle(
              fontSize: 13.sp,
              color: dialogCtx.inkColor(const Color(0xFF5D6B44)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC15B4B),
              ),
              child: Text(t.delete),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      _bloc.add(DeleteQuranPlan(planId: plan.id));
    }
  }

  void _continueReading(QuranPlanNextAyah nextAyah) {
    Navigator.of(context)
        .pushNamed(
          RouteNames.quranSurahDetail,
          arguments: SurahRouteArgs(
            surahNo: nextAyah.surahNumber,
            surahName: nextAyah.surahNameEnglish,
            ayahNo: nextAyah.ayahNumber,
            paraNumber: nextAyah.paraNumber,
          ),
        )
        .then((_) {
          if (mounted) {
            _bloc.add(
              LoadQuranPlanDetails(planId: widget.planId, forceRefresh: true),
            );
          }
        });
  }

  void _openPlanAyahs(QuranPlan plan) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => QuranPlanAyahsScreen(
              planId: plan.id,
              planName: plan.name,
              repository: widget.repository,
            ),
          ),
        )
        .then((_) {
          if (mounted) {
            _bloc.add(
              LoadQuranPlanDetails(planId: widget.planId, forceRefresh: true),
            );
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    const oliveColor = Color(0xFF9EAA52);
    const borderColor = Color(0xFFD2E3A8);
    const titleColor = Color(0xFF7A8D49);
    final t = QuranText.of(context);

    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<QuranPlanBloc, QuranPlanState>(
        listener: (context, state) {
          if (state.deleteSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(t.planDeletedSuccessfully),
                backgroundColor: const Color(0xFF6B8042),
                duration: const Duration(seconds: 2),
              ),
            );
            Navigator.of(context).pop();
            return;
          }
          if (state.deleteFailure != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  localizeFailureMessage(state.deleteFailure!.message),
                ),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
          if (state.completedSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(t.planCompletedSuccessfully),
                backgroundColor: const Color(0xFF6B8042),
                duration: const Duration(seconds: 2),
              ),
            );
          }
          if (state.completeFailure != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  localizeFailureMessage(state.completeFailure!.message),
                ),
                backgroundColor: Colors.red.shade700,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        builder: (context, state) {
          final plan = state.selectedPlanDetails ?? widget.initialPlan;

          return Scaffold(
            backgroundColor: context.pageColor(Colors.white),
            body: SafeArea(
              child: Column(
                children: [
                  // App Bar Header
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(20.r),
                          child: Container(
                            width: 40.r,
                            height: 40.r,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDEE99D),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.chevron_left_rounded,
                              color: const Color(0xFF5D7133),
                              size: 26.sp,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              t.quranPlanDetails,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: titleColor,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        if (plan != null)
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: Color(0xFF7A8D49),
                            ),
                            onSelected: (action) {
                              if (action == 'edit') {
                                _openEditPlan(plan);
                              } else if (action == 'delete') {
                                _confirmDelete(plan);
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.edit_note_rounded,
                                      color: Color(0xFF6B8042),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(t.editPlan),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Color(0xFFC15B4B),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      t.deletePlan,
                                      style: const TextStyle(
                                        color: Color(0xFFC15B4B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else
                          SizedBox(width: 40.r),
                      ],
                    ),
                  ),

                  // Body Content
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (state.isLoadingDetails && plan == null) {
                          return const Center(
                            child: CircularProgressIndicator(color: oliveColor),
                          );
                        }

                        if (state.detailsFailure != null && plan == null) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  localizeFailureMessage(
                                    state.detailsFailure!.message,
                                  ),
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                ElevatedButton(
                                  onPressed: () => _bloc.add(
                                    LoadQuranPlanDetails(
                                      planId: widget.planId,
                                      forceRefresh: true,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: oliveColor,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(t.read),
                                ),
                              ],
                            ),
                          );
                        }

                        if (plan == null) {
                          return Center(
                            child: Text(
                              t.planNotFound,
                              style: TextStyle(fontSize: 14.sp),
                            ),
                          );
                        }

                        return RefreshIndicator(
                          color: oliveColor,
                          onRefresh: () async {
                            _bloc.add(
                              LoadQuranPlanDetails(
                                planId: widget.planId,
                                forceRefresh: true,
                              ),
                            );
                          },
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeroCard(plan, t, borderColor),
                                SizedBox(height: 14.h),
                                _buildProgressCard(plan, t, borderColor),
                                if (plan.nextAyah != null &&
                                    !plan.isCompleted) ...[
                                  SizedBox(height: 14.h),
                                  _buildNextAyahCard(
                                    plan.nextAyah!,
                                    t,
                                    borderColor,
                                    oliveColor,
                                  ),
                                ],
                                if (plan.surahs.isNotEmpty) ...[
                                  SizedBox(height: 16.h),
                                  _buildSurahsSection(
                                    plan.surahs,
                                    t,
                                    borderColor,
                                  ),
                                ],
                                if (plan.paras.isNotEmpty) ...[
                                  SizedBox(height: 16.h),
                                  _buildParasSection(
                                    plan.paras,
                                    t,
                                    borderColor,
                                  ),
                                ],
                                SizedBox(height: 20.h),
                                _buildActionsSection(
                                  plan,
                                  state,
                                  t,
                                  oliveColor,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroCard(QuranPlan plan, QuranText t, Color borderColor) {
    final schedule = plan.schedule;

    final (statusText, statusBg, statusFg, statusIcon) = () {
      if (plan.isCompleted) {
        return (
          t.completed,
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
          Icons.check_circle_rounded,
        );
      }
      if (schedule.isOverdue) {
        return (
          t.overdue,
          const Color(0xFFFFEBEE),
          const Color(0xFFC62828),
          Icons.warning_amber_rounded,
        );
      }
      if (schedule.aheadBy > 0) {
        return (
          '+${t.n(schedule.aheadBy)} ${t.aheadOfSchedule}',
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
          Icons.trending_up_rounded,
        );
      }
      if (schedule.aheadBy < 0 || !schedule.isOnTrack) {
        return (
          t.behindSchedule,
          const Color(0xFFFFF3E0),
          const Color(0xFFE65100),
          Icons.trending_down_rounded,
        );
      }
      return (
        t.onTrack,
        const Color(0xFFE5EED0),
        const Color(0xFF52692D),
        Icons.check_circle_outline_rounded,
      );
    }();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.pageColor(Colors.white),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54.r,
                height: 54.r,
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDEBBE),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Image.asset(
                  'assets/images/Quran.png',
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.presetPlanName(plan.id, plan.name),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF282442),
                      ),
                    ),
                    if (plan.description != null &&
                        plan.description!.isNotEmpty) ...[
                      SizedBox(height: 3.h),
                      Text(
                        plan.description!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF7A8D49),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 13.sp, color: statusFg),
                    SizedBox(width: 4.w),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: statusFg,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 6.h,
            children: [
              _InfoTag(
                icon: Icons.calendar_today_rounded,
                label: '${t.startDate}: ${plan.startDate}',
              ),
              if (schedule.endDate.isNotEmpty)
                _InfoTag(
                  icon: Icons.event_available_rounded,
                  label: '${t.endDate}: ${schedule.endDate}',
                ),
              _InfoTag(
                icon: Icons.flag_rounded,
                label: '${t.targetDays}: ${t.n(plan.targetDays)}',
              ),
              _InfoTag(
                icon: Icons.timelapse_rounded,
                label: '${t.daysLeft}: ${t.n(schedule.daysLeft)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(QuranPlan plan, QuranText t, Color borderColor) {
    final counts = plan.counts;
    final schedule = plan.schedule;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.pageColor(Colors.white),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.overallProgress,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF282442),
                ),
              ),
              Text(
                '${t.n(counts.percentage)}%',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5D7133),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: counts.percentage.clamp(0, 100) / 100.0,
              minHeight: 7.h,
              backgroundColor: const Color(0xFFE9EED9),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF9EAA52),
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9F0),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: const Color(0xFFE4ECD2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MetricItem(
                    label: t.ayahsCompleted,
                    value: t.n(counts.completedAyahs),
                  ),
                ),
                _vDivider(),
                Expanded(
                  child: _MetricItem(
                    label: t.ayahsRemaining,
                    value: t.n(counts.remainingAyahs),
                  ),
                ),
                _vDivider(),
                Expanded(
                  child: _MetricItem(
                    label: t.dailyTarget,
                    value: t.n(schedule.ayahsPerDay),
                  ),
                ),
                _vDivider(),
                Expanded(
                  child: _MetricItem(
                    label: t.todayRemaining,
                    value: t.n(schedule.todayRemainingAyahs),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 28.h, color: const Color(0xFFD4E5A8));

  Widget _buildNextAyahCard(
    QuranPlanNextAyah nextAyah,
    QuranText t,
    Color borderColor,
    Color oliveColor,
  ) {
    final surahDisplay = t.isBangla && nextAyah.surahNameBangla.isNotEmpty
        ? nextAyah.surahNameBangla
        : nextAyah.surahNameEnglish;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7E7),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDEBBE),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: const Color(0xFF5D7133),
                      size: 16.sp,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    t.nextAyah,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF282442),
                    ),
                  ),
                ],
              ),
              if (nextAyah.surahNameArabic.isNotEmpty)
                Text(
                  nextAyah.surahNameArabic,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontFamily: 'Amiri',
                    color: const Color(0xFF5D7133),
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surahDisplay,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF282442),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${t.ayah} ${t.n(nextAyah.ayahNumber)} (${nextAyah.ayahKey}) · ${t.para} ${t.n(nextAyah.paraNumber)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF7A8D49),
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: () => _continueReading(nextAyah),
                style: FilledButton.styleFrom(
                  backgroundColor: oliveColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
                icon: Icon(Icons.menu_book_rounded, size: 16.sp),
                label: Text(
                  t.continueReading,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSurahsSection(
    List<QuranPlanSurah> surahs,
    QuranText t,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${t.selectedSurahs} (${t.n(surahs.length)})',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF282442),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: surahs.length,
          separatorBuilder: (_, _) => SizedBox(height: 8.h),
          itemBuilder: (context, index) {
            final s = surahs[index];
            final surahName = t.isBangla && s.nameBangla.isNotEmpty
                ? s.nameBangla
                : s.nameEnglish;

            return Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: context.pageColor(Colors.white),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28.r,
                            height: 28.r,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEFF5DD),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              t.n(s.surahNumber),
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF5D7133),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            surahName,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF282442),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (s.nameArabic.isNotEmpty) ...[
                            Text(
                              s.nameArabic,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontFamily: 'Amiri',
                                color: const Color(0xFF5D7133),
                              ),
                            ),
                            SizedBox(width: 8.w),
                          ],
                          if (s.isCompleted)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF4CAF50),
                              size: 18,
                            ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${t.n(s.readAyahs)} / ${t.n(s.totalAyahs)} ${t.ayah} (${t.n(s.percentage)}%)',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: const Color(0xFF6B8042),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${t.n(s.remainingAyahs)} ${t.ayahsRemaining}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: s.percentage.clamp(0, 100) / 100.0,
                      minHeight: 5.h,
                      backgroundColor: const Color(0xFFE9EED9),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF9EAA52),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildParasSection(
    List<QuranPlanPara> paras,
    QuranText t,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${t.selectedParas} (${t.n(paras.length)})',
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF282442),
          ),
        ),
        SizedBox(height: 10.h),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: paras.length,
          separatorBuilder: (_, _) => SizedBox(height: 8.h),
          itemBuilder: (context, index) {
            final p = paras[index];
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: context.pageColor(Colors.white),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${t.para} ${t.n(p.paraNumber)} ${p.nameBangla.isNotEmpty ? "(${p.nameBangla})" : ""}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF282442),
                        ),
                      ),
                      if (p.isCompleted)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF4CAF50),
                          size: 18,
                        ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${t.n(p.readAyahs)} / ${t.n(p.totalAyahs)} (${t.n(p.percentage)}%)',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: const Color(0xFF6B8042),
                        ),
                      ),
                      Text(
                        '${t.n(p.remainingAyahs)} ${t.ayahsRemaining}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: p.percentage.clamp(0, 100) / 100.0,
                      minHeight: 5.h,
                      backgroundColor: const Color(0xFFE9EED9),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF9EAA52),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionsSection(
    QuranPlan plan,
    QuranPlanState state,
    QuranText t,
    Color oliveColor,
  ) {
    return Column(
      children: [
        // View All Ayahs button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openPlanAyahs(plan),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF5D7133),
              side: const BorderSide(color: Color(0xFF9EAA52), width: 1.5),
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.r),
              ),
            ),
            icon: Icon(Icons.list_alt_rounded, size: 20.sp),
            label: Text(
              t.viewAllAyahs,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ),

        // Complete Plan button (only if not already completed)
        if (!plan.isCompleted && plan.status != 'completed') ...[
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: state.isCompleting
                  ? null
                  : () {
                      _bloc.add(CompleteQuranPlan(planId: plan.id));
                    },
              style: FilledButton.styleFrom(
                backgroundColor: oliveColor,
                padding: EdgeInsets.symmetric(vertical: 13.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.r),
                ),
              ),
              icon: state.isCompleting
                  ? SizedBox(
                      width: 18.r,
                      height: 18.r,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.check_circle_rounded, size: 20.sp),
              label: Text(
                t.completePlanAction,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.sp, color: const Color(0xFF8B9875)),
        SizedBox(width: 4.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: const Color(0xFF556040),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF282442),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.sp,
            color: const Color(0xFF8B9875),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
