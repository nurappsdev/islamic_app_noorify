import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/hadith/data/datasources/hadith_library_remote_data_source.dart';
import 'package:islami_app_noorify/features/hadith/data/hadith_content_settings.dart';
import 'package:islami_app_noorify/features/hadith/data/repositories/hadith_library_repository_impl.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_detail.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_details.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_detail/hadith_detail_bloc.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_content_settings_drawer.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_list_scaffold.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

/// Route arguments for [HadithDetailScreen].
class HadithDetailArgs {
  const HadithDetailArgs({this.subCategoryId, this.bookId, this.title})
    : assert(subCategoryId != null || bookId != null);

  final String? subCategoryId;
  final String? bookId;
  final String? title;
}

/// The hadiths of one sub-category (`GET /hadiths?subCategoryId=...`) or of a
/// whole book (`GET /hadiths?bookId=...`).
///
/// Reached by tapping a row on [HadithSubCategoryScreen], or the "Total
/// Hadith" button on a collection card of the library screen. Each hadith is a
/// card with its Arabic text, Bangla translation, reference (takhrij), grade
/// and source, paginated with shimmer placeholders.
class HadithDetailScreen extends StatelessWidget {
  const HadithDetailScreen({
    super.key,
    this.subCategoryId,
    this.bookId,
    this.title,
  });

  final String? subCategoryId;
  final String? bookId;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HadithDetailBloc(
        GetHadithDetails(
          HadithLibraryRepositoryImpl(HadithLibraryRemoteDataSourceImpl()),
        ),
      )..add(LoadHadithDetails(subCategoryId: subCategoryId, bookId: bookId)),
      child: _HadithDetailView(
        subCategoryId: subCategoryId,
        bookId: bookId,
        title: title,
      ),
    );
  }
}

class _HadithDetailView extends StatefulWidget {
  const _HadithDetailView({this.subCategoryId, this.bookId, this.title});

  final String? subCategoryId;
  final String? bookId;
  final String? title;

  @override
  State<_HadithDetailView> createState() => _HadithDetailViewState();
}

class _HadithDetailViewState extends State<_HadithDetailView> {
  /// How close to the end of the list (in logical pixels) the next page
  /// starts loading.
  static const _loadMoreThreshold = 400.0;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollController = ScrollController();
  final _settingsStore = HadithContentSettingsStore();
  String _query = '';
  HadithContentSettings _settings = const HadithContentSettings();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _settingsStore.load().then((value) {
      if (mounted) setState(() => _settings = value);
    });
  }

  void _updateSettings(HadithContentSettings value) {
    setState(() => _settings = value);
    _settingsStore.save(value);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      // The bloc ignores this while a page is loading or after the last one.
      context.read<HadithDetailBloc>().add(const LoadMoreHadithDetails());
    }
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

    final title = (widget.title ?? '').isNotEmpty
        ? widget.title!
        : appText.categoryHadith;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
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
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 28.h),
                children: [
                  if (state.isLoading)
                    const _HadithSkeletons(count: 2)
                  else if (state.status == HadithDetailStatus.failure) ...[
                    _Message(state.failure?.message ?? ''),
                    TextButton(
                      onPressed: () => context.read<HadithDetailBloc>().add(
                        LoadHadithDetails(
                          subCategoryId: widget.subCategoryId,
                          bookId: widget.bookId,
                        ),
                      ),
                      child: Text(appText.tryAgain),
                    ),
                  ] else if (hadiths.isEmpty && !(searching && state.hasMore))
                    _Message(appText.noResultsFound)
                  else ...[
                    for (final hadith in hadiths) ...[
                      _HadithCard(
                        hadith: hadith,
                        bookName: title,
                        settings: _settings,
                      ),
                      SizedBox(height: 14.h),
                    ],
                    if (state.isLoadingMore || (searching && state.hasMore))
                      const _HadithSkeletons(count: 1),
                    if (state.loadMoreFailure != null) ...[
                      _Message(state.loadMoreFailure!.message),
                      TextButton(
                        onPressed: () => context.read<HadithDetailBloc>().add(
                          const LoadMoreHadithDetails(),
                        ),
                        child: Text(appText.tryAgain),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
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
                foregroundColor: const Color(0xFF303629),
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
                  color: const Color(0xFF2C3320),
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
                backgroundColor: const Color(0xFFEDF1DE),
                foregroundColor: const Color(0xFF4C5A34),
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
        style: TextStyle(fontSize: 13.sp, color: const Color(0xFF5D6B44)),
      ),
    );
  }
}

/// Shimmer placeholders shaped like [_HadithCard].
class _HadithSkeletons extends StatelessWidget {
  const _HadithSkeletons({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE3ECC5),
      highlightColor: const Color(0xFFF6F9EC),
      child: Column(
        children: [
          for (var i = 0; i < count; i++) ...[
            Container(
              height: 340.h,
              decoration: BoxDecoration(
                color: Colors.white,
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

class _HadithCard extends StatefulWidget {
  const _HadithCard({
    required this.hadith,
    required this.bookName,
    required this.settings,
  });

  final HadithDetail hadith;
  final HadithContentSettings settings;

  /// Name of the book / sub-category on screen, used in the report mail.
  final String bookName;

  @override
  State<_HadithCard> createState() => _HadithCardState();
}

class _HadithCardState extends State<_HadithCard> {
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
            leading: Icon(icon, color: color),
            title: Text(label, style: TextStyle(color: color)),
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
                  color: const Color(0xFFDCE3C4),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE3E7D3)),
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
                    color: _green,
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
                const Spacer(),
                if (hadith.textEnglish.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _showEnglish = !_showEnglish),
                    icon: Icon(Icons.translate_rounded, size: 16.sp),
                    // Names the language a tap switches to.
                    label: Text(_showEnglish ? 'বাংলা' : 'English'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _green,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: _green),
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
                // Room for the overlaid menu button.
                SizedBox(width: 40.w),
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
                  color: _muted,
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
                  color: _ink,
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
                  color: const Color(0xFF8B9A4B),
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
                  color: _ink,
                ),
              ),
            ],
            if (hadith.takhrij.isNotEmpty) ...[
              SizedBox(height: 14.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: _tint,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: const Color(0xFFD5E2D0)),
                ),
                child: Text(
                  hadith.takhrij,
                  style: TextStyle(fontSize: 12.5.sp, height: 1.6, color: _ink),
                ),
              ),
            ],
            SizedBox(height: 14.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: _tint,
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
          child: Builder(
            builder: (buttonContext) => _MoreButton(
              tooltip: AppText.of(context).hadithCopy,
              onTap: () => _showActions(buttonContext),
            ),
          ),
        ),
      ],
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
            color: const Color(0xFFECF0DC),
            borderRadius: BorderRadius.circular(9.r),
            border: Border.all(color: const Color(0xFFDCE3C4)),
          ),
          child: Icon(
            Icons.more_vert_rounded,
            size: 16.sp,
            color: const Color(0xFF4C5A34),
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
        color: const Color(0xFF5D6B44),
      ),
    );
  }
}
