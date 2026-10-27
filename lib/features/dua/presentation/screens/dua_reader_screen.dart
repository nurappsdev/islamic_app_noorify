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
import 'package:tuhfatul_muslim/features/dua/presentation/dua_route_args.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/bloc/dua_settings/dua_settings_bloc.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_bookmark_sheet.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_page_header.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_zoom_control.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/core/theme/app_typography.dart';

/// Single-dua reader (design `devImg/img_19.png`), reached by tapping a dua
/// row on [DuaGroupScreen] / [DuaAllDuaScreen].
///
/// UI only: the recitation counter is in-memory and resets when the screen is
/// left; the bookmark icon opens [DuaBookmarkSheet]. The play icon has no
/// audio yet, so it isn't wired.
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

class _DuaReaderViewState extends State<_DuaReaderView> {
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

  /// Title, Arabic, translation and reference as plain text — for the
  /// header's copy and share actions.
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
    return buffer.toString().trim();
  }

  Future<void> _copyFullText() async {
    final appText = AppText.of(context);
    final text = _plainText(context);
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(appText.duaCopied),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  Future<void> _shareFullText() async {
    final appText = AppText.of(context);
    final text = _plainText(context);
    if (text.isEmpty) return;
    try {
      final box = context.findRenderObject();
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: _readable(context).name,
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
      body: BlocBuilder<DuaSettingsBloc, DuaSettingsState>(
        builder: (context, settings) {
          return Stack(
            children: [
              ListView(
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
                    // The dua's own name is the screen title, next to the
                    // back icon and cut to 12 characters so it can never
                    // reach the action icons; the heading below still spells
                    // it out in full.
                    title: readable.name.isNotEmpty
                        ? readable.name
                        : appText.duaIntroTitle,
                    titleBesideBack: true,
                    maxTitleChars: 12,
                    action: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _HeaderIconButton(
                          icon: Icons.copy_rounded,
                          onTap: _copyFullText,
                        ),
                        SizedBox(width: 8.w),
                        _HeaderIconButton(
                          icon: Icons.ios_share_rounded,
                          onTap: _shareFullText,
                        ),
                        SizedBox(width: 8.w),
                        _HeaderIconButton(
                          icon: Icons.more_vert_rounded,
                          onTap: _showSettingsModal,
                        ),
                      ],
                    ),
                  ),
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
                                child: Text(
                                  segment.arabic,
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(
                                    fontFamily: 'Noorehuda',
                                    fontFamilyFallback: appFontFamilyFallback,
                                    fontSize: settings.arabicFontSize.sp,
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
                    Text(
                      readable.transliteration,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: settings.translationFontSize.sp,
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
                                child: Text(
                                  segment.translation,
                                  style: TextStyle(
                                    fontSize: settings.translationFontSize.sp,
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
