import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/localization/localized_failure_message.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import '../../data/repositories/quran_plan_repository_impl.dart';
import '../../data/services/quran_plan_store.dart';
import '../../domain/quran_plan.dart';
import '../../domain/repositories/quran_plan_repository.dart';
import '../bloc/quran_plan/quran_plan_bloc.dart';
import '../quran_route_args.dart';
import '../quran_text.dart';
import 'create_quran_plan_screen.dart';
import 'quran_plan_details_screen.dart';
import '../widgets/dashboard/quran_dashboard_header.dart';
import '../widgets/quran_segmented_tabs.dart';

class QuranPlanScreen extends StatefulWidget {
  const QuranPlanScreen({super.key, this.onBack, this.repository, this.bloc});

  final VoidCallback? onBack;
  final QuranPlanRepository? repository;
  final QuranPlanBloc? bloc;

  @override
  State<QuranPlanScreen> createState() => _QuranPlanScreenState();
}

class _QuranPlanScreenState extends State<QuranPlanScreen> {
  late final QuranPlanBloc _bloc =
      widget.bloc ??
      QuranPlanBloc(
        repository: widget.repository ?? QuranPlanRepositoryImpl.shared,
      );

  final _activeScroll = ScrollController();
  final _completedScroll = ScrollController();

  int _tab = 0; // 0 = My Plan, 1 = Search Plan, 2 = Complete Plan
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _bloc.add(const LoadQuranPlans());
    _activeScroll.addListener(_onActiveScroll);
    _completedScroll.addListener(_onCompletedScroll);
  }

  void _onActiveScroll() {
    if (_activeScroll.position.extentAfter < 200) {
      _bloc.add(const LoadMoreQuranPlans(status: 'in_progress'));
    }
  }

  void _onCompletedScroll() {
    if (_completedScroll.position.extentAfter < 200) {
      _bloc.add(const LoadMoreQuranPlans(status: 'completed'));
    }
  }

  @override
  void dispose() {
    _activeScroll.dispose();
    _completedScroll.dispose();
    if (widget.bloc == null) {
      _bloc.close();
    }
    super.dispose();
  }

  Future<void> _openCreatePlan() async {
    final result = await Navigator.of(context).push<QuranPlan>(
      MaterialPageRoute(
        builder: (_) => CreateQuranPlanScreen(repository: widget.repository),
      ),
    );
    if (result != null && mounted) {
      setState(() => _tab = 0);
      _bloc.add(
        const LoadQuranPlans(status: 'in_progress', forceRefresh: true),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(QuranText.read(context).planCreatedSuccessfully),
          backgroundColor: const Color(0xFF6B8042),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _enrollPreset(QuranPlan preset) async {
    final t = QuranText.read(context);
    final repo = widget.repository ?? QuranPlanRepositoryImpl.shared;
    final result = await repo.createPlan(
      CreateQuranPlanRequest(
        name: preset.name,
        targetDays: preset.targetDays,
        wholeQuran: true,
      ),
    );
    if (!mounted) return;
    result.fold(
      (failure) {
        final message = (failure.statusCode == 409)
            ? t.quranPlanDuplicateName
            : localizeFailureMessage(failure.message);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade700,
          ),
        );
      },
      (created) {
        setState(() => _tab = 0);
        _bloc.add(
          const LoadQuranPlans(status: 'in_progress', forceRefresh: true),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t.planStarted(t.presetPlanName(preset.id, created.name)),
            ),
            backgroundColor: const Color(0xFF6B8042),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  void _openPlanDetails(QuranPlan plan) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => QuranPlanDetailsScreen(
              planId: plan.id,
              initialPlan: plan,
              repository: widget.repository,
            ),
          ),
        )
        .then((_) {
          if (mounted) {
            _bloc.add(const LoadQuranPlans(forceRefresh: true));
          }
        });
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
      _bloc.add(const LoadQuranPlans(forceRefresh: true));
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
      builder: (dialogCtx) => AlertDialog(
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
      ),
    );
    if (confirmed == true && mounted) {
      _bloc.add(DeleteQuranPlan(planId: plan.id));
    }
  }

  void _markCompleted(QuranPlan plan) {
    _bloc.add(CompleteQuranPlan(planId: plan.id));
  }

  void _markInProgress(QuranPlan plan) {
    _bloc.add(UpdateQuranPlanStatus(planId: plan.id, status: 'in_progress'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(QuranText.read(context).planUpdatedSuccessfully),
        backgroundColor: const Color(0xFF6B8042),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openPlanReading(QuranPlan plan) {
    Navigator.of(context).pushNamed(
      RouteNames.quranSurahDetail,
      arguments: SurahRouteArgs(
        surahNo: plan.startSurah,
        surahName: plan.startSurahName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = QuranText.of(context);
    const borderColor = Color(0xFFD2E3A8);

    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<QuranPlanBloc, QuranPlanState>(
        listenWhen: (previous, current) =>
            (!previous.deleteSuccess && current.deleteSuccess) ||
            (!previous.completedSuccess && current.completedSuccess) ||
            (previous.deleteFailure != current.deleteFailure &&
                current.deleteFailure != null) ||
            (previous.completeFailure != current.completeFailure &&
                current.completeFailure != null),
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state.completedSuccess) {
            messenger.hideCurrentSnackBar();
            messenger.showSnackBar(
              SnackBar(
                content: Text(t.planCompletedSuccessfully),
                backgroundColor: const Color(0xFF6B8042),
                duration: const Duration(seconds: 2),
              ),
            );
          }
          if (state.completeFailure != null) {
            messenger.hideCurrentSnackBar();
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  localizeFailureMessage(state.completeFailure!.message),
                ),
                backgroundColor: Colors.red.shade700,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          if (state.deleteSuccess) {
            messenger.hideCurrentSnackBar();
            messenger.showSnackBar(
              SnackBar(
                content: Text(t.planDeletedSuccessfully),
                backgroundColor: const Color(0xFF6B8042),
                duration: const Duration(seconds: 2),
              ),
            );
          }
          if (state.deleteFailure != null) {
            messenger.hideCurrentSnackBar();
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  localizeFailureMessage(state.deleteFailure!.message),
                ),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: context.pageColor(Colors.white),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                      child: QuranDashboardHeader(
                        title: AppText.of(context).planner,
                        onBack: widget.onBack,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
                      child: QuranSegmentedTabs(
                        selected: _tab,
                        labels: [t.myPlan, t.searchPlan, t.completePlan],
                        onSelected: (index) => setState(() => _tab = index),
                      ),
                    ),

                    // Search Bar when in Search Plan tab
                    if (_tab == 1) ...[
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 4.h),
                        child: TextField(
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: t.searchPlanHint,
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF7A8D49),
                            ),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 10.h,
                            ),
                            filled: true,
                            fillColor: context.surfaceColor(
                              const Color(0xFFF6F8EF),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24.r),
                              borderSide: const BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24.r),
                              borderSide: const BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24.r),
                              borderSide: const BorderSide(
                                color: Color(0xFF9EAA52),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Tab Content Body
                    Expanded(
                      child: BlocBuilder<QuranPlanBloc, QuranPlanState>(
                        builder: (context, state) {
                          return switch (_tab) {
                            0 => _buildMyPlanTab(state, t),
                            1 => _buildSearchPlanTab(t),
                            2 => _buildCompletePlanTab(state, t),
                            _ => const SizedBox.shrink(),
                          };
                        },
                      ),
                    ),
                  ],
                ),

                // Floating "Create Plan" button on "My Plan" and "Search Plan" tabs
                if (_tab != 2)
                  Positioned(
                    right: 20.w,
                    bottom: 24.h,
                    child: FilledButton.icon(
                      onPressed: _openCreatePlan,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF9EAA52),
                        foregroundColor: Colors.white,
                        elevation: 3,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 13.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28.r),
                        ),
                      ),
                      icon: Icon(Icons.edit_note_rounded, size: 20.sp),
                      label: Text(
                        t.createPlan,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyPlanTab(QuranPlanState state, QuranText t) {
    if (state.isLoadingActive) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF9EAA52)),
      );
    }

    if (state.activeStatus == QuranPlanLoadStatus.failure &&
        state.activePlans.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.activeFailure != null
                  ? localizeFailureMessage(state.activeFailure!.message)
                  : t.failedToLoadPlans,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700),
            ),
            SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: () => _bloc.add(
                const LoadQuranPlans(status: 'in_progress', forceRefresh: true),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9EAA52),
                foregroundColor: Colors.white,
              ),
              child: Text(t.read),
            ),
          ],
        ),
      );
    }

    if (state.activePlans.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFF9EAA52),
        onRefresh: () async {
          _bloc.add(
            const LoadQuranPlans(status: 'in_progress', forceRefresh: true),
          );
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 100.h),
            Center(child: _PlanEmptyIllustration(message: t.noActivePlans)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF9EAA52),
      onRefresh: () async {
        _bloc.add(
          const LoadQuranPlans(status: 'in_progress', forceRefresh: true),
        );
      },
      child: ListView.separated(
        controller: _activeScroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 90.h),
        itemCount:
            state.activePlans.length + (state.isLoadingMoreActive ? 1 : 0),
        separatorBuilder: (_, _) => SizedBox(height: 14.h),
        itemBuilder: (context, index) {
          if (index == state.activePlans.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF9EAA52),
                ),
              ),
            );
          }
          final plan = state.activePlans[index];
          return _ActiveQuranPlanCard(
            plan: plan,
            t: t,
            onOpenDetails: () => _openPlanDetails(plan),
            onRead: () => _openPlanReading(plan),
            onMarkCompleted: () => _markCompleted(plan),
            onEdit: () => _openEditPlan(plan),
            onDelete: () => _confirmDelete(plan),
          );
        },
      ),
    );
  }

  Widget _buildSearchPlanTab(QuranText t) {
    final query = _searchQuery.trim().toLowerCase();
    final presets = QuranPlanStore.presetSearchPlans.where((p) {
      if (query.isEmpty) return true;
      return p.name.toLowerCase().contains(query) ||
          t.presetPlanName(p.id, p.name).toLowerCase().contains(query) ||
          p.days.toString().contains(query) ||
          t.n(p.days).contains(query);
    }).toList();

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 90.h),
      itemCount: presets.length,
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final plan = presets[index];
        return _QuranPresetCard(
          plan: plan,
          name: t.presetPlanName(plan.id, plan.name),
          daysLabel: t.days(plan.days),
          buttonText: t.getStarted,
          onAction: () => _enrollPreset(plan),
        );
      },
    );
  }

  Widget _buildCompletePlanTab(QuranPlanState state, QuranText t) {
    if (state.isLoadingCompleted) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF9EAA52)),
      );
    }

    if (state.completedStatus == QuranPlanLoadStatus.failure &&
        state.completedPlans.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.completedFailure != null
                  ? localizeFailureMessage(state.completedFailure!.message)
                  : t.failedToLoadPlans,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700),
            ),
            SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: () => _bloc.add(
                const LoadQuranPlans(status: 'completed', forceRefresh: true),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9EAA52),
                foregroundColor: Colors.white,
              ),
              child: Text(t.read),
            ),
          ],
        ),
      );
    }

    if (state.completedPlans.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFF9EAA52),
        onRefresh: () async {
          _bloc.add(
            const LoadQuranPlans(status: 'completed', forceRefresh: true),
          );
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 100.h),
            Center(child: _PlanEmptyIllustration(message: t.noCompletedPlans)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF9EAA52),
      onRefresh: () async {
        _bloc.add(
          const LoadQuranPlans(status: 'completed', forceRefresh: true),
        );
      },
      child: ListView.separated(
        controller: _completedScroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 90.h),
        itemCount:
            state.completedPlans.length +
            (state.isLoadingMoreCompleted ? 1 : 0),
        separatorBuilder: (_, _) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          if (index == state.completedPlans.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF9EAA52),
                ),
              ),
            );
          }
          final plan = state.completedPlans[index];
          return _CompletedQuranPlanCard(
            plan: plan,
            t: t,
            onOpenDetails: () => _openPlanDetails(plan),
            onMarkInProgress: () => _markInProgress(plan),
            onDelete: () => _confirmDelete(plan),
          );
        },
      ),
    );
  }
}

/// Rich active plan card powered directly by backend counts and schedule.
class _ActiveQuranPlanCard extends StatelessWidget {
  const _ActiveQuranPlanCard({
    required this.plan,
    required this.t,
    required this.onRead,
    required this.onMarkCompleted,
    this.onOpenDetails,
    this.onEdit,
    this.onDelete,
  });

  final QuranPlan plan;
  final QuranText t;
  final VoidCallback onRead;
  final VoidCallback onMarkCompleted;
  final VoidCallback? onOpenDetails;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    const cardBorderColor = Color(0xFFD2E3A8);
    final schedule = plan.schedule;
    final counts = plan.counts;

    // Determine status badge details based on backend-calculated fields
    final (statusText, statusBg, statusFg, statusIcon) = () {
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

    final daySub =
        '${t.day} ${t.n(schedule.dayNumber)} / ${t.n(schedule.targetDays)} · ${t.n(schedule.daysLeft)} ${t.daysLeft}';

    return InkWell(
      onTap: onOpenDetails,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: context.pageColor(Colors.white),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: cardBorderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Book icon, Name, Day subtitle, and Menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 52.r,
                  height: 52.r,
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t.presetPlanName(plan.id, plan.name),
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF282442),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        daySub,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF8B9875),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Color(0xFF7A8D49),
                  ),
                  onSelected: (val) {
                    if (val == 'details') {
                      onOpenDetails?.call();
                    } else if (val == 'complete') {
                      onMarkCompleted();
                    } else if (val == 'edit') {
                      onEdit?.call();
                    } else if (val == 'delete') {
                      onDelete?.call();
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFF6B8042),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(child: Text(t.quranPlanDetails)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'complete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Color(0xFF6B8042),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(child: Text(t.markCompleted)),
                        ],
                      ),
                    ),
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
                          Flexible(child: Text(t.editPlan)),
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
                          Flexible(
                            child: Text(
                              t.deletePlan,
                              style: const TextStyle(color: Color(0xFFC15B4B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 10.h),

            // Schedule status badge & Progress percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14.sp, color: statusFg),
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
                Text(
                  '${t.progress}: ${t.n(counts.percentage)}%',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5D7133),
                  ),
                ),
              ],
            ),

            SizedBox(height: 8.h),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: LinearProgressIndicator(
                value: (counts.percentage.clamp(0, 100) / 100.0),
                minHeight: 6.h,
                backgroundColor: const Color(0xFFE9EED9),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF9EAA52),
                ),
              ),
            ),

            SizedBox(height: 12.h),

            // Stats grid (Ayahs completed, remaining, daily target, today remaining)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9F0),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFE4ECD2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _StatColumn(
                      title: t.ayahsCompleted,
                      value: t.n(counts.completedAyahs),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24.h,
                    color: const Color(0xFFD4E5A8),
                  ),
                  Expanded(
                    child: _StatColumn(
                      title: t.ayahsRemaining,
                      value: t.n(counts.remainingAyahs),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24.h,
                    color: const Color(0xFFD4E5A8),
                  ),
                  Expanded(
                    child: _StatColumn(
                      title: t.dailyTarget,
                      value: t.n(schedule.ayahsPerDay),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24.h,
                    color: const Color(0xFFD4E5A8),
                  ),
                  Expanded(
                    child: _StatColumn(
                      title: t.todayRemaining,
                      value: t.n(schedule.todayRemainingAyahs),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12.h),

            // Read button
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: onRead,
                borderRadius: BorderRadius.circular(16.r),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4E5A8),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 16.sp,
                        color: const Color(0xFF26321F),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        t.read,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF26321F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.title, required this.value});

  final String title;
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
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 10.sp, color: const Color(0xFF8B9875)),
        ),
      ],
    );
  }
}

/// Completed plan card
class _CompletedQuranPlanCard extends StatelessWidget {
  const _CompletedQuranPlanCard({
    required this.plan,
    required this.t,
    required this.onMarkInProgress,
    this.onOpenDetails,
    this.onDelete,
  });

  final QuranPlan plan;
  final QuranText t;
  final VoidCallback onMarkInProgress;
  final VoidCallback? onOpenDetails;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    const cardBorderColor = Color(0xFFD2E3A8);

    return InkWell(
      onTap: onOpenDetails,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: context.pageColor(Colors.white),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: cardBorderColor, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 52.r,
              height: 52.r,
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
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t.presetPlanName(plan.id, plan.name),
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF282442),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${t.days(plan.days)} · ${t.n(plan.counts.totalAyahs)} ${t.ayahsCompleted}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF8B9875),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFFE5EED0),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Text(
                t.completed,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B8042),
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: Color(0xFF7A8D49),
              ),
              onSelected: (val) {
                if (val == 'details') {
                  onOpenDetails?.call();
                } else if (val == 'reopen') {
                  onMarkInProgress();
                } else if (val == 'delete') {
                  onDelete?.call();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'details',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF6B8042),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(child: Text(t.quranPlanDetails)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'reopen',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.refresh_rounded,
                        color: Color(0xFF6B8042),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(child: Text(t.markInProgress)),
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
                      Flexible(
                        child: Text(
                          t.deletePlan,
                          style: const TextStyle(color: Color(0xFFC15B4B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Preset card for Tab 1 (Search Plan)
class _QuranPresetCard extends StatelessWidget {
  const _QuranPresetCard({
    required this.plan,
    required this.name,
    required this.daysLabel,
    this.buttonText,
    this.onAction,
  });

  final QuranPlan plan;
  final String name, daysLabel;
  final String? buttonText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    const cardBorderColor = Color(0xFFD2E3A8);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: context.pageColor(Colors.white),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: cardBorderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 56.r,
            height: 56.r,
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: const Color(0xFFDDEBBE),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Image.asset('assets/images/Quran.png', fit: BoxFit.contain),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF282442),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  daysLabel,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF8B9875),
                  ),
                ),
              ],
            ),
          ),
          if (buttonText != null && onAction != null)
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(16.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4E5A8),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Text(
                  buttonText!,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF26321F),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom Empty state illustration matching the user's design screenshots
class _PlanEmptyIllustration extends StatelessWidget {
  const _PlanEmptyIllustration({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: MediaQuery.sizeOf(context).width * .38,
          child: AspectRatio(
            aspectRatio: 140 / 130,
            child: CustomPaint(painter: _EmptyDocumentPainter()),
          ),
        ),
        SizedBox(height: 16.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF888888),
              fontWeight: FontWeight.w400,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyDocumentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paperPaint = Paint()
      ..color = const Color(0xFFD4E5A8)
      ..style = PaintingStyle.fill;

    final foldPaint = Paint()
      ..color = const Color(0xFF869E4C)
      ..style = PaintingStyle.fill;

    final rayPaint = Paint()
      ..color = const Color(0xFF768943)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw radiating lines on top left
    canvas.drawLine(
      Offset(size.width * 0.25, size.height * 0.22),
      Offset(size.width * 0.16, size.height * 0.13),
      rayPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.29),
      Offset(size.width * 0.17, size.height * 0.27),
      rayPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.23, size.height * 0.35),
      Offset(size.width * 0.17, size.height * 0.39),
      rayPaint,
    );

    // Draw document sheet with top right corner folded
    final docLeft = size.width * 0.38;
    final docTop = size.height * 0.18;
    final docWidth = size.width * 0.44;
    final docHeight = size.height * 0.65;
    final foldSize = size.width * .1;

    final docPath = Path()
      ..moveTo(docLeft, docTop)
      ..lineTo(docLeft + docWidth - foldSize, docTop)
      ..lineTo(docLeft + docWidth, docTop + foldSize)
      ..lineTo(docLeft + docWidth, docTop + docHeight - 8)
      ..quadraticBezierTo(
        docLeft + docWidth,
        docTop + docHeight,
        docLeft + docWidth - 8,
        docTop + docHeight,
      )
      ..lineTo(docLeft + 8, docTop + docHeight)
      ..quadraticBezierTo(
        docLeft,
        docTop + docHeight,
        docLeft,
        docTop + docHeight - 8,
      )
      ..close();

    canvas.drawPath(docPath, paperPaint);

    // Fold triangle on top-right
    final foldPath = Path()
      ..moveTo(docLeft + docWidth - foldSize, docTop)
      ..lineTo(docLeft + docWidth, docTop + foldSize)
      ..lineTo(docLeft + docWidth - foldSize, docTop + foldSize)
      ..close();
    canvas.drawPath(foldPath, foldPaint);

    // Bottom dark curved accent
    final bottomAccent = Path()
      ..moveTo(docLeft, docTop + docHeight - 4)
      ..lineTo(docLeft + docWidth, docTop + docHeight - 4)
      ..lineTo(docLeft + docWidth - 4, docTop + docHeight)
      ..lineTo(docLeft + 4, docTop + docHeight)
      ..close();
    canvas.drawPath(bottomAccent, foldPaint);

    // Circle badge with question mark ? on the left of paper
    final badgeCenter = Offset(size.width * 0.35, size.height * 0.36);
    final badgeRadius = size.width * .13;

    final badgePaint = Paint()
      ..color = const Color(0xFFD4E5A8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(badgeCenter, badgeRadius, badgePaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '?',
        style: TextStyle(
          color: const Color(0xFF6B8042),
          fontSize: size.width * .16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      badgeCenter - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
