import 'package:bloc/bloc.dart';

import 'language_state.dart';

export 'language_state.dart';

class LanguageCubit extends Cubit<LanguageState> {
  LanguageCubit() : super(const LanguageState());

  void update(AppLanguage language) {
    if (state.language == language) return;
    emit(state.copyWith(language: language));
  }
}
