import 'package:islami_app_noorify/features/hadith/data/models/hadith_book_reference.dart';
import 'package:islami_app_noorify/features/hadith/data/models/hadith_entry.dart';

enum HadithBookStatus {
  /// Looking on disk for an existing copy.
  checking,

  /// Not downloaded yet — show the download prompt.
  needsDownload,

  /// Parsing the bundled file into the local database.
  downloading,

  /// Book is on the device; [entries] is populated.
  ready,

  /// Download attempt failed.
  failed,
}

class HadithBookState {
  const HadithBookState({
    this.status = HadithBookStatus.checking,
    this.done = 0,
    this.total = 0,
    this.entries = const [],
    this.reference,
    this.errorMessage,
  });

  final HadithBookStatus status;
  final int done;
  final int total;
  final List<HadithEntry> entries;
  final HadithBookReference? reference;
  final String? errorMessage;

  double? get progress => total > 0 ? (done / total).clamp(0.0, 1.0) : null;

  HadithBookState copyWith({
    HadithBookStatus? status,
    int? done,
    int? total,
    List<HadithEntry>? entries,
    HadithBookReference? reference,
    String? errorMessage,
  }) {
    return HadithBookState(
      status: status ?? this.status,
      done: done ?? this.done,
      total: total ?? this.total,
      entries: entries ?? this.entries,
      reference: reference ?? this.reference,
      errorMessage: errorMessage,
    );
  }
}
