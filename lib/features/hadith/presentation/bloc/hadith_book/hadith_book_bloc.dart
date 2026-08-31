import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/hadith/data/hadith_book_downloader.dart';
import 'package:islami_app_noorify/features/hadith/data/hadith_database.dart';
import 'package:islami_app_noorify/features/hadith/data/models/hadith_book.dart';
import 'package:islami_app_noorify/features/hadith/data/models/hadith_book_reference.dart';

import 'hadith_book_event.dart';
import 'hadith_book_state.dart';

export 'hadith_book_event.dart';
export 'hadith_book_state.dart';

class HadithBookBloc extends Bloc<HadithBookEvent, HadithBookState> {
  HadithBookBloc({
    required this.book,
    HadithDatabase? database,
    HadithBookDownloader? downloader,
  }) : _database = database ?? HadithDatabase(),
       _downloader = downloader ?? HadithBookDownloader(),
       super(const HadithBookState()) {
    on<CheckHadithBook>(_onCheck);
    on<DownloadHadithBook>(_onDownload);
  }

  final HadithBook book;
  final HadithDatabase _database;
  final HadithBookDownloader _downloader;

  Future<HadithBookReference?> _loadReference() async {
    final path = book.assetReferenceXmlPath;
    return path == null ? null : HadithBookReference.load(path);
  }

  Future<void> _onCheck(
    CheckHadithBook event,
    Emitter<HadithBookState> emit,
  ) async {
    emit(const HadithBookState(status: HadithBookStatus.checking));
    if (await _database.isBookReady(book.slug)) {
      emit(
        HadithBookState(
          status: HadithBookStatus.ready,
          entries: await _database.entries(book.slug),
          reference: await _loadReference(),
        ),
      );
    } else {
      emit(const HadithBookState(status: HadithBookStatus.needsDownload));
    }
  }

  Future<void> _onDownload(
    DownloadHadithBook event,
    Emitter<HadithBookState> emit,
  ) async {
    if (state.status == HadithBookStatus.downloading) return;
    emit(const HadithBookState(status: HadithBookStatus.downloading));
    try {
      await emit.forEach<HadithSetupProgress>(
        _downloader.download(book),
        onData: (progress) => HadithBookState(
          status: HadithBookStatus.downloading,
          done: progress.done,
          total: progress.total,
        ),
      );
      if (await _database.isBookReady(book.slug)) {
        emit(
          HadithBookState(
            status: HadithBookStatus.ready,
            entries: await _database.entries(book.slug),
            reference: await _loadReference(),
          ),
        );
      } else {
        emit(const HadithBookState(status: HadithBookStatus.failed));
      }
    } catch (error) {
      emit(
        HadithBookState(
          status: HadithBookStatus.failed,
          errorMessage: error is HadithSetupException ? error.message : '$error',
        ),
      );
    }
  }
}
