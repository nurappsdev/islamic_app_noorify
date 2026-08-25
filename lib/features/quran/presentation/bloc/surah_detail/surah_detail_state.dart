import 'package:islami_app_noorify/features/quran/domain/surah_detail.dart';

class SurahDetailState {
  const SurahDetailState({
    this.isLoading = true,
    this.detail,
    this.hasError = false,
  });

  final bool isLoading;
  final SurahDetail? detail;
  final bool hasError;

  SurahDetailState copyWith({
    bool? isLoading,
    SurahDetail? detail,
    bool? hasError,
  }) {
    return SurahDetailState(
      isLoading: isLoading ?? this.isLoading,
      detail: detail ?? this.detail,
      hasError: hasError ?? this.hasError,
    );
  }
}
