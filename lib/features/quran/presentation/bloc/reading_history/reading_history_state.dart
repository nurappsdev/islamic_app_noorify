import 'package:islami_app_noorify/features/quran/domain/reading_history_entry.dart';

class ReadingHistoryState {
  const ReadingHistoryState({this.isLoading = true, this.entries = const []});

  final bool isLoading;
  final List<ReadingHistoryEntry> entries;

  ReadingHistoryState copyWith({
    bool? isLoading,
    List<ReadingHistoryEntry>? entries,
  }) {
    return ReadingHistoryState(
      isLoading: isLoading ?? this.isLoading,
      entries: entries ?? this.entries,
    );
  }
}
