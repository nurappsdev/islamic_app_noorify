import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/quran/domain/quran_plan.dart';

enum QuranPlanLoadStatus { initial, loading, success, failure }

class QuranPlanState {
  const QuranPlanState({
    this.activeStatus = QuranPlanLoadStatus.initial,
    this.completedStatus = QuranPlanLoadStatus.initial,
    this.activePlans = const [],
    this.completedPlans = const [],
    this.activePage = 1,
    this.completedPage = 1,
    this.hasMoreActive = false,
    this.hasMoreCompleted = false,
    this.isLoadingMoreActive = false,
    this.isLoadingMoreCompleted = false,
    this.activeFailure,
    this.completedFailure,
    this.isCreating = false,
    this.createdPlan,
    this.createFailure,
    this.isUpdating = false,
    this.updatedPlan,
    this.updateFailure,
    this.selectedPlanDetails,
    this.isLoadingDetails = false,
    this.detailsFailure,
    this.isCompleting = false,
    this.completedSuccess = false,
    this.completeFailure,
    this.isDeleting = false,
    this.deleteSuccess = false,
    this.deleteFailure,
    this.planAyahs = const [],
    this.planAyahsMeta = const QuranPlanMeta(),
    this.isLoadingAyahs = false,
    this.isLoadingMoreAyahs = false,
    this.ayahsFilter = 'all',
    this.ayahsFailure,
  });

  final QuranPlanLoadStatus activeStatus;
  final QuranPlanLoadStatus completedStatus;
  final List<QuranPlan> activePlans;
  final List<QuranPlan> completedPlans;
  final int activePage;
  final int completedPage;
  final bool hasMoreActive;
  final bool hasMoreCompleted;
  final bool isLoadingMoreActive;
  final bool isLoadingMoreCompleted;
  final Failure? activeFailure;
  final Failure? completedFailure;

  final bool isCreating;
  final QuranPlan? createdPlan;
  final Failure? createFailure;

  final bool isUpdating;
  final QuranPlan? updatedPlan;
  final Failure? updateFailure;

  // Plan Details
  final QuranPlan? selectedPlanDetails;
  final bool isLoadingDetails;
  final Failure? detailsFailure;

  // Complete Plan
  final bool isCompleting;
  final bool completedSuccess;
  final Failure? completeFailure;

  // Delete Plan
  final bool isDeleting;
  final bool deleteSuccess;
  final Failure? deleteFailure;

  // Plan Ayahs
  final List<QuranPlanAyah> planAyahs;
  final QuranPlanMeta planAyahsMeta;
  final bool isLoadingAyahs;
  final bool isLoadingMoreAyahs;
  final String ayahsFilter;
  final Failure? ayahsFailure;

  bool get isLoadingActive =>
      activeStatus == QuranPlanLoadStatus.loading && activePlans.isEmpty;
  bool get isLoadingCompleted =>
      completedStatus == QuranPlanLoadStatus.loading && completedPlans.isEmpty;

  QuranPlanState copyWith({
    QuranPlanLoadStatus? activeStatus,
    QuranPlanLoadStatus? completedStatus,
    List<QuranPlan>? activePlans,
    List<QuranPlan>? completedPlans,
    int? activePage,
    int? completedPage,
    bool? hasMoreActive,
    bool? hasMoreCompleted,
    bool? isLoadingMoreActive,
    bool? isLoadingMoreCompleted,
    Failure? activeFailure,
    bool clearActiveFailure = false,
    Failure? completedFailure,
    bool clearCompletedFailure = false,
    bool? isCreating,
    QuranPlan? createdPlan,
    bool clearCreatedPlan = false,
    Failure? createFailure,
    bool clearCreateFailure = false,
    bool? isUpdating,
    QuranPlan? updatedPlan,
    bool clearUpdatedPlan = false,
    Failure? updateFailure,
    bool clearUpdateFailure = false,
    QuranPlan? selectedPlanDetails,
    bool clearSelectedPlanDetails = false,
    bool? isLoadingDetails,
    Failure? detailsFailure,
    bool clearDetailsFailure = false,
    bool? isCompleting,
    bool? completedSuccess,
    Failure? completeFailure,
    bool clearCompleteFailure = false,
    bool? isDeleting,
    bool? deleteSuccess,
    Failure? deleteFailure,
    bool clearDeleteFailure = false,
    List<QuranPlanAyah>? planAyahs,
    QuranPlanMeta? planAyahsMeta,
    bool? isLoadingAyahs,
    bool? isLoadingMoreAyahs,
    String? ayahsFilter,
    Failure? ayahsFailure,
    bool clearAyahsFailure = false,
  }) => QuranPlanState(
    activeStatus: activeStatus ?? this.activeStatus,
    completedStatus: completedStatus ?? this.completedStatus,
    activePlans: activePlans ?? this.activePlans,
    completedPlans: completedPlans ?? this.completedPlans,
    activePage: activePage ?? this.activePage,
    completedPage: completedPage ?? this.completedPage,
    hasMoreActive: hasMoreActive ?? this.hasMoreActive,
    hasMoreCompleted: hasMoreCompleted ?? this.hasMoreCompleted,
    isLoadingMoreActive: isLoadingMoreActive ?? this.isLoadingMoreActive,
    isLoadingMoreCompleted:
        isLoadingMoreCompleted ?? this.isLoadingMoreCompleted,
    activeFailure: clearActiveFailure
        ? null
        : (activeFailure ?? this.activeFailure),
    completedFailure: clearCompletedFailure
        ? null
        : (completedFailure ?? this.completedFailure),
    isCreating: isCreating ?? this.isCreating,
    createdPlan: clearCreatedPlan ? null : (createdPlan ?? this.createdPlan),
    createFailure: clearCreateFailure
        ? null
        : (createFailure ?? this.createFailure),
    isUpdating: isUpdating ?? this.isUpdating,
    updatedPlan: clearUpdatedPlan ? null : (updatedPlan ?? this.updatedPlan),
    updateFailure: clearUpdateFailure
        ? null
        : (updateFailure ?? this.updateFailure),
    selectedPlanDetails: clearSelectedPlanDetails
        ? null
        : (selectedPlanDetails ?? this.selectedPlanDetails),
    isLoadingDetails: isLoadingDetails ?? this.isLoadingDetails,
    detailsFailure: clearDetailsFailure
        ? null
        : (detailsFailure ?? this.detailsFailure),
    isCompleting: isCompleting ?? this.isCompleting,
    completedSuccess: completedSuccess ?? this.completedSuccess,
    completeFailure: clearCompleteFailure
        ? null
        : (completeFailure ?? this.completeFailure),
    isDeleting: isDeleting ?? this.isDeleting,
    deleteSuccess: deleteSuccess ?? this.deleteSuccess,
    deleteFailure: clearDeleteFailure
        ? null
        : (deleteFailure ?? this.deleteFailure),
    planAyahs: planAyahs ?? this.planAyahs,
    planAyahsMeta: planAyahsMeta ?? this.planAyahsMeta,
    isLoadingAyahs: isLoadingAyahs ?? this.isLoadingAyahs,
    isLoadingMoreAyahs: isLoadingMoreAyahs ?? this.isLoadingMoreAyahs,
    ayahsFilter: ayahsFilter ?? this.ayahsFilter,
    ayahsFailure: clearAyahsFailure
        ? null
        : (ayahsFailure ?? this.ayahsFailure),
  );
}
