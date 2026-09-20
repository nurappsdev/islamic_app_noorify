import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/hadith/data/ebook_downloader.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/ebook.dart';

import 'ebook_download_event.dart';
import 'ebook_download_state.dart';

export 'ebook_download_event.dart';
export 'ebook_download_state.dart';

class EbookDownloadBloc extends Bloc<EbookDownloadEvent, EbookDownloadState> {
  EbookDownloadBloc(this._ebook, this._downloader)
    : super(const EbookDownloadState()) {
    on<CheckEbookDownload>(_onCheck);
    on<StartEbookDownload>(_onStart);
  }

  final Ebook _ebook;
  final EbookDownloader _downloader;

  Future<void> _onCheck(
    CheckEbookDownload event,
    Emitter<EbookDownloadState> emit,
  ) async {
    final file = await _downloader.existing(_ebook);
    emit(
      file == null
          ? const EbookDownloadState(status: EbookDownloadStatus.idle)
          : EbookDownloadState(
              status: EbookDownloadStatus.downloaded,
              filePath: file.path,
            ),
    );
  }

  Future<void> _onStart(
    StartEbookDownload event,
    Emitter<EbookDownloadState> emit,
  ) async {
    if (state.status == EbookDownloadStatus.downloading) return;
    emit(const EbookDownloadState(status: EbookDownloadStatus.downloading));
    try {
      final file = await _downloader.download(
        _ebook,
        onProgress: (progress) {
          if (!emit.isDone) {
            emit(
              EbookDownloadState(
                status: EbookDownloadStatus.downloading,
                progress: progress,
              ),
            );
          }
        },
      );
      emit(
        EbookDownloadState(
          status: EbookDownloadStatus.downloaded,
          filePath: file.path,
        ),
      );
    } catch (_) {
      emit(const EbookDownloadState(status: EbookDownloadStatus.failed));
    }
  }
}
