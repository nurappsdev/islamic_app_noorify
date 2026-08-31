import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/quran/data/services/quran_audio_downloader.dart';

import 'surah_audio_download_event.dart';
import 'surah_audio_download_state.dart';

export 'surah_audio_download_event.dart';
export 'surah_audio_download_state.dart';

class SurahAudioDownloadBloc
    extends Bloc<SurahAudioDownloadEvent, SurahAudioDownloadState> {
  SurahAudioDownloadBloc({QuranAudioDownloader? downloader})
    : _downloader = downloader ?? QuranAudioDownloader(),
      super(const SurahAudioDownloadState()) {
    on<CheckSurahAudioStatus>(_onCheck);
    on<StartSurahAudioDownload>(_onStart);
  }

  final QuranAudioDownloader _downloader;

  Future<void> _onCheck(
    CheckSurahAudioStatus event,
    Emitter<SurahAudioDownloadState> emit,
  ) async {
    if (state.status == SurahAudioDownloadStatus.downloading) return;
    emit(state.copyWith(status: SurahAudioDownloadStatus.checking));
    final progress = await _downloader.surahStatus(
      reciterId: event.reciterId,
      surahNo: event.surahNo,
      totalAyah: event.totalAyah,
    );
    final complete = await _downloader.isSurahComplete(
      reciterId: event.reciterId,
      surahNo: event.surahNo,
      totalAyah: event.totalAyah,
    );
    emit(
      SurahAudioDownloadState(
        status: complete
            ? SurahAudioDownloadStatus.complete
            : SurahAudioDownloadStatus.idle,
        done: progress.done,
        total: progress.total,
      ),
    );
  }

  Future<void> _onStart(
    StartSurahAudioDownload event,
    Emitter<SurahAudioDownloadState> emit,
  ) async {
    if (state.status == SurahAudioDownloadStatus.downloading) return;
    emit(
      SurahAudioDownloadState(
        status: SurahAudioDownloadStatus.downloading,
        done: state.done,
        total: event.totalAyah,
      ),
    );
    try {
      await emit.forEach<AudioDownloadProgress>(
        _downloader.downloadSurah(
          reciterId: event.reciterId,
          surahNo: event.surahNo,
        ),
        onData: (progress) => SurahAudioDownloadState(
          status: SurahAudioDownloadStatus.downloading,
          done: progress.done,
          total: progress.total,
        ),
      );
      emit(state.copyWith(status: SurahAudioDownloadStatus.complete));
    } catch (error) {
      emit(
        state.copyWith(
          status: SurahAudioDownloadStatus.failed,
          errorMessage: error is AudioDownloadException
              ? error.message
              : '$error',
        ),
      );
    }
  }
}
