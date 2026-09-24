import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:islami_app_noorify/core/constants/app_route_observer.dart';
import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/hadith/data/datasources/hadith_library_remote_data_source.dart';
import 'package:islami_app_noorify/features/hadith/data/hadith_bookmark_store.dart';
import 'package:islami_app_noorify/features/hadith/data/hadith_content_settings.dart';
import 'package:islami_app_noorify/features/hadith/data/models/hadith_detail_model.dart';
import 'package:islami_app_noorify/features/hadith/data/repositories/hadith_library_repository_impl.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_detail.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_details.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_read_hadiths.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/track_hadith_reading.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_detail/hadith_detail_bloc.dart';
import 'package:islami_app_noorify/features/hadith/presentation/controllers/hadith_reading_tracker.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_bookmark_sheet.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_content_settings_drawer.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_list_scaffold.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_login_required_dialog.dart';

/// Route arguments for [HadithDetailScreen].
class HadithDetailArgs {
  const HadithDetailArgs({
    this.subCategoryId,
    this.bookId,
    this.categoryId,
    this.planId,
    this.title,
    this.initialHadithId,
    this.initialHadithNumber,
  }) : assert(
         subCategoryId != null ||
             bookId != null ||
             categoryId != null ||
             planId != null,
       );

  final String? subCategoryId;
  final String? bookId;

  /// A whole category's hadiths, e.g. a reading plan's ("Get Start" uses
  /// [bookId] and this together, since the plan's own hadiths endpoint is
  /// unreliable).
  final String? categoryId;

  /// A reading plan whose hadiths are listed (each with its read state).
  final String? planId;
  final String? title;

  /// Hadith to scroll to once the list is ready (see
  /// [HadithDetailScreen.initialHadithId]).
  final String? initialHadithId;
  final int? initialHadithNumber;
}

/// The hadiths of one sub-category (`GET /hadiths?subCategoryId=...`), of a
/// whole category (`GET /hadiths?bookId=...&categoryId=...` — how a reading
/// plan's "Get Start" opens its hadiths), of a whole book
/// (`GET /hadiths?bookId=...`), or of a reading plan
/// (`GET /hadiths/plans/{planId}/hadiths`).
///
/// Reached by tapping a row on [HadithSubCategoryScreen], the "Total
/// Hadith" button on a collection card of the library screen, or "Get Start"
/// on a plan of the planner. Each hadith is a card with its Arabic text,
/// Bangla translation, reference (takhrij), grade and source, paginated with
/// shimmer placeholders.
class HadithDetailScreen extends StatelessWidget {
  const HadithDetailScreen({
    super.key,
    this.subCategoryId,
    this.bookId,
    this.categoryId,
    this.planId,
    this.title,
    this.initialHadithId,
    this.initialHadithNumber,
  });

  final String? subCategoryId;
  final String? bookId;
  final String? categoryId;
  final String? planId;
  final String? title;

  /// When set, the list scrolls to this hadith (matched by id, else by
  /// [initialHadithNumber]) as soon as it has been loaded and laid out, e.g.
  /// to continue where the user stopped reading.
  final String? initialHadithId;
  final int? initialHadithNumber;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          HadithDetailBloc(
            GetHadithDetails(
              HadithLibraryRepositoryImpl(HadithLibraryRemoteDataSourceImpl()),
            ),
          )..add(
            LoadHadithDetails(
              subCategoryId: subCategoryId,
              bookId: bookId,
              categoryId: categoryId,
              planId: planId,
            ),
          ),
      child: _HadithDetailView(
        subCategoryId: subCategoryId,
        bookId: bookId,
        categoryId: categoryId,
        planId: planId,
        title: title,
        initialHadithId: initialHadithId,
        initialHadithNumber: initialHadithNumber,
      ),
    );
  }
}

class _HadithDetailView extends StatefulWidget {
  const _HadithDetailView({
    this.subCategoryId,
    this.bookId,
    this.categoryId,
    this.planId,
    this.title,
    this.initialHadithId,
    this.initialHadithNumber,
  });

  final String? subCategoryId;
  final String? bookId;
  final String? categoryId;
  final String? planId;
  final String? title;
  final String? initialHadithId;
  final int? initialHadithNumber;

  @override
  State<_HadithDetailView> createState() => _HadithDetailViewState();
}

class _HadithDetailViewState extends State<_HadithDetailView>
    with WidgetsBindingObserver, RouteAware {
  /// How close to the end of the list (in logical pixels) the next page
  /// starts loading.
  static const _loadMoreThreshold = 400.0;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _listKey = GlobalKey();
  final _scrollController = ScrollController();
  final _settingsStore = HadithContentSettingsStore();
  String _query = '';
  HadithContentSettings _settings = const HadithContentSettings();

  /// Measures the user's active reading time and reports it (see
  /// [HadithReadingTracker]).
  late final HadithReadingTracker _tracker = HadithReadingTracker(
    TrackHadithReading(
      HadithLibraryRepositoryImpl(HadithLibraryRemoteDataSourceImpl()),
    ),
  );

  /// Fetches which hadiths in this scope are already marked read server-side,
  /// so their Yes checkbox opens checked (see [_loadReadStatus]).
  final GetReadHadiths _getReadHadiths = GetReadHadiths(
    HadithLibraryRepositoryImpl(HadithLibraryRemoteDataSourceImpl()),
  );

  /// Id of the hadith currently in focus, for the per-hadith timer circles.
  /// Updated on every [_tracker] tick, so it starts/stops with it (paused
  /// while the screen is backgrounded or another route is on top).
  final _focusedId = ValueNotifier<String?>(null);

  /// Ticks once a second in step with [_tracker], to refresh the timer
  /// circles without rebuilding the whole screen.
  final _clock = ValueNotifier<int>(0);

  /// One key per card, to find which hadith is on screen.
  final _cardKeys = <String, GlobalKey>{};

  /// Ids of the cards currently listed, top to bottom.
  List<String> _displayedIds = const [];

  bool _leaving = false;

  /// Ids of hadiths the auto-complete dialog has already been shown for, so
  /// it never asks twice in the same visit.
  final _autoPrompted = <String>{};

  /// Whether the auto-complete dialog is currently up (so a tick landing
  /// mid-dialog doesn't queue another one).
  bool _autoDialogShowing = false;

  /// Set once the scroll to the initial hadith has been started (or given up
  /// on because the hadith isn't in the list).
  bool _initialScrollHandled = false;

  bool get _hasInitialTarget =>
      (widget.initialHadithId ?? '').isNotEmpty ||
      (widget.initialHadithNumber ?? 0) > 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _settingsStore.load().then((value) {
      if (mounted) setState(() => _settings = value);
    });
    WidgetsBinding.instance.addObserver(this);
    _tracker
      ..addListener(_onTrackerChanged)
      ..load()
      ..start(_focusedHadithId, onTick: _onTrackerTick);
    _loadReadStatus();
  }

  /// Marks the hadiths of this scope already read server-side as completed
  /// in [_tracker] (`GET /hadiths/reading/read`), so their Yes checkbox opens
  /// checked instead of only after this device reports them itself.
  Future<void> _loadReadStatus() async {
    if (!hadithIsSignedIn) return;
    final result = await _getReadHadiths(
      subCategoryId: widget.subCategoryId,
      bookId: widget.bookId,
      planId: widget.planId,
    );
    if (!mounted) return;
    result.fold((_) {}, _tracker.markAlreadyRead);
  }

  void _onTrackerTick(String? focusedHadithId) {
    if (!mounted) return;
    _focusedId.value = focusedHadithId;
    _clock.value++;
    _maybeShowAutoComplete(focusedHadithId);
  }

  /// Once [hadithId] has been in focus for
  /// [HadithReadingConfig.autoCompleteSeconds], asks "Your reading time is
  /// complete" on its own — without the user having to leave the screen.
  void _maybeShowAutoComplete(String? hadithId) {
    if (hadithId == null || _leaving || _autoDialogShowing) return;
    // Reporting needs a token; guests get the login dialog from the Yes box.
    if (!hadithIsSignedIn) return;
    if (_autoPrompted.contains(hadithId)) return;
    if (_tracker.isCompleted(hadithId) || _tracker.isCompleting(hadithId)) {
      return;
    }
    if (_tracker.dwellSeconds(hadithId) <
        HadithReadingConfig.autoCompleteSeconds) {
      return;
    }
    _autoPrompted.add(hadithId);
    _showAutoCompleteDialog(hadithId);
  }

  Future<void> _showAutoCompleteDialog(String hadithId) async {
    _autoDialogShowing = true;
    // Time spent on the dialog is not reading time.
    _tracker.pause();
    final appText = AppText.readOf(context);
    final hadiths = context.read<HadithDetailBloc>().state.hadiths;
    final number = hadiths
        .where((h) => h.id == hadithId)
        .map((h) => h.hadithNumber)
        .firstOrNull;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        // Only the Yes button dismisses this one.
        canPop: false,
        child: AlertDialog(
          backgroundColor: dialogContext.surfaceColor(Colors.white),
          title: Text(
            appText.hadithReadingTimeComplete,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          content: number == null || number == 0
              ? null
              : Text(
                  '${appText.categoryHadith} $number',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: dialogContext.inkColor(const Color(0xFF5D6B44)),
                  ),
                ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF008000),
              ),
              child: Text(appText.yes),
            ),
          ],
        ),
      ),
    );
    _autoDialogShowing = false;
    if (!mounted) return;
    if (!_leaving) _tracker.resume();
    await _tracker.complete(hadithId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) appRouteObserver.subscribe(this, route);
  }

  void _onTrackerChanged() {
    if (mounted) setState(() {});
  }

  // --- Tracking: leaving the screen / the app ---------------------------------

  /// Another screen opened on top of this one: stop counting.
  @override
  void didPushNext() => _tracker.pause();

  @override
  void didPopNext() {
    if (!_leaving) _tracker.resume();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // Not while the leave dialog is up: that time isn't reading.
        if (!_leaving) _tracker.resume();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _tracker.pause();
    }
  }

  /// The hadith in the middle of the list, i.e. the one being read.
  String? _focusedHadithId() {
    final list = _listKey.currentContext?.findRenderObject();
    if (list is! RenderBox || !list.attached || !list.hasSize) return null;
    final center = list.localToGlobal(Offset.zero).dy + list.size.height / 2;
    String? best;
    var bestDistance = list.size.height / 2;
    for (final id in _displayedIds) {
      final box = _cardKeys[id]?.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      final bottom = top + box.size.height;
      final distance = center < top
          ? top - center
          : center > bottom
          ? center - bottom
          : 0.0;
      if (distance <= bestDistance) {
        best = id;
        bestDistance = distance;
        if (distance == 0) break;
      }
    }
    return best;
  }

  bool _trackingTornDown = false;

  /// Releases everything the tracking holds: the timer, the route and app
  /// lifecycle subscriptions, and the scroll and tracker listeners. Called
  /// as soon as the user leaves (after the report, if any) and again from
  /// [dispose]; safe to run twice.
  void _teardownTracking() {
    if (_trackingTornDown) return;
    _trackingTornDown = true;
    appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _tracker
      ..removeListener(_onTrackerChanged)
      ..stop();
  }

  /// Back button / gesture. Collects every hadith read for more than
  /// [HadithReadingConfig.minSeconds] and not yet reported, and — if there
  /// are any — asks whether to mark them all as read. Yes reports them (one
  /// batched call); No reports nothing at all. Otherwise leaves straight
  /// away.
  Future<void> _handleExit() async {
    if (_leaving) return;
    _leaving = true;
    final candidates = hadithIsSignedIn
        ? _tracker.reportCandidates
        : const <String>[];
    if (candidates.isNotEmpty) {
      final hadiths = context.read<HadithDetailBloc>().state.hadiths;
      final numbers = <int>[];
      for (final id in candidates) {
        final number = hadiths
            .where((h) => h.id == id)
            .map((h) => h.hadithNumber)
            .firstOrNull;
        if (number != null && number != 0) numbers.add(number);
      }
      numbers.sort();
      // Time spent deciding is not reading time.
      _tracker.pause();
      final confirmed = await _askCompletedBatch(numbers);
      if (!mounted) return;
      if (confirmed == true) {
        // One report, then leave; give it a moment to land first.
        await _tracker
            .submit(candidates, completed: true)
            .timeout(
              const Duration(seconds: 4),
              onTimeout: () => HadithCompletion.failed,
            );
      }
    }
    // Reported (or nothing to report): nothing may keep running from here on.
    _teardownTracking();
    if (mounted) Navigator.of(context).pop();
  }

  Future<bool?> _askCompletedBatch(List<int> hadithNumbers) {
    final appText = AppText.readOf(context);
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.surfaceColor(Colors.white),
        title: Text(
          appText.hadithCompletedQuestion,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        content: hadithNumbers.isEmpty
            ? null
            : Text(
                '${appText.categoryHadith}: ${hadithNumbers.join(', ')}',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: dialogContext.inkColor(const Color(0xFF5D6B44)),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(appText.no),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF008000),
            ),
            child: Text(appText.yes),
          ),
        ],
      ),
    );
  }

  void _updateSettings(HadithContentSettings value) {
    setState(() => _settings = value);
    _settingsStore.save(value);
  }

  // --- Scrolling to the initial hadith ----------------------------------------

  /// The hadith to open on: by id, else by hadith number.
  HadithDetail? _findInitialTarget(List<HadithDetail> hadiths) {
    final id = widget.initialHadithId ?? '';
    final number = widget.initialHadithNumber ?? 0;
    if (id.isNotEmpty) {
      final byId = hadiths.where((h) => h.id == id).firstOrNull;
      if (byId != null) return byId;
    }
    if (number > 0) {
      return hadiths.where((h) => h.hadithNumber == number).firstOrNull;
    }
    return null;
  }

  /// Brings the card of [hadithId] to the top of the list.
  ///
  /// Cards are built lazily, so one far down has no context until the list
  /// has scrolled near it: jump to an estimate (then in steps toward it)
  /// until its card exists, and finish with [Scrollable.ensureVisible] for
  /// the exact position.
  Future<void> _scrollToHadith(String hadithId) async {
    const maxAttempts = 40;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      // Wait for the frame that lays out the list (and, after each jump, the
      // cards built for the new position).
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || !_scrollController.hasClients) return;

      final cardContext = _cardKeys[hadithId]?.currentContext;
      if (cardContext != null && cardContext.mounted) {
        await Scrollable.ensureVisible(cardContext, duration: Duration.zero);
        return;
      }

      final index = _displayedIds.indexOf(hadithId);
      if (index < 0) return;
      final position = _scrollController.position;
      final built = [
        for (var i = 0; i < _displayedIds.length; i++)
          if (_cardKeys[_displayedIds[i]]?.currentContext != null) i,
      ];
      double target;
      if (attempt == 0 || built.isEmpty) {
        // Average card extent (content / cards) times the target's index.
        final average =
            (position.maxScrollExtent + position.viewportDimension) /
            _displayedIds.length;
        target = average * index;
      } else if (index > built.last) {
        target = position.pixels + position.viewportDimension * .8;
      } else {
        target = position.pixels - position.viewportDimension * .8;
      }
      _scrollController.jumpTo(
        target.clamp(position.minScrollExtent, position.maxScrollExtent),
      );
    }
  }

  @override
  void dispose() {
    _teardownTracking();
    _tracker.dispose();
    _cardKeys.clear();
    _displayedIds = const [];
    _scrollController.dispose();
    _focusedId.dispose();
    _clock.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      // The bloc ignores this while a page is loading or after the last one.
      context.read<HadithDetailBloc>().add(const LoadMoreHadithDetails());
    }
  }

  /// The list area: a skeleton, a failure/empty message, or the hadiths
  /// themselves as a lazily-built [ListView.builder] (this list can run to
  /// hundreds of hadiths, so cards off-screen must not stay built).
  Widget _buildListBody({
    required HadithDetailState state,
    required AppText appText,
    required List<HadithDetail> hadiths,
    required bool searching,
    required bool seekingInitial,
    required String title,
  }) {
    if (state.isLoading || seekingInitial) {
      return const _CenteredList(child: _HadithSkeletons(count: 2));
    }
    if (state.status == HadithDetailStatus.failure) {
      return _CenteredList(
        child: Column(
          children: [
            _Message(state.failure?.message ?? ''),
            TextButton(
              onPressed: () => context.read<HadithDetailBloc>().add(
                LoadHadithDetails(
                  subCategoryId: widget.subCategoryId,
                  bookId: widget.bookId,
                  categoryId: widget.categoryId,
                  planId: widget.planId,
                ),
              ),
              child: Text(appText.tryAgain),
            ),
          ],
        ),
      );
    }
    if (hadiths.isEmpty && !(searching && state.hasMore)) {
      return _CenteredList(child: _Message(appText.noResultsFound));
    }

    // Loading-more skeleton, or a retry row for a failed page — whichever
    // applies, tacked on as one extra list item so the list itself stays a
    // single, lazily-built ListView.builder.
    Widget? footer;
    if (state.isLoadingMore || (searching && state.hasMore)) {
      footer = const _HadithSkeletons(count: 1);
    } else if (state.loadMoreFailure != null) {
      footer = Column(
        children: [
          _Message(state.loadMoreFailure!.message),
          TextButton(
            onPressed: () => context.read<HadithDetailBloc>().add(
              const LoadMoreHadithDetails(),
            ),
            child: Text(appText.tryAgain),
          ),
        ],
      );
    }

    return ListView.builder(
      key: _listKey,
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 28.h),
      itemCount: hadiths.length + (footer == null ? 0 : 1),
      itemBuilder: (context, index) {
        if (index >= hadiths.length) return footer!;
        final hadith = hadiths[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 14.h),
          child: HadithDetailCard(
            key: hadith.id.isEmpty
                ? null
                : _cardKeys.putIfAbsent(hadith.id, GlobalKey.new),
            hadith: hadith,
            bookName: title,
            settings: _settings,
            tracker: _tracker,
            focusedId: _focusedId,
            clock: _clock,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final state = context.watch<HadithDetailBloc>().state;
    // A first page too short to scroll would never fire the scroll listener,
    // so keep pulling pages until the list overflows (or runs out).
    if (state.status == HadithDetailStatus.success &&
        state.hasMore &&
        !state.isLoadingMore &&
        state.loadMoreFailure == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        if (_scrollController.position.maxScrollExtent <= 0) {
          context.read<HadithDetailBloc>().add(const LoadMoreHadithDetails());
        }
      });
    }

    // Opening on a given hadith: keep loading pages until it is in the list
    // (showing placeholders meanwhile), then scroll to it once it is laid out.
    var seekingInitial = false;
    if (_hasInitialTarget &&
        !_initialScrollHandled &&
        state.status == HadithDetailStatus.success) {
      final target = _findInitialTarget(state.hadiths);
      if (target != null && target.id.isNotEmpty) {
        _initialScrollHandled = true;
        _scrollToHadith(target.id);
      } else if (!state.hasMore) {
        _initialScrollHandled = true; // not in this list: stay at the top
      } else if (state.loadMoreFailure == null) {
        seekingInitial = true;
        if (!state.isLoadingMore) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<HadithDetailBloc>().add(
                const LoadMoreHadithDetails(),
              );
            }
          });
        }
      }
    }

    // Search matches the chapter and the section name. It only sees loaded
    // pages, so the auto-load above keeps pulling pages while few match.
    final query = _query.trim().toLowerCase();
    final hadiths = query.isEmpty
        ? state.hadiths
        : state.hadiths
              .where(
                (h) =>
                    h.chapter.toLowerCase().contains(query) ||
                    h.sectionNameBangla.toLowerCase().contains(query),
              )
              .toList();
    final searching = query.isNotEmpty;
    _displayedIds = [
      for (final h in hadiths)
        if (h.id.isNotEmpty) h.id,
    ];

    final title = (widget.title ?? '').isNotEmpty
        ? widget.title!
        : appText.categoryHadith;

    final listBody = _buildListBody(
      state: state,
      appText: appText,
      hadiths: hadiths,
      searching: searching,
      seekingInitial: seekingInitial,
      title: title,
    );

    return PopScope(
      // Back is handled by _handleExit (completion question + report).
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleExit();
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: context.pageColor(Colors.white),
        endDrawer: HadithContentSettingsDrawer(
          settings: _settings,
          onChanged: _updateSettings,
          onOpenProfileSettings: () {
            Navigator.of(context).pop(); // close the drawer
            Navigator.of(context).pushNamed(RouteNames.settings);
          },
        ),
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 6.h),
              _Header(
                title: title,
                onContentSettings: () =>
                    _scaffoldKey.currentState?.openEndDrawer(),
              ),
              SizedBox(height: 12.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: HadithSearchField(
                  hint: appText.searchHere,
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              SizedBox(height: 14.h),
              Expanded(child: listBody),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onContentSettings});

  final String title;

  /// Opens the content-settings drawer (Arabic / translation, font sizes).
  final VoidCallback onContentSettings;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 14.w, right: 10.w),
            child: IconButton(
              onPressed: () => Navigator.maybePop(context),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFCBD16B),
                foregroundColor: context.inkColor(Color(0xFF303629)),
                minimumSize: Size(38.r, 38.r),
              ),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.inkColor(Color(0xFF2C3320)),
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 14.w),
            child: IconButton(
              onPressed: onContentSettings,
              tooltip: AppText.of(context).quranReaderSettingsTitle,
              style: IconButton.styleFrom(
                backgroundColor: context.surfaceColor(Color(0xFFEDF1DE)),
                foregroundColor: context.inkColor(Color(0xFF4C5A34)),
                minimumSize: Size(38.r, 38.r),
              ),
              icon: const Icon(Icons.text_fields_rounded, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 40.h),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13.sp,
          color: context.inkColor(Color(0xFF5D6B44)),
        ),
      ),
    );
  }
}

/// Loading / failure / empty content, padded and scrollable the same way as
/// the main hadith list (just never large enough to need [ListView.builder]
/// itself).
class _CenteredList extends StatelessWidget {
  const _CenteredList({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 28.h),
      children: [child],
    );
  }
}

/// Shimmer placeholders shaped like [HadithDetailCard].
class _HadithSkeletons extends StatelessWidget {
  const _HadithSkeletons({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.surfaceColor(Color(0xFFE3ECC5)),
      highlightColor: context.surfaceColor(Color(0xFFF6F9EC)),
      child: Column(
        children: [
          for (var i = 0; i < count; i++) ...[
            Container(
              height: 340.h,
              decoration: BoxDecoration(
                color: context.surfaceColor(Colors.white),
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            SizedBox(height: 14.h),
          ],
        ],
      ),
    );
  }
}

/// One hadith as a card: Arabic text, translation, reference, grade and
/// source, with the bookmark and copy / share / report buttons.
class HadithDetailCard extends StatefulWidget {
  const HadithDetailCard({
    super.key,
    required this.hadith,
    required this.bookName,
    required this.settings,
    this.tracker,
    this.focusedId,
    this.clock,
  });

  final HadithDetail hadith;
  final HadithContentSettings settings;

  /// Name of the book / sub-category on screen, used in the report mail.
  final String bookName;

  /// Holds how long each hadith has been read, for the timer circle. Null
  /// where there is no reading tracker (e.g. the offline saved reader), in
  /// which case no timer circle shows.
  final HadithReadingTracker? tracker;

  /// Id of the hadith currently in focus (see [_HadithDetailViewState]).
  final ValueListenable<String?>? focusedId;

  /// Ticks once a second so the timer circle refreshes.
  final ValueListenable<int>? clock;

  @override
  State<HadithDetailCard> createState() => _HadithDetailCardState();
}

class _HadithDetailCardState extends State<HadithDetailCard> {
  static const _ink = Color(0xFF283016);
  static const _muted = Color(0xFF5D6B44);
  static const _tint = Color(0xFFE6EFE3);
  static const _green = Color(0xFF008000);
  static const _reportEmail = 'report.tuhfatulmuslim@gmail.com';

  final GlobalKey _boundaryKey = GlobalKey();

  /// Which language the card shows; the button next to the number flips it.
  bool _showEnglish = false;

  HadithDetail get hadith => widget.hadith;
  HadithContentSettings get settings => widget.settings;

  final _bookmarkStore = HadithBookmarkStore();

  /// Whether the hadith is filed under at least one bookmark folder.
  bool _bookmarked = false;

  /// Identity of this hadith in the local bookmark tables. Online hadiths have
  /// no book slug, so the API id (unique across every book) stands in.
  String get _bookmarkSlug =>
      'api:${hadith.id.isNotEmpty ? hadith.id : hadith.hadithNumber}';

  @override
  void initState() {
    super.initState();
    _loadBookmarked();
  }

  Future<void> _loadBookmarked() async {
    final folders = await _bookmarkStore.foldersFor(
      _bookmarkSlug,
      hadith.hadithNumber,
    );
    if (mounted) setState(() => _bookmarked = folders.isNotEmpty);
  }

  /// Label under which the hadith shows in the Saved screen.
  String get _bookmarkTitle {
    for (final candidate in [
      hadith.titleBangla,
      hadith.titleEnglish,
      hadith.chapter,
      hadith.textBangla,
      hadith.textEnglish,
    ]) {
      if (candidate.trim().isNotEmpty) {
        final text = candidate.trim();
        return text.length > 90 ? '${text.substring(0, 90)}…' : text;
      }
    }
    return '';
  }

  /// "Book Mark" bottom sheet: file the hadith under one or more folders.
  Future<void> _showBookmarkSheet() async {
    final appText = _appText;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HadithBookmarkSheet(
        appText: appText,
        bookmark: HadithBookmark(
          bookSlug: _bookmarkSlug,
          hadithNo: hadith.hadithNumber,
          titleAr: '',
          titleBn: _bookmarkTitle,
          savedAt: DateTime.now(),
          payload: jsonEncode(hadith.toJson()),
        ),
      ),
    );
    if (saved != true || !mounted) return;
    await _loadBookmarked();
    _toast(appText.hadithBookmarkAdded);
  }

  /// [english] when English is on and available, otherwise [bangla] (and the
  /// other way round when one of them is empty).
  String _pick(String bangla, String english) {
    final preferred = _showEnglish ? english : bangla;
    return preferred.isNotEmpty ? preferred : (_showEnglish ? bangla : english);
  }

  /// For tap handlers, where [AppText.of] (which listens) is not allowed.
  AppText get _appText =>
      AppText.forLanguage(context.read<LanguageBloc>().state.language);

  /// Narrator and translation in the language the card currently shows.
  String get _translationText {
    final buffer = StringBuffer();
    if (!_showEnglish && hadith.narrator.isNotEmpty) {
      buffer.writeln(hadith.narrator);
    }
    final text = _pick(hadith.textBangla, hadith.textEnglish);
    if (text.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln(text);
    }
    return buffer.toString().trim();
  }

  /// Title, Arabic, narrator, translation and reference as plain text.
  String get _plainText {
    final buffer = StringBuffer();
    final title = _pick(hadith.titleBangla, hadith.titleEnglish);
    if (title.isNotEmpty) buffer.writeln('${hadith.hadithNumber}. $title');
    if (hadith.textArabic.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(hadith.textArabic);
    }
    final translation = _translationText;
    if (translation.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(translation);
    }
    if (hadith.takhrij.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(hadith.takhrij);
    }
    return buffer.toString().trim();
  }

  String get _shareSubject => _pick(hadith.titleBangla, hadith.titleEnglish);

  Rect? get _originRect {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  Future<void> _copyValue(String text) async {
    if (text.isEmpty) return;
    final copied = _appText.hadithCopied;
    await Clipboard.setData(ClipboardData(text: text));
    _toast(copied);
  }

  Future<void> _shareScreenshot() async {
    final failed = _appText.hadithShareFailed;
    try {
      final boundary =
          _boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/hadith_${hadith.id}.png');
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: _shareSubject,
          sharePositionOrigin: _originRect,
        ),
      );
    } catch (_) {
      _toast(failed);
    }
  }

  Future<void> _report() async {
    final appText = _appText;
    final subject =
        '${appText.hadithReport}: ${widget.bookName} — '
        '${appText.categoryHadith} ${hadith.hadithNumber}';
    final body =
        '${appText.hadithReportMessage}'
        '${appText.hadithBookReference}: ${widget.bookName}\n'
        '${appText.categoryHadith}: ${hadith.hadithNumber}\n\n'
        '$_plainText';
    final uri = Uri.parse(
      'mailto:$_reportEmail'
      '?subject=${Uri.encodeComponent(subject)}'
      '&body=${Uri.encodeComponent(body)}',
    );
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) _toast(appText.hadithReportFailed);
    } catch (_) {
      _toast(appText.hadithReportFailed);
    }
  }

  /// Bottom sheet with the per-hadith copy / share / report actions.
  void _showActions(BuildContext buttonContext) {
    final appText = _appText;
    showModalBottomSheet<void>(
      context: buttonContext,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetContext) {
        Widget tile({
          required IconData icon,
          required String label,
          required VoidCallback onTap,
          Color color = const Color(0xFF4C5A34),
        }) {
          return ListTile(
            leading: Icon(icon, color: context.inkColor(color)),
            title: Text(
              label,
              style: TextStyle(color: context.inkColor(color)),
            ),
            onTap: () {
              Navigator.pop(sheetContext);
              onTap();
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: context.surfaceColor(Color(0xFFDCE3C4)),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 6.h),
              if (_translationText.isNotEmpty)
                tile(
                  icon: Icons.translate_rounded,
                  label: appText.hadithCopyTranslation,
                  onTap: () => _copyValue(_translationText),
                ),
              if (hadith.textArabic.isNotEmpty)
                tile(
                  icon: Icons.menu_book_rounded,
                  label: appText.hadithCopyArabic,
                  onTap: () => _copyValue(hadith.textArabic),
                ),
              tile(
                icon: Icons.copy_rounded,
                label: appText.hadithCopyFull,
                onTap: () => _copyValue(_plainText),
              ),
              tile(
                icon: Icons.ios_share_rounded,
                label: appText.hadithShareScreenshot,
                onTap: _shareScreenshot,
              ),
              tile(
                icon: Icons.flag_outlined,
                label: appText.hadithReport,
                color: const Color(0xFFC15B4B),
                onTap: _report,
              ),
              SizedBox(height: 8.h),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final grade = _pick(hadith.gradeBangla, hadith.grade);
    final source = _pick(hadith.sourceBangla, hadith.sourceEnglish);
    final author = _pick(hadith.authorBangla, hadith.authorEnglish);
    final title = _pick(hadith.titleBangla, hadith.titleEnglish);
    final text = _pick(hadith.textBangla, hadith.textEnglish);

    final card = Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: context.surfaceColor(Colors.white),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.lineColor(Color(0xFFE3E7D3))),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: context.surfaceColor(_green),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '${hadith.hadithNumber}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (widget.tracker != null &&
                    widget.focusedId != null &&
                    widget.clock != null) ...[
                  SizedBox(width: 8.w),
                  _HadithTimerBadge(
                    hadithId: hadith.id,
                    tracker: widget.tracker!,
                    focusedId: widget.focusedId!,
                    clock: widget.clock!,
                  ),
                ],
                const Spacer(),
                if (hadith.textEnglish.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _showEnglish = !_showEnglish),
                    icon: Icon(Icons.translate_rounded, size: 16.sp),
                    // Names the language a tap switches to.
                    label: Text(_showEnglish ? 'বাংলা' : 'English'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.inkColor(_green),
                      backgroundColor: context.surfaceColor(Colors.white),
                      side: BorderSide(color: context.lineColor(_green)),
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      minimumSize: Size(0, 30.h),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                    ),
                  ),
                // Room for the overlaid bookmark and menu buttons.
                SizedBox(width: 76.w),
              ],
            ),
            if (title.isNotEmpty && settings.showTranslation) ...[
              SizedBox(height: 12.h),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.sp * settings.translationScale,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: context.inkColor(_muted),
                ),
              ),
            ],
            if (hadith.textArabic.isNotEmpty && settings.showArabic) ...[
              SizedBox(height: 14.h),
              Text(
                hadith.textArabic,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 20.sp * settings.arabicScale,
                  height: 2.0,
                  color: context.inkColor(_ink),
                ),
              ),
            ],
            // The English text already opens with its narrator.
            if (settings.showTranslation &&
                !_showEnglish &&
                hadith.narrator.isNotEmpty) ...[
              SizedBox(height: 14.h),
              Text(
                hadith.narrator,
                style: TextStyle(
                  fontSize: 12.5.sp * settings.translationScale,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                  color: context.inkColor(Color(0xFF8B9A4B)),
                ),
              ),
            ],
            if (text.isNotEmpty && settings.showTranslation) ...[
              SizedBox(height: 8.h),
              Text(
                text,
                style: TextStyle(
                  fontSize: 14.sp * settings.translationScale,
                  height: 1.7,
                  color: context.inkColor(_ink),
                ),
              ),
            ],
            if (hadith.takhrij.isNotEmpty) ...[
              SizedBox(height: 14.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: context.surfaceColor(_tint),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: context.lineColor(Color(0xFFD5E2D0)),
                  ),
                ),
                child: Text(
                  hadith.takhrij,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    height: 1.6,
                    color: context.inkColor(_ink),
                  ),
                ),
              ),
            ],
            SizedBox(height: 14.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: context.surfaceColor(_tint),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Wrap(
                spacing: 12.w,
                runSpacing: 8.h,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (grade.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF008000),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        grade,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (source.isNotEmpty) _FooterText(source),
                  if (author.isNotEmpty) _FooterText(author),
                  if (hadith.sectionNameBangla.isNotEmpty)
                    _FooterText(hadith.sectionNameBangla),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Stack(
      children: [
        RepaintBoundary(key: _boundaryKey, child: card),
        // Outside the boundary so the menu button is not in the screenshot.
        PositionedDirectional(
          top: 14.r,
          end: 14.r,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BookmarkButton(
                tooltip: AppText.of(context).hadithBookmark,
                bookmarked: _bookmarked,
                onTap: _showBookmarkSheet,
              ),
              SizedBox(width: 6.w),
              Builder(
                builder: (buttonContext) => _MoreButton(
                  tooltip: AppText.of(context).hadithCopy,
                  onTap: () => _showActions(buttonContext),
                ),
              ),
            ],
          ),
        ),
        if (widget.tracker != null && widget.clock != null)
          PositionedDirectional(
            bottom: 10.r,
            end: 10.r,
            child: _HadithCompleteCheckbox(
              hadithId: hadith.id,
              tracker: widget.tracker!,
              clock: widget.clock!,
            ),
          ),
      ],
    );
  }
}

class _BookmarkButton extends StatelessWidget {
  const _BookmarkButton({
    required this.tooltip,
    required this.bookmarked,
    required this.onTap,
  });

  final String tooltip;
  final bool bookmarked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9.r),
        child: Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: context.surfaceColor(
              bookmarked ? const Color(0xFF8B9A4B) : const Color(0xFFECF0DC),
            ),
            borderRadius: BorderRadius.circular(9.r),
            border: Border.all(color: context.lineColor(Color(0xFFDCE3C4))),
          ),
          child: Icon(
            bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            size: 16.sp,
            color: bookmarked
                ? Colors.white
                : context.inkColor(const Color(0xFF4C5A34)),
          ),
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9.r),
        child: Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: context.surfaceColor(Color(0xFFECF0DC)),
            borderRadius: BorderRadius.circular(9.r),
            border: Border.all(color: context.lineColor(Color(0xFFDCE3C4))),
          ),
          child: Icon(
            Icons.more_vert_rounded,
            size: 16.sp,
            color: context.inkColor(Color(0xFF4C5A34)),
          ),
        ),
      ),
    );
  }
}

/// Per-hadith reading timer: a small ring that fills over a minute and
/// resets, with the elapsed time in its center. Green and filling while
/// [hadithId] is the one in focus, grey and frozen while it's not — so
/// scrolling away visibly pauses it and scrolling back resumes it where it
/// left off. Once reported (see [HadithReadingTracker.isCompleted]), it
/// turns into a static checkmark: the timer has stopped for good.
class _HadithTimerBadge extends StatelessWidget {
  const _HadithTimerBadge({
    required this.hadithId,
    required this.tracker,
    required this.focusedId,
    required this.clock,
  });

  final String hadithId;
  final HadithReadingTracker tracker;
  final ValueListenable<String?> focusedId;
  final ValueListenable<int> clock;

  @override
  Widget build(BuildContext context) {
    if (hadithId.isEmpty) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: Listenable.merge([focusedId, clock, tracker]),
      builder: (context, _) => _TimerCircle(
        seconds: tracker.dwellSeconds(hadithId),
        active: focusedId.value == hadithId,
        completed: tracker.isCompleted(hadithId),
      ),
    );
  }
}

class _TimerCircle extends StatelessWidget {
  const _TimerCircle({
    required this.seconds,
    required this.active,
    required this.completed,
  });

  final int seconds;
  final bool active;
  final bool completed;

  /// The ring completes one lap per minute of reading.
  static const _lapSeconds = 60;

  static const _active = Color(0xFF008000);
  static const _idle = Color(0xFF9AA583);

  String get _label {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return minutes > 0
        ? '$minutes:${secs.toString().padLeft(2, '0')}'
        : '$secs';
  }

  @override
  Widget build(BuildContext context) {
    // Nothing spent on this hadith yet and it's not the one in focus: no
    // badge to show.
    if (seconds <= 0 && !active && !completed) return const SizedBox.shrink();
    final color = completed || active ? _active : _idle;
    return Tooltip(
      message: completed ? 'Read' : (active ? 'Reading…' : 'Paused'),
      child: SizedBox(
        width: 30.r,
        height: 30.r,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 30.r,
              height: 30.r,
              child: CircularProgressIndicator(
                // Frozen full once done, otherwise the current lap.
                value: completed ? 1 : (seconds % _lapSeconds) / _lapSeconds,
                strokeWidth: 2.5,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            if (completed)
              Icon(Icons.check_rounded, size: 14.sp, color: color)
            else
              Padding(
                // Keeps the label off the ring; FittedBox shrinks it instead
                // of overflowing once minutes reach two digits (10+ minutes).
                padding: EdgeInsets.all(5.r),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w700,
                      color: color,
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

/// The "Yes" checkbox that appears bottom-right of a card once
/// [hadithId] has been read for more than [HadithReadingConfig.minSeconds] —
/// checking it reports that hadith as completed right away (the same POST
/// the 5-minute dialog and the leave dialog use), after which the checkbox
/// shows checked and disabled and the timer above has stopped.
class _HadithCompleteCheckbox extends StatelessWidget {
  const _HadithCompleteCheckbox({
    required this.hadithId,
    required this.tracker,
    required this.clock,
  });

  final String hadithId;
  final HadithReadingTracker tracker;
  final ValueListenable<int> clock;

  @override
  Widget build(BuildContext context) {
    if (hadithId.isEmpty) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: Listenable.merge([clock, tracker]),
      builder: (context, _) {
        final completed = tracker.isCompleted(hadithId);
        final completing = tracker.isCompleting(hadithId);
        final eligible =
            tracker.dwellSeconds(hadithId) > HadithReadingConfig.minSeconds;
        if (!completed && !eligible) return const SizedBox.shrink();
        return _YesCheckbox(
          checked: completed,
          busy: completing,
          onTap: completed || completing
              ? null
              : () async {
                  if (!await ensureHadithLogin(context)) return;
                  tracker.complete(hadithId);
                },
        );
      },
    );
  }
}

class _YesCheckbox extends StatelessWidget {
  const _YesCheckbox({required this.checked, required this.busy, this.onTap});

  final bool checked;
  final bool busy;
  final VoidCallback? onTap;

  static const _green = Color(0xFF008000);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: context.surfaceColor(
              checked ? _green : const Color(0xFFECF0DC),
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: context.lineColor(
                checked ? _green : const Color(0xFFDCE3C4),
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                SizedBox(
                  width: 12.r,
                  height: 12.r,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation(
                      checked ? Colors.white : _green,
                    ),
                  ),
                )
              else
                Icon(
                  checked
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: 14.sp,
                  color: checked
                      ? Colors.white
                      : context.inkColor(const Color(0xFF4C5A34)),
                ),
              SizedBox(width: 4.w),
              Text(
                AppText.of(context).yes,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: checked
                      ? Colors.white
                      : context.inkColor(const Color(0xFF4C5A34)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterText extends StatelessWidget {
  const _FooterText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.sp,
        height: 1.4,
        color: context.inkColor(Color(0xFF5D6B44)),
      ),
    );
  }
}
