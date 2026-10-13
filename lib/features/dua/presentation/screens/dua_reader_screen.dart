import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

/// Single-dua reader (design `devImg/img_6.png`), reached by tapping a dua
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
  /// Unifies a real `/duas/featured` item and the legacy mock [DuaDetail]
  /// into one shape the view below renders, resolving bilingual fields in
  /// the app's current language.
  _DuaReadable _readable(BuildContext context) {
    final model = widget.args.featuredModel;
    if (model != null) {
      final categoryName = context.localized(model.category?.name);
      final title = context.localized(model.title);
      return _DuaReadable(
        headerTitle: categoryName.isNotEmpty ? categoryName : title,
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
      );
    }
    final detail = widget.args.detail!;
    return _DuaReadable(
      headerTitle: widget.args.featured!.groupLabel,
      name: detail.name,
      segments: detail.segments,
      transliteration: detail.transliteration,
      repeatCount: detail.repeatCount,
      reference: '',
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

  void _showSettingsModal() {
    final appText = AppText.of(context);
    final settingsBloc = context.read<DuaSettingsBloc>();

    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor(Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return BlocProvider.value(
          value: settingsBloc,
          child: Padding(
            padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 32.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: context.surfaceColor(Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  appText.duaSettingsTitle,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.primary,
                  ),
                ),
                SizedBox(height: 20.h),
                const DuaZoomControl(),
                SizedBox(height: 20.h),
                BlocBuilder<DuaSettingsBloc, DuaSettingsState>(
                  builder: (context, state) {
                    return Column(
                      children: [
                        _VisibilityToggle(
                          label: appText.showArabicLabel,
                          value: state.showArabic,
                          onChanged: (val) {
                            context.read<DuaSettingsBloc>().add(
                              ToggleDuaArabic(val),
                            );
                          },
                        ),
                        SizedBox(height: 12.h),
                        _VisibilityToggle(
                          label: appText.showTranslationLabel,
                          value: state.showTranslation,
                          onChanged: (val) {
                            context.read<DuaSettingsBloc>().add(
                              ToggleDuaTranslation(val),
                            );
                          },
                        ),
                        SizedBox(height: 12.h),
                        _VisibilityToggle(
                          label: appText.showTransliterationLabel,
                          value: state.showTransliteration,
                          onChanged: (val) {
                            context.read<DuaSettingsBloc>().add(
                              ToggleDuaTransliteration(val),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
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
          final multiplier = settings.fontSizeMultiplier;
          return ListView(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h + bottomInset),
            children: [
              SizedBox(height: 36.h),
              DuaPageHeader(
                title: readable.headerTitle,
                action: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _showSettingsModal,
                      style: IconButton.styleFrom(
                        backgroundColor: context.surfaceColor(
                          Color(0xFFDFDE68),
                        ),
                        foregroundColor: context.inkColor(Color(0xFF303629)),
                        minimumSize: Size(38.r, 38.r),
                      ),
                      icon: const Icon(Icons.settings_rounded, size: 18),
                    ),
                    SizedBox(width: 8.w),
                    IconButton(
                      onPressed: _showBookmarkSheet,
                      style: IconButton.styleFrom(
                        backgroundColor: context.surfaceColor(
                          Color(0xFFDFDE68),
                        ),
                        foregroundColor: context.inkColor(Color(0xFF303629)),
                        minimumSize: Size(38.r, 38.r),
                      ),
                      icon: const Icon(Icons.bookmark_border_rounded, size: 18),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),
              Text(
                readable.name,
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700),
              ),
              if (readable.repeatCount != null) ...[
                SizedBox(height: 10.h),
                Text(
                  context.localizedDigits(
                    '${appText.duaRecitePrefix} ${readable.repeatCount} '
                    '${appText.duaReciteSuffix}',
                  ),
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: context.inkColor(Color(0xFF3B4430)),
                  ),
                ),
              ],
              SizedBox(height: 20.h),
              for (final segment in readable.segments) ...[
                if (settings.showArabic)
                  Text(
                    segment.arabic,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Noorehuda',
                      fontSize: 20.sp * multiplier,
                      height: 1.9,
                      color: context.inkColor(Color(0xFF283016)),
                    ),
                  ),
                if (settings.showArabic && settings.showTranslation)
                  SizedBox(height: 4.h),
                if (settings.showTranslation)
                  Text(
                    segment.translation,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp * multiplier,
                      color: context.inkColor(Color(0xFF5D6B44)),
                    ),
                  ),
                SizedBox(height: 14.h),
              ],
              if (settings.showTransliteration) ...[
                SizedBox(height: 6.h),
                Text(
                  readable.transliteration,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5.sp * multiplier,
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                    color: context.inkColor(Color(0xFF3B4430)),
                  ),
                ),
              ],
              if (readable.reference.isNotEmpty) ...[
                SizedBox(height: 18.h),
                Text(
                  '${appText.hadithBookReference}: ${readable.reference}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: context.inkColor(Color(0xFF7C8A63)),
                  ),
                ),
              ],
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
    required this.headerTitle,
    required this.name,
    required this.segments,
    required this.transliteration,
    required this.repeatCount,
    required this.reference,
  });

  final String headerTitle;
  final String name;
  final List<DuaSegment> segments;
  final String transliteration;
  final int? repeatCount;
  final String reference;
}

class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: context.inkColor(Color(0xFF6B7458)),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColor.primary,
          activeTrackColor: AppColor.primary.withOpacity(0.2),
        ),
      ],
    );
  }
}
