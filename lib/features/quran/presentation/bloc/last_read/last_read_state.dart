import 'package:tuhfatul_muslim/features/quran/domain/reading_history_entry.dart';

/// Where "Continue Reading" opens the reader.
typedef QuranContinueTarget = ({int surahNo, int ayahNo, String surahName});

class LastReadState {
  const LastReadState({this.isLoading = true, this.entry, this.continueFrom});

  final bool isLoading;

  /// The last ayah read, for display.
  final ReadingHistoryEntry? entry;

  /// The ayah to continue from — the server's `continueFrom` when its last
  /// read is the latest; otherwise [entry] itself.
  final QuranContinueTarget? continueFrom;

  /// Where tapping "Continue Reading" should go; null before any reading.
  QuranContinueTarget? get target =>
      continueFrom ??
      (entry == null
          ? null
          : (
              surahNo: entry!.surahNo,
              ayahNo: entry!.ayahNo,
              surahName: entry!.surahName,
            ));

  LastReadState copyWith({bool? isLoading, ReadingHistoryEntry? entry}) {
    return LastReadState(
      isLoading: isLoading ?? this.isLoading,
      entry: entry ?? this.entry,
      continueFrom: continueFrom,
    );
  }
}
