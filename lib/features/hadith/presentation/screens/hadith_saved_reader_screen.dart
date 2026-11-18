import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_daily_dashboard.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/state/amol_daily_store.dart';
import 'package:tuhfatul_muslim/features/hadith/data/hadith_bookmark_store.dart';
import 'package:tuhfatul_muslim/features/hadith/data/hadith_content_settings.dart';
import 'package:tuhfatul_muslim/features/hadith/data/models/hadith_detail_model.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/entities/hadith_detail.dart';
import 'package:tuhfatul_muslim/features/hadith/presentation/screens/hadith_detail_screen.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// Reads a hadith saved from the online library, from the copy kept with its
/// bookmark (so it also works offline). Opened from the Saved screen.
class HadithSavedReaderScreen extends StatefulWidget {
  const HadithSavedReaderScreen({super.key, required this.bookmark});

  final HadithBookmark bookmark;

  @override
  State<HadithSavedReaderScreen> createState() =>
      _HadithSavedReaderScreenState();
}

class _HadithSavedReaderScreenState extends State<HadithSavedReaderScreen> {
  HadithContentSettings _settings = const HadithContentSettings();
  late final HadithDetail? _hadith = _decode(widget.bookmark.payload);
  final _sessionSeconds = ValueNotifier<int>(0);
  final _stopwatch = Stopwatch();
  late final Timer _timer;
  late final AppLifecycleListener _lifecycle;

  static HadithDetail? _decode(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      return HadithDetailModel.fromJson(
        jsonDecode(payload) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _sessionSeconds.value = _stopwatch.elapsed.inSeconds;
    });
    _lifecycle = AppLifecycleListener(
      onHide: _stopwatch.stop,
      onShow: _stopwatch.start,
    );
    unawaited(AmolDailyStore.instance.ensureLoaded());
    HadithContentSettingsStore().load().then((value) {
      if (mounted) setState(() => _settings = value);
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _timer.cancel();
    _stopwatch.stop();
    _sessionSeconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final hadith = _hadith;
    final source = hadith == null
        ? ''
        : (hadith.sourceBangla.isNotEmpty
              ? hadith.sourceBangla
              : hadith.sourceEnglish);

    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 6.h),
            SizedBox(
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
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 15,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      context.localizedDigits(
                        '${appText.categoryHadith} ${widget.bookmark.hadithNo}',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.inkColor(const Color(0xFF2C3320)),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _SavedHadithReadTime(seconds: _sessionSeconds),
                  SizedBox(width: 14.w),
                ],
              ),
            ),
            Expanded(
              child: hadith == null
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32.w),
                        child: Text(
                          appText.noSavedHadithMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: context.inkColor(const Color(0xFF5D6B44)),
                          ),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
                      child: HadithDetailCard(
                        hadith: hadith,
                        bookName: source,
                        settings: _settings,
                        onTranslationLanguageChanged: (language) {
                          final value = _settings.copyWith(
                            translationLanguage: language,
                          );
                          setState(() => _settings = value);
                          HadithContentSettingsStore().save(value);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The active saved-reader time and today's shared Hadith total. The latter
/// is the same Amol source used by the Home Hadith feature card.
class _SavedHadithReadTime extends StatelessWidget {
  const _SavedHadithReadTime({required this.seconds});

  final ValueListenable<int> seconds;

  static String _clock(int seconds) {
    String two(int value) => value.toString().padLeft(2, '0');
    final minutes = seconds ~/ 60;
    return '${two(minutes)}:${two(seconds % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    final isBangla =
        context.watch<LanguageBloc>().state.language == AppLanguage.bangla;
    return ValueListenableBuilder<AmolDailyDashboard?>(
      valueListenable: AmolDailyStore.instance,
      builder: (context, daily, _) {
        var recordedMinutes = 0;
        for (final pillar in daily?.pillars ?? const []) {
          if (pillar.pillarKey == 'hadith' &&
              pillar.entry != null &&
              pillar.entry!.isMinutes) {
            recordedMinutes = pillar.entry!.amount.floor();
            break;
          }
        }
        return ValueListenableBuilder<int>(
          valueListenable: seconds,
          builder: (context, value, _) {
            final total = recordedMinutes + value ~/ 60;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TimePill(text: context.localizedDigits(_clock(value))),
                SizedBox(width: 4.w),
                _TimePill(
                  text: context.localizedDigits(
                    isBangla ? '$total মি' : '${total}m',
                  ),
                  total: true,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.text, this.total = false});

  final String text;
  final bool total;

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey(total ? 'hadith-saved-total-minutes' : 'hadith-saved-timer'),
    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
    decoration: BoxDecoration(
      color: context.surfaceColor(
        total ? const Color(0xFFEDF1DE) : const Color(0xFFF5F6EA),
      ),
      borderRadius: BorderRadius.circular(12.r),
      border: Border.all(color: const Color(0xFF9BA85B).withValues(alpha: .4)),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: context.inkColor(const Color(0xFF4C5A34)),
        fontSize: 10.sp,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    ),
  );
}
