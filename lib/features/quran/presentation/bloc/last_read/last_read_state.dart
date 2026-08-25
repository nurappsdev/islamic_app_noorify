import 'package:islami_app_noorify/features/quran/domain/reading_history_entry.dart';

class LastReadState {
  const LastReadState({this.isLoading = true, this.entry});

  final bool isLoading;
  final ReadingHistoryEntry? entry;

  LastReadState copyWith({bool? isLoading, ReadingHistoryEntry? entry}) {
    return LastReadState(
      isLoading: isLoading ?? this.isLoading,
      entry: entry ?? this.entry,
    );
  }
}
