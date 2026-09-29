import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/localization/localized_failure_message.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import '../../data/repositories/quran_plan_repository_impl.dart';
import '../../domain/quran_plan.dart';
import '../../domain/repositories/quran_plan_repository.dart';
import '../bloc/quran_plan/quran_plan_bloc.dart';
import '../quran_route_args.dart';
import '../quran_text.dart';

class QuranPlanAyahsScreen extends StatefulWidget {
  const QuranPlanAyahsScreen({
    super.key,
    required this.planId,
    required this.planName,
    this.repository,
    this.bloc,
  });

  final String planId;
  final String planName;
  final QuranPlanRepository? repository;
  final QuranPlanBloc? bloc;

  @override
  State<QuranPlanAyahsScreen> createState() => _QuranPlanAyahsScreenState();
}

class _QuranPlanAyahsScreenState extends State<QuranPlanAyahsScreen> {
  late final QuranPlanBloc _bloc =
      widget.bloc ??
      QuranPlanBloc(
        repository: widget.repository ?? QuranPlanRepositoryImpl.shared,
      );

  final _scrollController = ScrollController();
  String _currentFilter = 'all';

  @override
  void initState() {
    super.initState();
    _bloc.add(
      LoadPlanAyahs(
        planId: widget.planId,
        filter: _currentFilter,
        forceRefresh: true,
      ),
    );
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 300) {
      _bloc.add(LoadMorePlanAyahs(planId: widget.planId));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    if (widget.bloc == null) {
      _bloc.close();
    }
    super.dispose();
  }

  void _onFilterSelected(String filter) {
    if (_currentFilter == filter) return;
    setState(() => _currentFilter = filter);
    _bloc.add(ChangePlanAyahsFilter(planId: widget.planId, filter: filter));
  }

  void _openAyahReading(QuranPlanAyah ayah) {
    Navigator.of(context)
        .pushNamed(
          RouteNames.quranSurahDetail,
          arguments: SurahRouteArgs(
            surahNo: ayah.surahNumber,
            surahName: ayah.surahNameEnglish,
            ayahNo: ayah.ayahNumber,
            paraNumber: ayah.paraNumber,
          ),
        )
        .then((_) {
          if (mounted) {
            _bloc.add(
              LoadPlanAyahs(
                planId: widget.planId,
                filter: _currentFilter,
                forceRefresh: true,
              ),
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
      child: Scaffold(
        backgroundColor: context.pageColor(Colors.white),
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            t.planAyahs,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            widget.planName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF8B9875),
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 40.r),
                  ],
                ),
              ),

              // Filter Chips Row: [All] [Read] [Unread]
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                child: Row(
                  children: [
                    _FilterChip(
                      label: t.all,
                      isSelected: _currentFilter == 'all',
                      onTap: () => _onFilterSelected('all'),
                    ),
                    SizedBox(width: 8.w),
                    _FilterChip(
                      label: t.read,
                      isSelected: _currentFilter == 'read',
                      onTap: () => _onFilterSelected('read'),
                    ),
                    SizedBox(width: 8.w),
                    _FilterChip(
                      label: t.unread,
                      isSelected: _currentFilter == 'unread',
                      onTap: () => _onFilterSelected('unread'),
                    ),
                  ],
                ),
              ),

              // Body: Paginated Ayahs List
              Expanded(
                child: BlocBuilder<QuranPlanBloc, QuranPlanState>(
                  builder: (context, state) {
                    if (state.isLoadingAyahs && state.planAyahs.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(color: oliveColor),
                      );
                    }

                    if (state.ayahsFailure != null && state.planAyahs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              localizeFailureMessage(
                                state.ayahsFailure!.message,
                              ),
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            ElevatedButton(
                              onPressed: () => _bloc.add(
                                LoadPlanAyahs(
                                  planId: widget.planId,
                                  filter: _currentFilter,
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

                    if (state.planAyahs.isEmpty) {
                      return RefreshIndicator(
                        color: oliveColor,
                        onRefresh: () async {
                          _bloc.add(
                            LoadPlanAyahs(
                              planId: widget.planId,
                              filter: _currentFilter,
                              forceRefresh: true,
                            ),
                          );
                        },
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: 120.h),
                            Center(
                              child: Text(
                                t.noPlansYet,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      color: oliveColor,
                      onRefresh: () async {
                        _bloc.add(
                          LoadPlanAyahs(
                            planId: widget.planId,
                            filter: _currentFilter,
                            forceRefresh: true,
                          ),
                        );
                      },
                      child: ListView.separated(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
                        itemCount:
                            state.planAyahs.length +
                            (state.isLoadingMoreAyahs ? 1 : 0),
                        separatorBuilder: (_, _) => SizedBox(height: 8.h),
                        itemBuilder: (context, index) {
                          if (index == state.planAyahs.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: oliveColor,
                                ),
                              ),
                            );
                          }

                          final ayah = state.planAyahs[index];
                          final surahDisplay =
                              t.isBangla && ayah.surahNameBangla.isNotEmpty
                              ? ayah.surahNameBangla
                              : ayah.surahNameEnglish;

                          return InkWell(
                            onTap: () => _openAyahReading(ayah),
                            borderRadius: BorderRadius.circular(16.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 12.h,
                              ),
                              decoration: BoxDecoration(
                                color: context.pageColor(Colors.white),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  // Surah & Ayah badge
                                  Container(
                                    width: 42.r,
                                    height: 42.r,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: ayah.isRead
                                          ? const Color(0xFFE8F5E9)
                                          : const Color(0xFFF7F9F0),
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(
                                        color: ayah.isRead
                                            ? const Color(0xFF81C784)
                                            : borderColor,
                                      ),
                                    ),
                                    child: Text(
                                      ayah.ayahKey,
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w700,
                                        color: ayah.isRead
                                            ? const Color(0xFF2E7D32)
                                            : const Color(0xFF5D7133),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),

                                  // Surah details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              surahDisplay,
                                              style: TextStyle(
                                                fontSize: 13.sp,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF282442),
                                              ),
                                            ),
                                            if (ayah.surahNameArabic.isNotEmpty)
                                              Text(
                                                ayah.surahNameArabic,
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  fontFamily: 'Amiri',
                                                  color: const Color(
                                                    0xFF5D7133,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        SizedBox(height: 3.h),
                                        Text(
                                          '${t.ayah} ${t.n(ayah.ayahNumber)} · ${t.para} ${t.n(ayah.paraNumber)}',
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            color: const Color(0xFF8B9875),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 8.w),

                                  // Read State Icon
                                  if (ayah.isRead)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(
                                          10.r,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_rounded,
                                            size: 13.sp,
                                            color: const Color(0xFF2E7D32),
                                          ),
                                          SizedBox(width: 2.w),
                                          Text(
                                            t.read,
                                            style: TextStyle(
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF2E7D32),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: const Color(0xFF8A9A70),
                                      size: 20.sp,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4E5A8) : const Color(0xFFF7F9F0),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF9EAA52)
                : const Color(0xFFD2E3A8),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? const Color(0xFF232D1C)
                : const Color(0xFF5D6B44),
          ),
        ),
      ),
    );
  }
}
