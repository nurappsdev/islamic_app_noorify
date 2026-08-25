import 'package:bloc/bloc.dart';

import 'app_preferences_event.dart';
import 'app_preferences_state.dart';

export 'app_preferences_event.dart';
export 'app_preferences_state.dart';

class AppPreferencesBloc
    extends Bloc<AppPreferencesEvent, AppPreferencesState> {
  AppPreferencesBloc() : super(const AppPreferencesState()) {
    on<UpdateFontSize>((event, emit) {
      if (state.fontSize == event.size) return;
      emit(state.copyWith(fontSize: event.size));
    });

    on<ToggleDarkTheme>((event, emit) {
      emit(state.copyWith(darkThemeEnabled: !state.darkThemeEnabled));
    });

    on<UpdateDarkThemeEnabled>((event, emit) {
      if (state.darkThemeEnabled == event.enabled) return;
      emit(state.copyWith(darkThemeEnabled: event.enabled));
    });
  }
}
