import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dua_settings_event.dart';
import 'dua_settings_state.dart';

export 'dua_settings_event.dart';
export 'dua_settings_state.dart';

class DuaSettingsBloc extends Bloc<DuaSettingsEvent, DuaSettingsState> {
  DuaSettingsBloc() : super(const DuaSettingsState()) {
    on<LoadDuaSettings>(_onLoad);
    on<SetDuaFontSize>(_onSetFontSize);
    on<ToggleDuaArabic>(_onToggleArabic);
    on<ToggleDuaTranslation>(_onToggleTranslation);
    on<ToggleDuaTransliteration>(_onToggleTransliteration);
  }

  static const _fontSizeKey = 'dua_font_size';
  static const _showArabicKey = 'dua_show_arabic';
  static const _showTranslationKey = 'dua_show_translation';
  static const _showTransliterationKey = 'dua_show_transliteration';

  Future<void> _onLoad(
    LoadDuaSettings event,
    Emitter<DuaSettingsState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    emit(
      state.copyWith(
        fontSizeMultiplier: prefs.getDouble(_fontSizeKey) ?? 1.0,
        showArabic: prefs.getBool(_showArabicKey) ?? true,
        showTranslation: prefs.getBool(_showTranslationKey) ?? true,
        showTransliteration: prefs.getBool(_showTransliterationKey) ?? true,
      ),
    );
  }

  Future<void> _onSetFontSize(
    SetDuaFontSize event,
    Emitter<DuaSettingsState> emit,
  ) async {
    emit(state.copyWith(fontSizeMultiplier: event.multiplier));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, event.multiplier);
  }

  Future<void> _onToggleArabic(
    ToggleDuaArabic event,
    Emitter<DuaSettingsState> emit,
  ) async {
    emit(state.copyWith(showArabic: event.show));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showArabicKey, event.show);
  }

  Future<void> _onToggleTranslation(
    ToggleDuaTranslation event,
    Emitter<DuaSettingsState> emit,
  ) async {
    emit(state.copyWith(showTranslation: event.show));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showTranslationKey, event.show);
  }

  Future<void> _onToggleTransliteration(
    ToggleDuaTransliteration event,
    Emitter<DuaSettingsState> emit,
  ) async {
    emit(state.copyWith(showTransliteration: event.show));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showTransliterationKey, event.show);
  }
}
