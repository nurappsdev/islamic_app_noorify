import 'package:bloc/bloc.dart';

import 'app_preferences_state.dart';

export 'app_preferences_state.dart';

class AppPreferencesCubit extends Cubit<AppPreferencesState> {
  AppPreferencesCubit() : super(const AppPreferencesState());

  void updateFontSize(AppFontSize size) {
    if (state.fontSize == size) return;
    emit(state.copyWith(fontSize: size));
  }

  void toggleDarkTheme() {
    emit(state.copyWith(darkThemeEnabled: !state.darkThemeEnabled));
  }

  void updateDarkThemeEnabled(bool enabled) {
    if (state.darkThemeEnabled == enabled) return;
    emit(state.copyWith(darkThemeEnabled: enabled));
  }
}
