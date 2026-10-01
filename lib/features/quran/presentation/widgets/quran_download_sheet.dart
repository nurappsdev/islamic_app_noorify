import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/offline_quran/offline_quran_bloc.dart';
import 'quran_design.dart';
import 'quran_modal.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';

Future<void> showQuranDownload(
  BuildContext context, {
  OfflineQuranBloc? bloc,
}) async {
  if (bloc != null && bloc.state.status != OfflineQuranStatus.preparing) {
    bloc.add(const CheckOfflineQuran());
  }
  await showQuranModal<void>(
    context,
    bloc == null
        ? BlocProvider(
            create: (_) => OfflineQuranBloc()..add(const CheckOfflineQuran()),
            child: const QuranDownloadSheet(),
          )
        : BlocProvider.value(value: bloc, child: const QuranDownloadSheet()),
    heightFactor: .72,
  );
}

class QuranDownloadSheet extends StatelessWidget {
  const QuranDownloadSheet({super.key});
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: quranBorder,
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: BlocBuilder<OfflineQuranBloc, OfflineQuranState>(
          builder: (context, state) {
            final downloading = state.status == OfflineQuranStatus.preparing;
            final ready = state.status == OfflineQuranStatus.ready;
            return Column(
              children: [
                QuranSheetHeading(AppText.of(context).quranTajweedTitle),
                // TODO(backend): provide a versioned Tajweed document/content URL,
                // file size and checksum before offering a Tajweed-specific download.
                Text(
                  AppText.of(context).quranTajweedUnavailable,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: quranInk, height: 1.5),
                ),
                const SizedBox(height: 28),
                Image.asset('assets/images/quran/Quran.png', height: 180),
                const SizedBox(height: 24),
                Text(
                  ready
                      ? AppText.of(context).quranReadyOffline
                      : downloading
                      ? AppText.of(context).quranDownloading
                      : AppText.of(context).quranOfflineTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 21, color: quranInk),
                ),
                const SizedBox(height: 18),
                if (downloading || state.status == OfflineQuranStatus.checking)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: LinearProgressIndicator(
                          minHeight: 56,
                          color: quranInk,
                          backgroundColor: quranOlive,
                          value: downloading ? state.progress : null,
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 60,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: quranBorder,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white),
                        ),
                        child: Text(
                          state.progress == null
                              ? '…'
                              : context.localizedDigits(
                                  '${(state.progress! * 100).round()}%',
                                ),
                          style: const TextStyle(color: quranInk),
                        ),
                      ),
                    ],
                  ),
                if (state.status == OfflineQuranStatus.failed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(AppText.of(context).quranDownloadInterrupted),
                  ),
                if (!downloading && state.status != OfflineQuranStatus.checking)
                  FilledButton(
                    onPressed: ready
                        ? () => Navigator.pop(context)
                        : () => context.read<OfflineQuranBloc>().add(
                            const PrepareOfflineQuran(),
                          ),
                    style: FilledButton.styleFrom(backgroundColor: quranOlive),
                    child: Text(
                      ready
                          ? AppText.of(context).commonDone
                          : state.status == OfflineQuranStatus.failed
                          ? AppText.of(context).quranRetryDownload
                          : AppText.of(context).quranDownloadQuran,
                    ),
                  ),
                if (downloading)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      AppText.of(context).quranKeepScreenOpen,
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
