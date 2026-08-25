import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/core/bloc/app_preferences/app_preferences_bloc.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';
import 'package:islami_app_noorify/features/auth/presentation/bloc/sign_in/sign_in_bloc.dart';
import 'package:islami_app_noorify/features/auth/presentation/bloc/sign_up/sign_up_bloc.dart'
    as sign_up;

void main() {
  group('AppPreferencesBloc', () {
    test('starts with medium text and light theme', () {
      final bloc = AppPreferencesBloc();
      addTearDown(bloc.close);

      expect(bloc.state.fontSize, AppFontSize.medium);
      expect(bloc.state.darkThemeEnabled, isFalse);
    });

    test('updates font size and theme preference', () async {
      final bloc = AppPreferencesBloc();
      addTearDown(bloc.close);

      bloc.add(const UpdateFontSize(AppFontSize.large));
      bloc.add(const UpdateDarkThemeEnabled(true));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.fontSize, AppFontSize.large);
      expect(bloc.state.darkThemeEnabled, isTrue);
      expect(appFontScale(bloc.state.fontSize), 1.15);
    });
  });

  group('LanguageBloc', () {
    test('starts in english and updates language', () async {
      final bloc = LanguageBloc();
      addTearDown(bloc.close);

      expect(bloc.state.language, AppLanguage.english);

      bloc.add(const UpdateLanguage(AppLanguage.bangla));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.language, AppLanguage.bangla);
    });
  });

  group('SignInBloc', () {
    test('toggles password visibility and loading', () async {
      final bloc = SignInBloc();
      addTearDown(bloc.close);

      expect(bloc.state.obscurePassword, isTrue);
      expect(bloc.state.isLoading, isFalse);

      bloc.add(const ToggleObscurePassword());
      bloc.add(const SetLoading(true));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.obscurePassword, isFalse);
      expect(bloc.state.isLoading, isTrue);
    });
  });

  group('SignUpBloc', () {
    test('toggles form state', () async {
      final bloc = sign_up.SignUpBloc();
      addTearDown(bloc.close);

      expect(bloc.state.obscurePassword, isTrue);
      expect(bloc.state.obscureConfirm, isTrue);
      expect(bloc.state.saveInfo, isTrue);
      expect(bloc.state.isLoading, isFalse);

      bloc.add(const sign_up.ToggleObscurePassword());
      bloc.add(const sign_up.ToggleObscureConfirm());
      bloc.add(const sign_up.SetSaveInfo(false));
      bloc.add(const sign_up.SetLoading(true));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.obscurePassword, isFalse);
      expect(bloc.state.obscureConfirm, isFalse);
      expect(bloc.state.saveInfo, isFalse);
      expect(bloc.state.isLoading, isTrue);
    });
  });
}
