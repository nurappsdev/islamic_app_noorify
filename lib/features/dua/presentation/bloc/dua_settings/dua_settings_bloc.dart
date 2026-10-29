import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dua_settings_event.dart';
import 'dua_settings_state.dart';

export 'dua_settings_event.dart';
export 'dua_settings_state.dart';

class DuaSettingsBloc extends Bloc<DuaSettingsEvent, DuaSettingsState> {
  DuaSettingsBloc() : super(const DuaSettingsState()) {
    on<LoadDuaSettings>(_onLoad);
    on<SetDuaArabicFontSize>(_onSetArabicFontSize);
    on<SetDuaTranslationFontSize>(_onSetTranslationFontSize);
    on<SetDuaFontSizes>(_onSetFontSizes);
    on<ToggleDuaArabic>(_onToggleArabic);
    on<ToggleDuaTranslation>(_onToggleTranslation);
    on<ToggleDuaTransliteration>(_onToggleTransliteration);
    on<ToggleDuaNarration>(_onToggleNarration);
    on<ToggleDuaReference>(_onToggleReference);
  }

  static const _arabicFontSizeKey = 'dua_arabic_font_size';
  static const _translationFontSizeKey = 'dua_translation_font_size';
  static const _showArabicKey = 'dua_show_arabic';
  static const _showTranslationKey = 'dua_show_translation';
  static const _showTransliterationKey = 'dua_show_transliteration';
  static const _showNarrationKey = 'dua_show_narration';
  static const _showReferenceKey = 'dua_show_reference';

  Future<void> _onLoad(
    LoadDuaSettings event,
    Emitter<DuaSettingsState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    emit(
      state.copyWith(
        arabicFontSize: prefs.getDouble(_arabicFontSizeKey) ?? 20.0,
        translationFontSize: prefs.getDouble(_translationFontSizeKey) ?? 12.0,
        showArabic: prefs.getBool(_showArabicKey) ?? true,
        showTranslation: prefs.getBool(_showTranslationKey) ?? true,
        showTransliteration: prefs.getBool(_showTransliterationKey) ?? true,
        showNarration: prefs.getBool(_showNarrationKey) ?? true,
        showReference: prefs.getBool(_showReferenceKey) ?? true,
      ),
    );
  }

  Future<void> _onSetArabicFontSize(
    SetDuaArabicFontSize event,
    Emitter<DuaSettingsState> emit,
  ) async {
    emit(state.copyWith(arabicFontSize: event.size));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_arabicFontSizeKey, event.size);
  }

  Future<void> _onSetTranslationFontSize(
    SetDuaTranslationFontSize event,
    Emitter<DuaSettingsState> emit,
  ) async {
    emit(state.copyWith(translationFontSize: event.size));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_translationFontSizeKey, event.size);
  }

  Future<void> _onSetFontSizes(
    SetDuaFontSizes event,
    Emitter<DuaSettingsState> emit,
  ) async {
    emit(
      state.copyWith(
        arabicFontSize: event.arabic,
        translationFontSize: event.translation,
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_arabicFontSizeKey, event.arabic);
    await prefs.setDouble(_translationFontSizeKey, event.translation);
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

  Future<void> _onToggleNarration(
    ToggleDuaNarration event,
    Emitter<DuaSettingsState> emit,
  ) async {
    emit(state.copyWith(showNarration: event.show));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showNarrationKey, event.show);
  }

  Future<void> _onToggleReference(
    ToggleDuaReference event,
    Emitter<DuaSettingsState> emit,
  ) async {
    emit(state.copyWith(showReference: event.show));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showReferenceKey, event.show);
  }
}
