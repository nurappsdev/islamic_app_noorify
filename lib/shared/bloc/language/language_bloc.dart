import 'package:bloc/bloc.dart';

import 'language_event.dart';
import 'language_state.dart';

export 'language_event.dart';
export 'language_state.dart';

class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  LanguageBloc() : super(const LanguageState()) {
    on<UpdateLanguage>((event, emit) {
      if (state.language == event.language) return;
      emit(state.copyWith(language: event.language));
    });
  }
}
