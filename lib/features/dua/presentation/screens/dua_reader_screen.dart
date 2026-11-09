import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';

import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/dua/data/dua_bookmark_store.dart';
import 'package:tuhfatul_muslim/features/dua/data/dua_catalog.dart';
import 'package:tuhfatul_muslim/features/dua/data/repositories/dua_reading_repository_impl.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/controllers/dua_reading_tracker.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/dua_login_dialog.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/dua_route_args.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/bloc/dua_settings/dua_settings_bloc.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_bookmark_sheet.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_page_header.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_text_zoom.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_zoom_control.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/core/theme/app_typography.dart';

const _tuhfatulMuslimPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.tuhfatulmuslim.app&pcampaignid=web_share';
const _tuhfatulMuslimShareInvitation =
    'Discover more daily Duas with Tuhfatul Muslim.';

/// Single-dua reader (design `devImg/img_19.png`), reached by tapping a dua
/// row on [DuaGroupScreen] / [DuaAllDuaScreen].
///
/// The recitation counter is in-memory and resets when the screen is left;
/// the bookmark icon opens [DuaBookmarkSheet]. The play icon has no audio
/// yet, so it isn't wired.
///
/// Opening the screen starts a reading timer ([DuaReadingTracker]), shown in
/// the header's top-right corner. Past half a minute — the least
/// `POST /duas/reading/track` accepts — a "Read / Completed" checkbox
/// appears; checking it reports the time and stops the timer. Leaving the
/// screen reports it too, so each visit counts exactly once and the next one
/// starts from zero while the day's total keeps adding up.
///
/// Checking the box is permanent: a dua marked read opens with its box
/// already checked and its recorded duration shown, and no timer runs for it
/// again.
///
/// Those same three texts are selectable: a long press puts the handles and
/// the platform's own Copy menu on the one that was pressed, so any part of
/// it can be taken. Everything else on the page stays plain, unselectable
/// text.
///
/// A two-finger pinch anywhere on the page resizes the three reading texts —
/// the Arabic, the Bangla pronunciation and the Bangla translation — and
/// nothing else: the title, the header, the cards and every label keep their
/// own size. The pinch moves the very sizes the settings sheet's sliders
/// hold, so where it is let go is where it stays, this visit and the next.
class DuaReaderScreen extends StatelessWidget {
  const DuaReaderScreen({super.key, required this.args});

  final DuaReaderArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DuaSettingsBloc()..add(const LoadDuaSettings()),
      child: _DuaReaderView(args: args),
    );
  }
}

class _DuaReaderView extends StatefulWidget {
  const _DuaReaderView({required this.args});

  final DuaReaderArgs args;

  @override
  State<_DuaReaderView> createState() => _DuaReaderViewState();
}

class _DuaReaderViewState extends State<_DuaReaderView>
    with WidgetsBindingObserver {
  /// Reports how long this dua is read. Null for the legacy mock catalog's
  /// demo duas: they have no `_id` the API would accept.
  DuaReadingTracker? _reading;

  /// Whether the bottom recite bar (counter, reset, bookmark, play) shows.
  /// It is off for now; set it to `true` to bring the bar back, which is why
  /// its widget and the counter state below are kept. Not `const`, so the
  /// bar's code stays referenced rather than reading as dead code.
  final bool _showReciteBar = false;

  /// How many times the dua has been recited this visit — the bottom bar's
  /// counter pill (design `img_19.png`); resets when the screen is left.
  int _count = 0;

  void _incrementCount() => setState(() => _count++);
  void _resetCount() => setState(() => _count = 0);

  /// The reading sizes the live pinch started from. Null when none is
  /// running.
  ({double arabic, double translation})? _pinchFrom;

  /// The reading sizes the pinch has reached, shown in place of the saved
  /// ones until the settings carry them (see [_onSettingsChanged]).
  ({double arabic, double translation})? _pinchSizes;

  /// The Arabic size to draw with: the live pinch's, else the saved one.
  double _arabicFontSize(DuaSettingsState settings) =>
      _pinchSizes?.arabic ?? settings.arabicFontSize;

  /// The size the Bangla pronunciation and translation are drawn with.
  double _translationFontSize(DuaSettingsState settings) =>
      _pinchSizes?.translation ?? settings.translationFontSize;

  /// A pinch begins from the size on screen — the one a previous pinch
  /// reached if its commit has not come back yet — so resuming one never
  /// jumps.
  void _onZoomStart() {
    final settings = context.read<DuaSettingsBloc>().state;
    _pinchFrom =
        _pinchSizes ??
        (
          arabic: settings.arabicFontSize,
          translation: settings.translationFontSize,
        );
  }

  /// Resizes the reading text as the fingers move. Local state, so the
  /// pinch follows them at frame rate and nothing is saved mid-gesture.
  void _onZoomUpdate(double scale) {
    final from = _pinchFrom;
    if (from == null) return;
    final sizes = duaZoomedFontSizes(
      arabic: from.arabic,
      translation: from.translation,
      scale: scale,
    );
    if (sizes == _pinchSizes) return;
    setState(() => _pinchSizes = sizes);
  }

  /// Keeps the size the pinch reached the way the sliders keep theirs: one
  /// event, so both sizes land together, saved for the next visit too.
  void _onZoomEnd() {
    final sizes = _pinchSizes;
    _pinchFrom = null;
    if (sizes == null) return;
    context.read<DuaSettingsBloc>().add(
      SetDuaFontSizes(arabic: sizes.arabic, translation: sizes.translation),
    );
  }

  /// Drops the live sizes once the settings hold them, so later changes —
  /// the sliders, or a reload — are what the reader draws from again. While
  /// a pinch is running the live sizes stay in charge.
  void _onSettingsChanged(DuaSettingsState settings) {
    final sizes = _pinchSizes;
    if (sizes == null || _pinchFrom != null) return;
    if (settings.arabicFontSize == sizes.arabic &&
        settings.translationFontSize == sizes.translation) {
      setState(() => _pinchSizes = null);
    }
  }

  @override
  void initState() {
    super.initState();
    final duaId = widget.args.featuredModel?.id ?? '';
    if (duaId.isEmpty) return;
    WidgetsBinding.instance.addObserver(this);
    _reading = DuaReadingTracker(DuaReadingRepositoryImpl.shared, duaId: duaId)
      ..start();
  }

  @override
  void dispose() {
    final reading = _reading;
    if (reading != null) {
      WidgetsBinding.instance.removeObserver(this);
      // Leaving the screen reports what was read, whether or not the
      // checkbox was used; the request outlives this widget, and seconds
      // the checkbox already reported are not sent again.
      unawaited(reading.finish());
      reading.dispose();
    }
    super.dispose();
  }

  /// Only foreground time is reading time.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _reading?.resume();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _reading?.pause();
    }
  }

  /// The "Read / Completed" checkbox: reports the time read so far and
  /// stops the timer. Tracking needs the signed-in user's token, so a guest
  /// is asked to sign in first and nothing is reported for them.
  Future<void> _markAsRead() async {
    final reading = _reading;
    if (reading == null || reading.isCompleted || reading.isSubmitting) return;
    if (!reading.canReport) {
      await showDuaLoginRequiredDialog(context);
      return;
    }
    await reading.complete();
  }

  /// Unifies a real `/duas/featured` item and the legacy mock [DuaDetail]
  /// into one shape the view below renders, resolving bilingual fields in
  /// the app's current language.
  _DuaReadable _readable(BuildContext context) {
    final model = widget.args.featuredModel;
    if (model != null) {
      final categoryName = context.localized(model.category?.name);
      final title = context.localized(model.title);
      return _DuaReadable(
        categoryLabel: categoryName.isNotEmpty
            ? categoryName
            : widget.args.featured?.groupLabel ?? '',
        name: title,
        segments: [
          DuaSegment(
            arabic: model.arabic,
            translation: context.localized(model.translation),
          ),
        ],
        transliteration: context.localized(model.transliteration),
        repeatCount: model.recommendedRepeatCount > 0
            ? model.recommendedRepeatCount
            : null,
        reference: context.localized(model.reference),
        instruction: context.localized(model.instruction),
        virtue: context.localized(model.virtue),
      );
    }
    final detail = widget.args.detail!;
    return _DuaReadable(
      categoryLabel: widget.args.featured!.groupLabel,
      name: detail.name,
      segments: detail.segments,
      transliteration: detail.transliteration,
      repeatCount: detail.repeatCount,
      reference: '',
      instruction: '',
      virtue: '',
    );
  }

  /// The dua's own `_id`, or `mock:<name>` for the legacy catalog's demo
  /// duas — stable per-dua key used by [DuaBookmarkStore].
  String get _duaId {
    final model = widget.args.featuredModel;
    if (model != null) return model.id;
    return 'mock:${widget.args.detail!.name}';
  }

  /// Snapshots the current dua (bilingually, not just the resolved display
  /// language) for [folder], so it renders correctly later regardless of
  /// the app's language when it's reopened from Saved.
  DuaBookmarkModel _buildSnapshot(String folder) {
    final model = widget.args.featuredModel;
    final now = DateTime.now();
    if (model != null) {
      return DuaBookmarkModel(
        duaId: model.id,
        folder: folder,
        titleBn: model.title.bn ?? model.title.en ?? '',
        titleEn: model.title.en ?? model.title.bn ?? '',
        arabic: model.arabic,
        transliterationBn:
            model.transliteration.bn ?? model.transliteration.en ?? '',
        transliterationEn:
            model.transliteration.en ?? model.transliteration.bn ?? '',
        translationBn: model.translation.bn ?? model.translation.en ?? '',
        translationEn: model.translation.en ?? model.translation.bn ?? '',
        referenceBn: model.reference.bn ?? '',
        referenceEn: model.reference.en ?? '',
        categoryNameBn: model.category?.name.bn ?? '',
        categoryNameEn: model.category?.name.en ?? '',
        recommendedRepeatCount: model.recommendedRepeatCount,
        createdAt: now,
        iconUrl: model.iconUrl ?? model.category?.iconUrl,
      );
    }
    final detail = widget.args.detail!;
    final segment = detail.segments.isNotEmpty ? detail.segments.first : null;
    return DuaBookmarkModel(
      duaId: _duaId,
      folder: folder,
      titleBn: detail.name,
      titleEn: detail.name,
      arabic: segment?.arabic ?? '',
      transliterationBn: detail.transliteration,
      transliterationEn: detail.transliteration,
      translationBn: segment?.translation ?? '',
      translationEn: segment?.translation ?? '',
      referenceBn: '',
      referenceEn: '',
      categoryNameBn: widget.args.featured?.groupLabel ?? '',
      categoryNameEn: widget.args.featured?.groupLabel ?? '',
      recommendedRepeatCount: detail.repeatCount ?? 1,
      createdAt: now,
    );
  }

  Future<void> _showBookmarkSheet() async {
    final appText = AppText.forLanguage(
      context.read<LanguageBloc>().state.language,
    );
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DuaBookmarkSheet(
        appText: appText,
        duaId: _duaId,
        buildSnapshot: _buildSnapshot,
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appText.duaBookmarkAdded),
          duration: const Duration(milliseconds: 1200),
        ),
      );
    }
  }

  /// Every available reader section as plain text — for sharing all Dua
  /// content from the app-bar share chooser.
  String _plainText(BuildContext context) {
    final readable = _readable(context);
    final buffer = StringBuffer();
    if (readable.name.isNotEmpty) buffer.writeln(readable.name);
    final arabic = readable.segments
        .map((s) => s.arabic)
        .where((a) => a.isNotEmpty)
        .join('\n');
    if (arabic.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(arabic);
    }
    if (readable.transliteration.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(readable.transliteration);
    }
    final translation = readable.segments
        .map((s) => s.translation)
        .where((t) => t.isNotEmpty)
        .join('\n');
    if (translation.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(translation);
    }
    if (readable.reference.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(readable.reference);
    }
    if (readable.instruction.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(readable.instruction);
    }
    if (readable.virtue.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(readable.virtue);
    }
    return buffer.toString().trim();
  }

  Future<void> _showCopySheet() async {
    final appText = AppText.of(context);
    final copied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DuaCopySheet(readable: _readable(context)),
    );
    if (copied != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(appText.duaCopied),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  Future<void> _showShareSheet() async {
    final appText = AppText.of(context);
    final readable = _readable(context);
    final part = await showModalBottomSheet<_DuaSharePart>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DuaShareSheet(readable: readable),
    );
    if (part == null || !mounted) return;
    await _shareText(_shareTextFor(readable, part), readable.name, appText);
  }

  String _shareTextFor(_DuaReadable readable, _DuaSharePart part) {
    switch (part) {
      case _DuaSharePart.all:
        return _plainText(context);
      case _DuaSharePart.name:
        return readable.name;
      case _DuaSharePart.guidanceAndVirtue:
        return [
          readable.instruction,
          readable.virtue,
        ].where((text) => text.isNotEmpty).join('\n\n');
      case _DuaSharePart.transliteration:
        return readable.transliteration;
      case _DuaSharePart.reference:
        return readable.reference;
    }
  }

  Future<void> _shareText(String text, String subject, AppText appText) async {
    final shareText = text.trim();
    if (shareText.isEmpty) return;
    final message = [
      shareText,
      _tuhfatulMuslimShareInvitation,
      _tuhfatulMuslimPlayStoreUrl,
    ].join('\n\n');
    try {
      final box = context.findRenderObject();
      await SharePlus.instance.share(
        ShareParams(
          text: message,
          subject: subject,
          sharePositionOrigin: box is RenderBox
              ? box.localToGlobal(Offset.zero) & box.size
              : null,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(appText.duaShareFailed)));
    }
  }

  void _showSettingsModal() {
    final appText = AppText.of(context);
    final settingsBloc = context.read<DuaSettingsBloc>();
    final pageContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor(Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return BlocProvider.value(
          value: settingsBloc,
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 28.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: IconButton.styleFrom(
                            backgroundColor: context.surfaceColor(
                              const Color(0xFFF1F1E4),
                            ),
                            foregroundColor: context.inkColor(
                              const Color(0xFF303629),
                            ),
                            minimumSize: Size(34.r, 34.r),
                          ),
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          appText.duaSettingsTitle,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: context.inkColor(const Color(0xFF2C3320)),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    _SettingsSectionHeader(
                      title: appText.duaDisplayReadingStyleSection,
                    ),
                    SizedBox(height: 10.h),
                    BlocBuilder<DuaSettingsBloc, DuaSettingsState>(
                      builder: (context, state) {
                        return Container(
                          padding: EdgeInsets.all(14.r),
                          decoration: BoxDecoration(
                            color: context.surfaceColor(Colors.white),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: context.lineColor(const Color(0xFFE3E7D3)),
                            ),
                          ),
                          child: Column(
                            children: [
                              _SettingsToggleRow(
                                icon: Icons.menu_book_rounded,
                                iconBg: const Color(0xFFF3DCC4),
                                iconColor: const Color(0xFFB07A2E),
                                title: appText.duaNarrationToggleTitle,
                                subtitle: appText.duaNarrationToggleSubtitle,
                                value: state.showNarration,
                                onChanged: (val) => context
                                    .read<DuaSettingsBloc>()
                                    .add(ToggleDuaNarration(val)),
                              ),
                              Divider(height: 28.h),
                              _SettingsToggleRow(
                                icon: Icons.menu_book_outlined,
                                iconBg: const Color(0xFFE3DAF5),
                                iconColor: const Color(0xFF7C5FC4),
                                title: appText.showArabicLabel,
                                subtitle: appText.duaArabicToggleSubtitle,
                                value: state.showArabic,
                                onChanged: (val) => context
                                    .read<DuaSettingsBloc>()
                                    .add(ToggleDuaArabic(val)),
                              ),
                              Divider(height: 28.h),
                              _SettingsToggleRow(
                                icon: Icons.translate_rounded,
                                iconBg: const Color(0xFFFBDFE6),
                                iconColor: const Color(0xFFB0527A),
                                title: appText.showTranslationLabel,
                                subtitle: appText.duaTranslationToggleSubtitle,
                                value: state.showTranslation,
                                onChanged: (val) => context
                                    .read<DuaSettingsBloc>()
                                    .add(ToggleDuaTranslation(val)),
                              ),
                              Divider(height: 28.h),
                              _SettingsToggleRow(
                                icon: Icons.record_voice_over_rounded,
                                iconBg: const Color(0xFFDCEEC0),
                                iconColor: const Color(0xFF2F6B3C),
                                title: appText.showTransliterationLabel,
                                subtitle:
                                    appText.duaTransliterationToggleSubtitle,
                                value: state.showTransliteration,
                                onChanged: (val) => context
                                    .read<DuaSettingsBloc>()
                                    .add(ToggleDuaTransliteration(val)),
                              ),
                              Divider(height: 28.h),
                              _SettingsToggleRow(
                                icon: Icons.description_rounded,
                                iconBg: const Color(0xFFFBF0DD),
                                iconColor: const Color(0xFFD08A3E),
                                title: appText.duaReferenceToggleTitle,
                                subtitle: appText.duaReferenceToggleSubtitle,
                                value: state.showReference,
                                onChanged: (val) => context
                                    .read<DuaSettingsBloc>()
                                    .add(ToggleDuaReference(val)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 22.h),
                    _SettingsSectionHeader(
                      title: appText.duaTypographyStylingSection,
                    ),
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: context.surfaceColor(Colors.white),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: context.lineColor(const Color(0xFFE3E7D3)),
                        ),
                      ),
                      child: const DuaFontSizeControls(),
                    ),
                    SizedBox(height: 16.h),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.settings_outlined),
                      title: Text(appText.settingsTitle),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(
                          pageContext,
                        ).pushNamed(RouteNames.settings);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final readable = _readable(context);

    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: BlocConsumer<DuaSettingsBloc, DuaSettingsState>(
        listener: (context, settings) => _onSettingsChanged(settings),
        builder: (context, settings) {
          return Stack(
            children: [
              // Two fingers resize the reading text; one finger is left to
              // the list, which scrolls and taps exactly as before.
              DuaTextZoomDetector(
                onZoomStart: _onZoomStart,
                onZoomUpdate: _onZoomUpdate,
                onZoomEnd: _onZoomEnd,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    16.w,
                    0,
                    16.w,
                    // Room for the floating recite bar while it shows; just
                    // breathing space under the last card while it doesn't.
                    (_showReciteBar ? 96.h : 24.h) + bottomInset,
                  ),
                  children: [
                    SizedBox(height: 36.h),
                    DuaPageHeader(
                      // Keep the app-bar title fixed; the dua's full name is
                      // shown in the reading content below.
                      title: appText.duaIntroTitle,
                      titleBesideBack: true,
                      action: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_reading case final tracker?) ...[
                            _DuaReadingTimerPill(tracker: tracker),
                            SizedBox(width: 8.w),
                          ],
                          _HeaderIconButton(
                            icon: Icons.copy_rounded,
                            onTap: _showCopySheet,
                          ),
                          SizedBox(width: 8.w),
                          _HeaderIconButton(
                            icon: Icons.ios_share_rounded,
                            onTap: _showShareSheet,
                          ),
                          SizedBox(width: 8.w),
                          _HeaderIconButton(
                            icon: Icons.more_vert_rounded,
                            onTap: _showSettingsModal,
                          ),
                        ],
                      ),
                    ),
                    if (_reading case final tracker?)
                      _DuaReadCheckbox(tracker: tracker, onTap: _markAsRead),
                    if (readable.categoryLabel.isNotEmpty) ...[
                      SizedBox(height: 18.h),
                      _CategoryPill(label: readable.categoryLabel),
                    ],
                    SizedBox(height: 16.h),
                    Text(
                      readable.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17.sp,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                        color: context.inkColor(const Color(0xFF2C3320)),
                      ),
                    ),
                    if (readable.repeatCount != null) ...[
                      SizedBox(height: 8.h),
                      Text(
                        context.localizedDigits(
                          '${appText.duaRecitePrefix} ${readable.repeatCount} '
                          '${appText.duaReciteSuffix}',
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.inkColor(const Color(0xFF7C8A63)),
                        ),
                      ),
                    ],
                    if (settings.showNarration &&
                        readable.instruction.isNotEmpty) ...[
                      SizedBox(height: 16.h),
                      _SectionCard(
                        icon: Icons.menu_book_rounded,
                        accent: const Color(0xFF4C5A34),
                        bg: Colors.white,
                        border: const Color(0xFFE3E7D3),
                        title: appText.duaNarrationTitle,
                        child: Text(
                          readable.instruction,
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            height: 1.6,
                            color: context.inkColor(const Color(0xFF3B4430)),
                          ),
                        ),
                      ),
                    ],
                    if (settings.showArabic &&
                        readable.segments.any((s) => s.arabic.isNotEmpty)) ...[
                      SizedBox(height: 14.h),
                      _SectionCard(
                        icon: Icons.auto_awesome_outlined,
                        accent: const Color(0xFFB07A2E),
                        bg: const Color(0xFFFBF3DD),
                        border: const Color(0xFFEBDCA8),
                        title: appText.duaArabicSectionTitle,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final segment in readable.segments)
                              if (segment.arabic.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4.h),
                                  child: SelectableText(
                                    segment.arabic,
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.rtl,
                                    // The list keeps every drag: without
                                    // this the text's own viewport takes
                                    // them and the page stops scrolling.
                                    scrollPhysics:
                                        const NeverScrollableScrollPhysics(),
                                    style: TextStyle(
                                      fontFamily: 'Noorehuda',
                                      fontFamilyFallback: appFontFamilyFallback,
                                      fontSize: _arabicFontSize(settings).sp,
                                      height: 1.9,
                                      color: context.inkColor(
                                        const Color(0xFF283016),
                                      ),
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ],
                    if (settings.showTransliteration &&
                        readable.transliteration.isNotEmpty) ...[
                      SizedBox(height: 10.h),
                      SelectableText(
                        readable.transliteration,
                        textAlign: TextAlign.center,
                        scrollPhysics: const NeverScrollableScrollPhysics(),
                        style: TextStyle(
                          fontSize: _translationFontSize(settings).sp,
                          height: 1.6,
                          fontStyle: FontStyle.italic,
                          color: context.inkColor(const Color(0xFF3B4430)),
                        ),
                      ),
                    ],
                    if (settings.showTranslation &&
                        readable.segments.any(
                          (s) => s.translation.isNotEmpty,
                        )) ...[
                      SizedBox(height: 14.h),
                      _SectionCard(
                        icon: Icons.translate_rounded,
                        accent: const Color(0xFFB0527A),
                        bg: const Color(0xFFFBDFE6),
                        title: appText.duaTranslationSectionTitle,
                        trailing: InkWell(
                          onTap: () {
                            final translation = readable.segments
                                .map((s) => s.translation)
                                .where((t) => t.isNotEmpty)
                                .join('\n');
                            if (translation.isEmpty) return;
                            Clipboard.setData(ClipboardData(text: translation));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(appText.duaCopied),
                                duration: const Duration(milliseconds: 1200),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12.r),
                          child: Icon(
                            Icons.copy_rounded,
                            size: 15.sp,
                            color: context.inkColor(const Color(0xFFB0527A)),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final segment in readable.segments)
                              if (segment.translation.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 3.h),
                                  child: SelectableText(
                                    segment.translation,
                                    scrollPhysics:
                                        const NeverScrollableScrollPhysics(),
                                    style: TextStyle(
                                      fontSize: _translationFontSize(
                                        settings,
                                      ).sp,
                                      height: 1.6,
                                      color: context.inkColor(
                                        const Color(0xFF5D4450),
                                      ),
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ],
                    if (settings.showReference &&
                        readable.reference.isNotEmpty) ...[
                      SizedBox(height: 14.h),
                      _SectionCard(
                        icon: Icons.verified_rounded,
                        accent: const Color(0xFF2F6B3C),
                        bg: const Color(0xFFDCEEC0),
                        title: appText.duaAuthenticTitle,
                        trailing: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: context.surfaceColor(Colors.white),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            appText.duaChainVerifiedBadge,
                            style: TextStyle(
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.w600,
                              color: context.inkColor(const Color(0xFF2F6B3C)),
                            ),
                          ),
                        ),
                        child: Text(
                          readable.reference,
                          style: TextStyle(
                            fontSize: 12.sp,
                            height: 1.6,
                            color: context.inkColor(const Color(0xFF3B4430)),
                          ),
                        ),
                      ),
                    ],
                    if (readable.virtue.isNotEmpty) ...[
                      SizedBox(height: 14.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: context.surfaceColor(const Color(0xFFFBF3DD)),
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.watch_later_outlined,
                              size: 15.sp,
                              color: context.inkColor(const Color(0xFFB07A2E)),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                readable.virtue,
                                style: TextStyle(
                                  fontSize: 11.5.sp,
                                  height: 1.6,
                                  color: context.inkColor(
                                    const Color(0xFF7C6A3A),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_showReciteBar)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: _ReciteBar(
                      count: _count,
                      onIncrement: _incrementCount,
                      onReset: _resetCount,
                      onBookmark: _showBookmarkSheet,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// The reader content, once a real `/duas/featured` item or the legacy mock
/// [DuaDetail] has been resolved to plain display strings in the app's
/// current language.
class _DuaReadable {
  const _DuaReadable({
    required this.categoryLabel,
    required this.name,
    required this.segments,
    required this.transliteration,
    required this.repeatCount,
    required this.reference,
    required this.instruction,
    required this.virtue,
  });

  final String categoryLabel;
  final String name;
  final List<DuaSegment> segments;
  final String transliteration;
  final int? repeatCount;
  final String reference;
  final String instruction;
  final String virtue;
}

/// Copy chooser shown from the reader app bar. Each card can be selected on
/// its own, while "All Dua" toggles every available section together.
class _DuaCopySheet extends StatefulWidget {
  const _DuaCopySheet({required this.readable});

  final _DuaReadable readable;

  @override
  State<_DuaCopySheet> createState() => _DuaCopySheetState();
}

class _DuaCopySheetState extends State<_DuaCopySheet> {
  late Set<_DuaCopyPart> _selected;

  @override
  void initState() {
    super.initState();
    _selected = _availableParts.toSet();
  }

  List<_DuaCopyPart> get _availableParts => [
    if (_arabicAndTranslation.isNotEmpty) _DuaCopyPart.arabicAndTranslation,
    if (widget.readable.transliteration.isNotEmpty)
      _DuaCopyPart.transliteration,
    if (_referenceAndGuidance.isNotEmpty) _DuaCopyPart.referenceAndGuidance,
  ];

  String get _arabicAndTranslation {
    final arabic = widget.readable.segments
        .map((segment) => segment.arabic)
        .where((text) => text.isNotEmpty)
        .join('\n');
    final translation = widget.readable.segments
        .map((segment) => segment.translation)
        .where((text) => text.isNotEmpty)
        .join('\n');
    return [arabic, translation].where((text) => text.isNotEmpty).join('\n');
  }

  String get _referenceAndGuidance => [
    widget.readable.reference,
    widget.readable.instruction,
    widget.readable.virtue,
  ].where((text) => text.isNotEmpty).join('\n');

  bool get _allSelected =>
      _availableParts.isNotEmpty && _availableParts.every(_selected.contains);

  void _toggleAll() => setState(() {
    if (_allSelected) {
      _selected.removeAll(_availableParts);
    } else {
      _selected.addAll(_availableParts);
    }
  });

  void _toggle(_DuaCopyPart part) => setState(() {
    if (!_selected.add(part)) _selected.remove(part);
  });

  String get _selectedText {
    final parts = <String>[];
    if (widget.readable.name.isNotEmpty) parts.add(widget.readable.name);
    if (_selected.contains(_DuaCopyPart.arabicAndTranslation)) {
      final arabic = widget.readable.segments
          .map((segment) => segment.arabic)
          .where((text) => text.isNotEmpty)
          .join('\n');
      final translation = widget.readable.segments
          .map((segment) => segment.translation)
          .where((text) => text.isNotEmpty)
          .join('\n');
      if (arabic.isNotEmpty) parts.add('Arabic\n$arabic');
      if (translation.isNotEmpty) parts.add('Translation\n$translation');
    }
    if (_selected.contains(_DuaCopyPart.transliteration)) {
      parts.add('Transliteration\n${widget.readable.transliteration}');
    }
    if (_selected.contains(_DuaCopyPart.referenceAndGuidance)) {
      if (widget.readable.reference.isNotEmpty) {
        parts.add('Reference\n${widget.readable.reference}');
      }
      if (widget.readable.instruction.isNotEmpty) {
        parts.add('Guidance\n${widget.readable.instruction}');
      }
      if (widget.readable.virtue.isNotEmpty) {
        parts.add('Virtue\n${widget.readable.virtue}');
      }
    }
    return parts.join('\n\n');
  }

  Future<void> _copy() async {
    final text = _selectedText.trim();
    if (text.isEmpty) return;
    await Clipboard.setData(
      ClipboardData(
        text: [
          text,
          _tuhfatulMuslimShareInvitation,
          _tuhfatulMuslimPlayStoreUrl,
        ].join('\n\n'),
      ),
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      (
        icon: Icons.checklist_rounded,
        title: 'All Dua',
        subtitle: 'Select all available Dua content',
        selected: _allSelected,
        enabled: _availableParts.isNotEmpty,
        onTap: _toggleAll,
      ),
      (
        icon: Icons.menu_book_outlined,
        title: 'Arabic & Translation',
        subtitle: 'Copy the original text and its meaning',
        selected: _selected.contains(_DuaCopyPart.arabicAndTranslation),
        enabled: _availableParts.contains(_DuaCopyPart.arabicAndTranslation),
        onTap: () => _toggle(_DuaCopyPart.arabicAndTranslation),
      ),
      (
        icon: Icons.assignment_outlined,
        title: 'Phonetic Transliteration',
        subtitle: 'Helps with clear pronunciation',
        selected: _selected.contains(_DuaCopyPart.transliteration),
        enabled: _availableParts.contains(_DuaCopyPart.transliteration),
        onTap: () => _toggle(_DuaCopyPart.transliteration),
      ),
      (
        icon: Icons.article_outlined,
        title: 'Reference & Guidance',
        subtitle: 'Copy the source, guidance, and virtue',
        selected: _selected.contains(_DuaCopyPart.referenceAndGuidance),
        enabled: _availableParts.contains(_DuaCopyPart.referenceAndGuidance),
        onTap: () => _toggle(_DuaCopyPart.referenceAndGuidance),
      ),
    ];

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(24.w, 14.h, 24.w, 18.h),
        decoration: BoxDecoration(
          color: context.surfaceColor(Colors.white),
          borderRadius: BorderRadius.vertical(top: Radius.circular(34.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56.w,
              height: 6.h,
              decoration: BoxDecoration(
                color: context.lineColor(const Color(0xFFD4D1CE)),
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            SizedBox(height: 18.h),
            Row(
              children: [
                Text(
                  'Copy',
                  style: TextStyle(
                    color: const Color(0xFFA5B657),
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: context.surfaceColor(
                      const Color(0xFFF4F4F2),
                    ),
                    foregroundColor: context.inkColor(const Color(0xFF777572)),
                    minimumSize: Size(40.r, 40.r),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            SizedBox(height: 18.h),
            for (final option in options) ...[
              _DuaCopyOptionCard(
                icon: option.icon,
                title: option.title,
                subtitle: option.subtitle,
                selected: option.selected,
                enabled: option.enabled,
                onTap: option.onTap,
              ),
              SizedBox(height: 10.h),
            ],
            SizedBox(height: 4.h),
            SizedBox(
              width: double.infinity,
              height: 58.h,
              child: FilledButton(
                onPressed: _selected.isEmpty ? null : _copy,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFA5B657),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFDCE4BE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
                child: Text('Copy!', style: TextStyle(fontSize: 17.sp)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _DuaCopyPart {
  arabicAndTranslation,
  transliteration,
  referenceAndGuidance,
}

class _DuaCopyOptionCard extends StatelessWidget {
  const _DuaCopyOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? const Color(0xFFA5B657)
        : context.inkColor(const Color(0xFFC9C9C4));
    return Material(
      color: context.surfaceColor(const Color(0xFFFDFDFC)),
      borderRadius: BorderRadius.circular(24.r),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(24.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: BoxConstraints(minHeight: 86.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: selected ? const Color(0xFFA5B657) : Colors.transparent,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .035),
                blurRadius: 16.r,
                offset: Offset(0, 5.h),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 27.sp),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: enabled
                            ? context.inkColor(const Color(0xFF383632))
                            : color,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      subtitle,
                      style: TextStyle(color: color, fontSize: 12.sp),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              Icon(
                selected
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                color: color,
                size: 26.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A content picker before handing the selected text to Android's native
/// share surface (Quick Share, installed apps, and so on).
class _DuaShareSheet extends StatelessWidget {
  const _DuaShareSheet({required this.readable});

  final _DuaReadable readable;

  @override
  Widget build(BuildContext context) {
    final hasGuidance =
        readable.instruction.isNotEmpty || readable.virtue.isNotEmpty;
    final options = [
      (
        part: _DuaSharePart.all,
        icon: Icons.checklist_rounded,
        title: 'All Dua',
        subtitle: 'Share all available Dua content',
        enabled: readable.name.isNotEmpty || readable.segments.isNotEmpty,
      ),
      (
        part: _DuaSharePart.name,
        icon: Icons.short_text_rounded,
        title: 'Dua name',
        subtitle: 'Share only this Dua name',
        enabled: readable.name.isNotEmpty,
      ),
      (
        part: _DuaSharePart.guidanceAndVirtue,
        icon: Icons.menu_book_outlined,
        title: 'Dua Guidance & Virtue',
        subtitle: 'Share the guidance and benefit',
        enabled: hasGuidance,
      ),
      (
        part: _DuaSharePart.transliteration,
        icon: Icons.assignment_outlined,
        title: 'Phonetic Transliteration',
        subtitle: 'Share pronunciation-friendly text',
        enabled: readable.transliteration.isNotEmpty,
      ),
      (
        part: _DuaSharePart.reference,
        icon: Icons.article_outlined,
        title: 'Reference & Source',
        subtitle: 'Share the Dua reference',
        enabled: readable.reference.isNotEmpty,
      ),
    ];

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 22.h),
        decoration: BoxDecoration(
          color: context.surfaceColor(Colors.white),
          borderRadius: BorderRadius.vertical(top: Radius.circular(34.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: context.lineColor(const Color(0xFFD4D1CE)),
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            SizedBox(height: 18.h),
            Row(
              children: [
                Text(
                  'Share',
                  style: TextStyle(
                    color: const Color(0xFFA5B657),
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: context.surfaceColor(
                      const Color(0xFFF4F4F2),
                    ),
                    foregroundColor: context.inkColor(const Color(0xFF777572)),
                    minimumSize: Size(40.r, 40.r),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            for (final option in options) ...[
              _DuaShareOptionCard(
                icon: option.icon,
                title: option.title,
                subtitle: option.subtitle,
                enabled: option.enabled,
                onTap: () => Navigator.of(context).pop(option.part),
              ),
              SizedBox(height: 8.h),
            ],
          ],
        ),
      ),
    );
  }
}

enum _DuaSharePart { all, name, guidanceAndVirtue, transliteration, reference }

class _DuaShareOptionCard extends StatelessWidget {
  const _DuaShareOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final olive = const Color(0xFFA5B657);
    final muted = context.inkColor(const Color(0xFFC9C9C4));
    return Material(
      color: context.surfaceColor(const Color(0xFFFDFDFC)),
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          constraints: BoxConstraints(minHeight: 62.h),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .035),
                blurRadius: 13.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: enabled ? olive : muted, size: 23.sp),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: enabled
                            ? context.inkColor(const Color(0xFF383632))
                            : muted,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: enabled ? olive : muted,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.reply_rounded,
                color: enabled ? olive : muted,
                size: 22.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A circular icon button in the header's action row (design `img_19.png`:
/// copy, share, and the settings overflow).
class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      style: IconButton.styleFrom(
        // The yellow badge is a vivid accent, so dark mode keeps it as it
        // is — which means its icon has to stay dark as well. Mapped to
        // light ink it was all but invisible on that badge. This is the
        // same pair [DuaPageHeader]'s back button uses.
        backgroundColor: context.surfaceColor(const Color(0xFFDFDE68)),
        foregroundColor: const Color(0xFF303629),
        minimumSize: Size(38.r, 38.r),
      ),
      icon: Icon(icon, size: 18),
    );
  }
}

/// The live reading timer in the header's top-right corner: how long this
/// visit has been reading, refreshed each second. It stops for good once the
/// dua is marked read, and then shows a check instead of the clock — on a
/// dua read earlier, from the moment the screen opens.
class _DuaReadingTimerPill extends StatelessWidget {
  const _DuaReadingTimerPill({required this.tracker});

  final DuaReadingTracker tracker;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: tracker,
      builder: (context, _) {
        final seconds = tracker.elapsedSeconds;
        final read = tracker.isCompleted;
        final accent = read ? const Color(0xFF2F6B3C) : const Color(0xFF5D6B44);
        return Container(
          height: 38.r,
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          decoration: BoxDecoration(
            color: context.surfaceColor(
              read ? const Color(0xFFDCEEC0) : const Color(0xFFF3F1DE),
            ),
            borderRadius: BorderRadius.circular(19.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                read ? Icons.check_circle_rounded : Icons.timer_outlined,
                size: 13.sp,
                color: context.inkColor(accent),
              ),
              SizedBox(width: 4.w),
              Text(
                context.localizedDigits(
                  '${seconds ~/ 60}:'
                  '${(seconds % 60).toString().padLeft(2, '0')}',
                ),
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                  color: context.inkColor(accent),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The "Read / Completed" checkbox, right-aligned under the header. It shows
/// once this visit is long enough to report ([DuaReadingTracker.canComplete])
/// and, once checked, stays checked and disabled — the reading has been
/// recorded and the timer above has stopped. A dua read on an earlier visit
/// shows it checked right away.
class _DuaReadCheckbox extends StatelessWidget {
  const _DuaReadCheckbox({required this.tracker, required this.onTap});

  final DuaReadingTracker tracker;
  final Future<void> Function() onTap;

  static const _green = Color(0xFF2F6B3C);

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return ListenableBuilder(
      listenable: tracker,
      builder: (context, _) {
        final read = tracker.isCompleted;
        final busy = tracker.isSubmitting;
        if (!read && !busy && !tracker.canComplete) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: EdgeInsets.only(top: 14.h),
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: read || busy ? null : () => unawaited(onTap()),
                borderRadius: BorderRadius.circular(20.r),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: context.surfaceColor(
                      read ? _green : const Color(0xFFECF0DC),
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: context.lineColor(
                        read ? _green : const Color(0xFFDCE3C4),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (busy)
                        SizedBox(
                          width: 13.r,
                          height: 13.r,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation(
                              read ? Colors.white : _green,
                            ),
                          ),
                        )
                      else
                        Icon(
                          read
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          size: 15.sp,
                          color: read
                              ? Colors.white
                              : context.inkColor(const Color(0xFF4C5A34)),
                        ),
                      SizedBox(width: 6.w),
                      Text(
                        appText.duaMarkAsReadLabel,
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w600,
                          color: read
                              ? Colors.white
                              : context.inkColor(const Color(0xFF4C5A34)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The dua's category/group name pill under the header (design
/// `img_19.png`).
class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: context.surfaceColor(const Color(0xFFF3F1DE)),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 15.sp,
            color: context.inkColor(const Color(0xFF8B9A4B)),
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                color: context.inkColor(const Color(0xFF5D6B44)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A labeled content card used for the reader's Narration / Arabic /
/// Translation / Authentic-Hadith sections (design `img_19.png`).
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.accent,
    required this.bg,
    required this.title,
    required this.child,
    this.trailing,
    this.border,
  });

  final IconData icon;
  final Color accent;
  final Color bg;
  final String title;
  final Widget child;
  final Widget? trailing;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: context.surfaceColor(bg),
        borderRadius: BorderRadius.circular(16.r),
        border: border == null
            ? null
            : Border.all(color: context.lineColor(border!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15.sp, color: context.inkColor(accent)),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                    color: context.inkColor(accent),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          SizedBox(height: 10.h),
          child,
        ],
      ),
    );
  }
}

/// Floating recite-counter bar (design `img_19.png`): tap the number to
/// count a recitation, the loop icon resets it, the bookmark icon opens
/// [DuaBookmarkSheet], and the play icon is disabled — no audio yet.
class _ReciteBar extends StatelessWidget {
  const _ReciteBar({
    required this.count,
    required this.onIncrement,
    required this.onReset,
    required this.onBookmark,
  });

  final int count;
  final VoidCallback onIncrement;
  final VoidCallback onReset;
  final VoidCallback onBookmark;

  static const _barColor = Color(0xFFA1AE57);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: context.surfaceColor(_barColor),
        borderRadius: BorderRadius.circular(32.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: onIncrement,
            borderRadius: BorderRadius.circular(22.r),
            child: Container(
              width: 42.r,
              height: 42.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.surfaceColor(Colors.white),
                shape: BoxShape.circle,
              ),
              child: Text(
                context.localizedDigits('$count'),
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: context.inkColor(const Color(0xFF3C4A28)),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onReset,
            icon: const Icon(Icons.replay_rounded, color: Colors.white),
          ),
          IconButton(
            onPressed: onBookmark,
            icon: const Icon(
              Icons.bookmark_border_rounded,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: null,
            icon: Icon(
              Icons.play_arrow_rounded,
              color: Colors.white.withValues(alpha: .55),
            ),
          ),
        ],
      ),
    );
  }
}

/// Uppercase section label with a small accent bar, used above each group of
/// settings cards (design `devImg/img_20.png`: "DISPLAY & READING STYLE" /
/// "TYPOGRAPHY & SCRIPT STYLING").
class _SettingsSectionHeader extends StatelessWidget {
  const _SettingsSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4.w,
          height: 14.h,
          decoration: BoxDecoration(
            color: context.surfaceColor(const Color(0xFFD08A3E)),
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: context.inkColor(const Color(0xFF8B9A4B)),
          ),
        ),
      ],
    );
  }
}

/// One content-visibility toggle in the settings sheet's "Display & Reading
/// Style" card: an icon badge, a title + subtitle, and a switch (design
/// `devImg/img_20.png`).
class _SettingsToggleRow extends StatelessWidget {
  const _SettingsToggleRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38.r,
          height: 38.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.surfaceColor(iconBg),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, size: 17.sp, color: context.inkColor(iconColor)),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: context.inkColor(const Color(0xFF2C3320)),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10.5.sp,
                  height: 1.4,
                  color: context.inkColor(const Color(0xFF7C8A63)),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColor.primary,
          activeTrackColor: AppColor.primary.withValues(alpha: 0.3),
        ),
      ],
    );
  }
}
