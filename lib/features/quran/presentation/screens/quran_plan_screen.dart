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
import '../../data/services/quran_content_service.dart';

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

  int _tab = 0; // 0 = My Plan, 1 = Search Plan, 2 = Completed
  String _searchQuery = '';

  /// Presets whose plan is being created, so a second tap waits.
  final _starting = <String>{};

  /// Ayah count per surah, for each preset's daily load.
  late final Future<Map<int, int>> _ayahCounts = QuranContentService.shared
      .loadSurahs()
      .then((list) => {for (final s in list) s.number: s.totalAyah})
      .catchError((Object _) => <int, int>{});

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

  /// A preset covers the whole Quran or a run of surahs (Juz Amma is surahs
  /// 78-114, exactly para 30).
  static bool _isWholeQuran(QuranPlan preset) =>
      preset.startSurah == 1 && preset.endSurah == 114;

  static List<int> _presetSurahs(QuranPlan preset) => [
    for (var n = preset.startSurah; n <= preset.endSurah; n++) n,
  ];

  Future<void> _enrollPreset(QuranPlan preset) async {
    if (_starting.contains(preset.id)) return;
    final t = QuranText.read(context);
    final repo = widget.repository ?? QuranPlanRepositoryImpl.shared;
    final whole = _isWholeQuran(preset);
    setState(() => _starting.add(preset.id));
    final result = await repo.createPlan(
      CreateQuranPlanRequest(
        name: preset.name,
        targetDays: preset.targetDays,
        wholeQuran: whole,
        surahNumbers: whole ? const [] : _presetSurahs(preset),
      ),
    );
    if (!mounted) return;
    setState(() => _starting.remove(preset.id));
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
            color: dialogCtx.inkColor(_ink),
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

  Future<void> _markCompleted(QuranPlan plan) async {
    final t = QuranText.read(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: dialogCtx.surfaceColor(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          t.markCompletedConfirmTitle,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: dialogCtx.inkColor(_ink),
          ),
        ),
        content: Text(
          t.markCompletedConfirmMessage,
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
              backgroundColor: const Color(0xFF7A8D49),
            ),
            child: Text(t.markCompleted),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _bloc.add(CompleteQuranPlan(planId: plan.id));
    }
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
    final next = plan.nextAyah;
    Navigator.of(context)
        .pushNamed(
          RouteNames.quranSurahDetail,
          arguments: next == null
              ? SurahRouteArgs(
                  surahNo: plan.startSurah,
                  surahName: plan.startSurahName,
                )
              : SurahRouteArgs(
                  surahNo: next.surahNumber,
                  surahName: next.surahNameEnglish,
                  ayahNo: next.ayahNumber,
                  paraNumber: next.paraNumber,
                ),
        )
        .then((_) {
          // Reading moves the plan's progress and next ayah.
          if (mounted) _bloc.add(const LoadQuranPlans(forceRefresh: true));
        });
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
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
                      child: QuranSegmentedTabs(
                        selected: _tab,
                        labels: [t.myPlan, t.searchPlan, t.completed],
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

                // Floating "Create Plan" on "My Plan"; the preset list offers
                // it as its first entry instead, so it never covers a preset.
                if (_tab == 0)
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
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: context.inkColor(Colors.grey.shade700),
              ),
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
              child: Text(t.retry),
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
            Center(
              child: _PlanEmptyIllustration(
                message: t.noActivePlans,
                hint: t.noActivePlansHint,
                action: t.exploreReadyPlans,
                onAction: () => setState(() => _tab = 1),
              ),
            ),
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

    return FutureBuilder<Map<int, int>>(
      future: _ayahCounts,
      builder: (context, counts) => ListView.separated(
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 90.h),
        itemCount: presets.length + 1,
        separatorBuilder: (_, _) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _CreateOwnPlanCard(
              title: t.createPlan,
              onTap: _openCreatePlan,
            );
          }
          final plan = presets[index - 1];
          final ayahs = _isWholeQuran(plan)
              ? 6236
              : _presetSurahs(plan).fold<int?>(0, (sum, surah) {
                  final count = counts.data?[surah];
                  return sum == null || count == null ? null : sum + count;
                });
          return _QuranPresetCard(
            plan: plan,
            name: t.presetPlanName(plan.id, plan.name),
            daysLabel: [
              t.days(plan.days),
              if (ayahs != null && ayahs > 0)
                t.aboutPerDay((ayahs / plan.days).ceil()),
            ].join(' · '),
            buttonText: t.getStarted,
            busy: _starting.contains(plan.id),
            onAction: () => _enrollPreset(plan),
          );
        },
      ),
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
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: context.inkColor(Colors.grey.shade700),
              ),
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
              child: Text(t.retry),
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

const _ink = Color(0xFF2D3A1F);
const _muted = Color(0xFF7C8A63);
const _olive = Color(0xFF7A8D49);
const _cardLine = Color(0xFFD2E3A8);

/// The shared card frame of the Planner lists.
class _PlanCardFrame extends StatelessWidget {
  const _PlanCardFrame({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20.r);
    return Material(
      color: context.surfaceColor(Colors.white),
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: context.lineColor(_cardLine)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// The Quran artwork tile at the start of every plan card.
class _PlanIcon extends StatelessWidget {
  const _PlanIcon({this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size.r,
    height: size.r,
    padding: EdgeInsets.all(6.r),
    decoration: BoxDecoration(
      color: context.surfaceColor(const Color(0xFFDDEBBE)),
      borderRadius: BorderRadius.circular(14.r),
    ),
    child: Image.asset('assets/images/Quran.png', fit: BoxFit.contain),
  );
}

/// One menu entry with its icon; destructive entries are red.
PopupMenuItem<String> _menuItem(
  String value,
  IconData icon,
  String label, {
  bool destructive = false,
}) {
  const red = Color(0xFFC15B4B);
  return PopupMenuItem(
    value: value,
    child: Row(
      children: [
        Icon(
          icon,
          color: destructive ? red : const Color(0xFF6B8042),
          size: 20,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: destructive ? const TextStyle(color: red) : null,
          ),
        ),
      ],
    ),
  );
}

/// An active plan: where it stands, what today asks for, and one clear way
/// to carry on reading.
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
    final schedule = plan.schedule;
    final counts = plan.counts;
    final next = plan.nextAyah;

    final (statusText, statusFg, statusIcon) = schedule.isOverdue
        ? (t.overdue, const Color(0xFFC62828), Icons.warning_amber_rounded)
        : schedule.aheadBy > 0
        ? (
            '+${t.n(schedule.aheadBy)} ${t.aheadOfSchedule}',
            const Color(0xFF2E7D32),
            Icons.trending_up_rounded,
          )
        : schedule.aheadBy < 0 || !schedule.isOnTrack
        ? (
            t.behindSchedule,
            const Color(0xFFE65100),
            Icons.trending_down_rounded,
          )
        : (
            t.onTrack,
            const Color(0xFF52692D),
            Icons.check_circle_outline_rounded,
          );
    final statusColor = context.inkColor(statusFg);
    final todayDone = schedule.todayRemainingAyahs <= 0;

    return _PlanCardFrame(
      onTap: onOpenDetails,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _PlanIcon(),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.presetPlanName(plan.id, plan.name),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: context.inkColor(_ink),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      t.dayOfTotal(
                        schedule.dayNumber,
                        schedule.targetDays,
                        schedule.daysLeft,
                      ),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.inkColor(_muted),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: context.inkColor(_olive),
                ),
                onSelected: (val) => switch (val) {
                  'details' => onOpenDetails?.call(),
                  'complete' => onMarkCompleted(),
                  'edit' => onEdit?.call(),
                  'delete' => onDelete?.call(),
                  _ => null,
                },
                itemBuilder: (_) => [
                  _menuItem(
                    'details',
                    Icons.info_outline_rounded,
                    t.quranPlanDetails,
                  ),
                  _menuItem(
                    'complete',
                    Icons.check_circle_outline,
                    t.markCompleted,
                  ),
                  _menuItem('edit', Icons.edit_note_rounded, t.editPlan),
                  _menuItem(
                    'delete',
                    Icons.delete_outline_rounded,
                    t.deletePlan,
                    destructive: true,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Schedule status and overall progress.
          Row(
            children: [
              Icon(statusIcon, size: 16.sp, color: statusColor),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  statusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              Text(
                '${t.n(counts.percentage)}%',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: context.inkColor(const Color(0xFF5D7133)),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: counts.percentage.clamp(0, 100) / 100.0,
              minHeight: 6.h,
              backgroundColor: context.lineColor(const Color(0xFFE9EED9)),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF9EAA52)),
            ),
          ),
          SizedBox(height: 12.h),

          // Today's goal, the number that matters most day to day.
          Container(
            key: const ValueKey('quran-plan-today'),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: context.surfaceColor(
                todayDone ? const Color(0xFFE8F5E9) : const Color(0xFFF4F7EA),
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(
                  todayDone ? Icons.check_circle_rounded : Icons.today_rounded,
                  size: 18.sp,
                  color: context.inkColor(
                    todayDone ? const Color(0xFF2E7D32) : _olive,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    todayDone
                        ? t.todayTargetDone
                        : t.todayToGo(schedule.todayRemainingAyahs),
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: context.inkColor(_ink),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _StatColumn(
                  title: t.ayahsCompleted,
                  value: t.n(counts.completedAyahs),
                ),
              ),
              Expanded(
                child: _StatColumn(
                  title: t.ayahsRemaining,
                  value: t.n(counts.remainingAyahs),
                ),
              ),
              Expanded(
                child: _StatColumn(
                  title: t.dailyTarget,
                  value: t.n(schedule.ayahsPerDay),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // The one main action: pick up where the reading stopped.
          FilledButton(
            key: const ValueKey('quran-plan-continue'),
            onPressed: onRead,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF9EAA52),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.menu_book_rounded, size: 20.sp),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.continueReading,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (next != null)
                        Text(
                          t.continueAt(
                            t.surahName(
                              next.surahNumber,
                              next.surahNameEnglish,
                            ),
                            next.ayahNumber,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white.withValues(alpha: .9),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, size: 18.sp),
              ],
            ),
          ),
        ],
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
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: context.inkColor(_ink),
          ),
        ),
        SizedBox(height: 2.h),
        // Wraps rather than cutting the label short.
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(
            fontSize: 11.sp,
            height: 1.2,
            color: context.inkColor(_muted),
          ),
        ),
      ],
    );
  }
}

/// A completed plan: its name in full, what it covered, and a way back in.
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
    return _PlanCardFrame(
      onTap: onOpenDetails,
      child: Row(
        children: [
          const _PlanIcon(),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.presetPlanName(plan.id, plan.name),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: context.inkColor(_ink),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${t.days(plan.days)} · ${t.n(plan.counts.totalAyahs)} ${t.ayahsCompleted}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: context.inkColor(_muted),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: context.surfaceColor(const Color(0xFFE5EED0)),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14.sp,
                        color: context.inkColor(const Color(0xFF6B8042)),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        t.completed,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: context.inkColor(const Color(0xFF6B8042)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: context.inkColor(_olive),
            ),
            onSelected: (val) => switch (val) {
              'details' => onOpenDetails?.call(),
              'reopen' => onMarkInProgress(),
              'delete' => onDelete?.call(),
              _ => null,
            },
            itemBuilder: (_) => [
              _menuItem(
                'details',
                Icons.info_outline_rounded,
                t.quranPlanDetails,
              ),
              _menuItem('reopen', Icons.refresh_rounded, t.markInProgress),
              _menuItem(
                'delete',
                Icons.delete_outline_rounded,
                t.deletePlan,
                destructive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A ready-made plan: its length and daily load, and a button to start it.
class _QuranPresetCard extends StatelessWidget {
  const _QuranPresetCard({
    required this.plan,
    required this.name,
    required this.daysLabel,
    this.buttonText,
    this.onAction,
    this.busy = false,
  });

  final QuranPlan plan;
  final String name, daysLabel;
  final String? buttonText;
  final VoidCallback? onAction;

  /// The plan is being created; the button waits.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return _PlanCardFrame(
      child: Row(
        children: [
          const _PlanIcon(size: 52),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: context.inkColor(_ink),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  daysLabel,
                  style: TextStyle(
                    fontSize: 12.sp,
                    height: 1.3,
                    color: context.inkColor(_muted),
                  ),
                ),
              ],
            ),
          ),
          if (buttonText != null && onAction != null) ...[
            SizedBox(width: 8.w),
            FilledButton(
              key: ValueKey('quran-preset-${plan.id}'),
              onPressed: busy ? null : onAction,
              style: FilledButton.styleFrom(
                backgroundColor: context.surfaceColor(const Color(0xFFD4E5A8)),
                foregroundColor: context.inkColor(const Color(0xFF26321F)),
                disabledBackgroundColor: context.surfaceColor(
                  const Color(0xFFD4E5A8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                minimumSize: Size(0, 36.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: busy
                  ? SizedBox(
                      width: 16.r,
                      height: 16.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.inkColor(_olive),
                      ),
                    )
                  : Text(
                      buttonText!,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Create Plan" as a list entry, for a plan of one's own choosing.
class _CreateOwnPlanCard extends StatelessWidget {
  const _CreateOwnPlanCard({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20.r);
    return Material(
      key: const ValueKey('quran-plan-create-own'),
      color: context.surfaceColor(const Color(0xFFF4F7EA)),
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          child: Row(
            children: [
              Container(
                width: 40.r,
                height: 40.r,
                decoration: const BoxDecoration(
                  color: Color(0xFF9EAA52),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit_note_rounded,
                  color: Colors.white,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: context.inkColor(_ink),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.inkColor(_olive),
                size: 22.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The empty-list illustration, with an optional hint and next step.
class _PlanEmptyIllustration extends StatelessWidget {
  const _PlanEmptyIllustration({
    required this.message,
    this.hint,
    this.action,
    this.onAction,
  });

  final String message;
  final String? hint, action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: MediaQuery.sizeOf(context).width * .34,
            child: AspectRatio(
              aspectRatio: 140 / 130,
              child: CustomPaint(painter: _EmptyDocumentPainter()),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: context.inkColor(_ink),
            ),
          ),
          if (hint != null) ...[
            SizedBox(height: 6.h),
            Text(
              hint!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                height: 1.4,
                color: context.inkColor(_muted),
              ),
            ),
          ],
          if (action != null && onAction != null) ...[
            SizedBox(height: 16.h),
            OutlinedButton.icon(
              key: const ValueKey('quran-plan-explore'),
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: context.inkColor(_olive),
                side: BorderSide(color: context.lineColor(_cardLine)),
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.r),
                ),
              ),
              icon: Icon(Icons.auto_stories_rounded, size: 18.sp),
              label: Text(
                action!,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
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
