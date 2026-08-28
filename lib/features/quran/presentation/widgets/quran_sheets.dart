import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/quran/domain/translation_edition.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/quran_translation/quran_translation_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/reciter/reciter_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/surah_audio_download/surah_audio_download_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/tafsir/tafsir_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_zoom_control.dart';

/// Opens a bottom sheet listing reciters from [reciterBloc], letting the
/// user pick one. Pass the ancestor's [ReciterBloc] explicitly since a
/// bottom sheet is a separate route and doesn't inherit it automatically.
void openReciterPicker(BuildContext context, ReciterBloc reciterBloc) {
  showModalBottomSheet(
    context: context,
    builder: (_) => BlocProvider.value(
      value: reciterBloc,
      child: const ReciterPickerSheet(),
    ),
  );
}

class ReciterPickerSheet extends StatelessWidget {
  const ReciterPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appText.selectReciterTitle,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10.h),
            BlocBuilder<ReciterBloc, ReciterState>(
              builder: (context, state) {
                if (state.isLoading && state.reciters.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColor.primary),
                    ),
                  );
                }
                return ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 360.h),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: state.reciters.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: const Color(0xFFE3ECC5)),
                    itemBuilder: (context, index) {
                      final reciter = state.reciters[index];
                      final selected = reciter.id == state.selectedId;
                      return ListTile(
                        title: Text(
                          reciter.name,
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        trailing: selected
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColor.primary,
                              )
                            : null,
                        onTap: () {
                          context.read<ReciterBloc>().add(
                            SelectReciter(reciter.id),
                          );
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens a bottom sheet with the tafsir text for [verseKey], choosing the
/// tafsir resource based on [isBangla].
void openTafsirSheet(BuildContext context, String verseKey, bool isBangla) {
  final resourceId = isBangla
      ? banglaTafsirResourceId
      : englishTafsirResourceId;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider(
      create: (_) =>
          TafsirBloc(tafsirResourceId: resourceId)..add(LoadTafsir(verseKey)),
      child: const TafsirSheet(),
    ),
  );
}

class TafsirSheet extends StatelessWidget {
  const TafsirSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appText.tafsirTitle,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10.h),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 420.h),
              child: BlocBuilder<TafsirBloc, TafsirState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.h),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColor.primary,
                        ),
                      ),
                    );
                  }
                  if (state.hasError) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.h),
                      child: Center(
                        child: Text(
                          appText.quranLoadError,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    );
                  }
                  return SingleChildScrollView(
                    child: Text(
                      state.text,
                      style: TextStyle(fontSize: 13.sp, height: 1.5),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when the user tries to play recitation that is not on the device.
/// Explains that a connection is needed, downloads the whole surah (Bismillah
/// included) on confirmation, and resolves to `true` once the audio is saved
/// so the caller can start playback.
Future<bool> showSurahAudioSheet(
  BuildContext context, {
  required SurahAudioDownloadBloc downloadBloc,
  required int reciterId,
  required int surahNo,
  required int totalAyah,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: downloadBloc,
      child: _SurahAudioSheet(
        reciterId: reciterId,
        surahNo: surahNo,
        totalAyah: totalAyah,
      ),
    ),
  );
  return result ?? false;
}

class _SurahAudioSheet extends StatelessWidget {
  const _SurahAudioSheet({
    required this.reciterId,
    required this.surahNo,
    required this.totalAyah,
  });

  final int reciterId;
  final int surahNo;
  final int totalAyah;

  void _start(BuildContext context) {
    context.read<SurahAudioDownloadBloc>().add(
      StartSurahAudioDownload(
        reciterId: reciterId,
        surahNo: surahNo,
        totalAyah: totalAyah,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return BlocConsumer<SurahAudioDownloadBloc, SurahAudioDownloadState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == SurahAudioDownloadStatus.complete,
      listener: (context, state) => Navigator.of(context).pop(true),
      builder: (context, state) {
        final isDownloading =
            state.status == SurahAudioDownloadStatus.downloading;
        final hasFailed = state.status == SurahAudioDownloadStatus.failed;
        final percent = state.progress == null
            ? null
            : (state.progress! * 100).round();

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.wifi_rounded,
                      color: AppColor.primary,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      appText.quranAudioModalTitle,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColor.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  appText.quranAudioModalBody,
                  style: TextStyle(
                    fontSize: 13.sp,
                    height: 1.5,
                    color: const Color(0xFF5A6350),
                  ),
                ),
                SizedBox(height: 18.h),
                if (isDownloading) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: LinearProgressIndicator(
                      value: state.progress,
                      minHeight: 8.h,
                      backgroundColor: const Color(0xFFE0E6CC),
                      color: AppColor.primary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '${appText.quranDownloadSurahAudio}  ${percent ?? 0}%',
                    style: TextStyle(fontSize: 12.sp, color: AppColor.primary),
                  ),
                ] else ...[
                  if (hasFailed) ...[
                    Text(
                      appText.quranAudioDownloadFailed,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.red.shade400,
                      ),
                    ),
                    SizedBox(height: 12.h),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: FilledButton(
                      onPressed: () => _start(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26.r),
                        ),
                      ),
                      child: Text(
                        hasFailed
                            ? appText.tryAgain
                            : appText.quranAudioModalDownloadCta,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      appText.offlineQuranNotNow,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: const Color(0xFF7A8368),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Reader display settings: separate Arabic / translation zoom, visibility
/// toggles, and the translation-edition picker (with per-edition download).
/// Pass the ancestor [QuranTranslationBloc] explicitly — a bottom sheet is a
/// separate route.
void showQuranReaderSettingsSheet(
  BuildContext context, {
  required QuranTranslationBloc bloc,
}) {
  bloc.add(const LoadTranslationEditions());
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: const _QuranReaderSettingsSheet(),
    ),
  );
}

class _QuranReaderSettingsSheet extends StatelessWidget {
  const _QuranReaderSettingsSheet();

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return SafeArea(
      child: BlocBuilder<QuranTranslationBloc, QuranTranslationState>(
        builder: (context, state) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 560.h),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 20.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appText.quranReaderSettingsTitle,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColor.primary,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  _SettingLabel(appText.quranArabicSizeLabel),
                  const QuranZoomControl(target: QuranZoomTarget.arabic),
                  SizedBox(height: 8.h),
                  _SettingLabel(appText.quranTranslationSizeLabel),
                  const QuranZoomControl(target: QuranZoomTarget.translation),
                  SizedBox(height: 6.h),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    activeColor: AppColor.primary,
                    title: Text(
                      appText.quranShowTranslationLabel,
                      style: TextStyle(fontSize: 13.sp),
                    ),
                    value: state.showTranslation,
                    onChanged: (v) => context.read<QuranTranslationBloc>().add(
                      SetShowTranslation(v ?? true),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  _SettingLabel(appText.quranTranslationLabel),
                  SizedBox(height: 4.h),
                  for (final edition in kTranslationEditions)
                    _EditionRow(edition: edition, state: state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SettingLabel extends StatelessWidget {
  const _SettingLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF5A6350),
        ),
      ),
    );
  }
}

class _EditionRow extends StatelessWidget {
  const _EditionRow({required this.edition, required this.state});

  final TranslationEdition edition;
  final QuranTranslationState state;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bloc = context.read<QuranTranslationBloc>();
    final selected = state.selectedEditionId == edition.id;
    final downloaded =
        edition.isBuiltIn || state.downloadedEditionIds.contains(edition.id);
    final dl = state.editionDownload?.editionId == edition.id
        ? state.editionDownload
        : null;
    final isDownloading = dl != null && !dl.failed;

    Widget trailing;
    if (isDownloading) {
      final pct = dl.fraction == null ? 0 : (dl.fraction! * 100).round();
      trailing = Text(
        '${appText.quranEditionDownloading} $pct%',
        style: TextStyle(fontSize: 11.sp, color: AppColor.primary),
      );
    } else if (!downloaded) {
      trailing = TextButton(
        onPressed: () => bloc.add(DownloadTranslationEdition(edition)),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          dl?.failed == true
              ? appText.tryAgain
              : appText.quranDownloadEditionCta,
          style: TextStyle(fontSize: 12.sp, color: AppColor.primary),
        ),
      );
    } else if (selected) {
      trailing = const Icon(Icons.check_circle, color: AppColor.primary);
    } else if (!edition.isBuiltIn) {
      trailing = InkWell(
        onTap: () => bloc.add(DeleteTranslationEdition(edition.id)),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Icon(
            Icons.delete_outline_rounded,
            size: 18.sp,
            color: const Color(0xFF9AA187),
          ),
        ),
      );
    } else {
      trailing = const SizedBox.shrink();
    }

    return InkWell(
      onTap: downloaded && !isDownloading
          ? () => bloc.add(SelectTranslationEdition(edition.id))
          : null,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    edition.name,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      color: selected
                          ? AppColor.primary
                          : const Color(0xFF3A4032),
                    ),
                  ),
                  Text(
                    edition.languageName,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFF9AA187),
                    ),
                  ),
                  if (isDownloading) ...[
                    SizedBox(height: 6.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6.r),
                      child: LinearProgressIndicator(
                        value: dl.fraction,
                        minHeight: 4.h,
                        backgroundColor: const Color(0xFFE0E6CC),
                        color: AppColor.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8.w),
            trailing,
          ],
        ),
      ),
    );
  }
}
