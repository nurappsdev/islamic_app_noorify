import 'package:islami_app_noorify/features/quran/domain/reciter.dart';

class ReciterState {
  const ReciterState({
    this.isLoading = true,
    this.reciters = const [],
    this.selectedId,
  });

  final bool isLoading;
  final List<Reciter> reciters;
  final int? selectedId;

  String get selectedName {
    final id = selectedId;
    if (id == null) return '';
    for (final reciter in reciters) {
      if (reciter.id == id) return reciter.name;
    }
    return '';
  }

  ReciterState copyWith({
    bool? isLoading,
    List<Reciter>? reciters,
    int? selectedId,
  }) {
    return ReciterState(
      isLoading: isLoading ?? this.isLoading,
      reciters: reciters ?? this.reciters,
      selectedId: selectedId ?? this.selectedId,
    );
  }
}
