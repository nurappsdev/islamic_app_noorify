import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/core/bloc/app_preferences/app_preferences_cubit.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_cubit.dart';
import 'package:islami_app_noorify/features/auth/presentation/bloc/sign_in/sign_in_cubit.dart';
import 'package:islami_app_noorify/features/auth/presentation/bloc/sign_up/sign_up_cubit.dart';

void main() {
  group('AppPreferencesCubit', () {
    test('starts with medium text and light theme', () {
      final cubit = AppPreferencesCubit();
      addTearDown(cubit.close);

      expect(cubit.state.fontSize, AppFontSize.medium);
      expect(cubit.state.darkThemeEnabled, isFalse);
    });

    test('updates font size and theme preference', () {
      final cubit = AppPreferencesCubit();
      addTearDown(cubit.close);

      cubit.updateFontSize(AppFontSize.large);
      cubit.updateDarkThemeEnabled(true);

      expect(cubit.state.fontSize, AppFontSize.large);
      expect(cubit.state.darkThemeEnabled, isTrue);
      expect(appFontScale(cubit.state.fontSize), 1.15);
    });
  });

  group('LanguageCubit', () {
    test('starts in english and updates language', () {
      final cubit = LanguageCubit();
      addTearDown(cubit.close);

      expect(cubit.state.language, AppLanguage.english);

      cubit.update(AppLanguage.bangla);

      expect(cubit.state.language, AppLanguage.bangla);
    });
  });

  group('SignInCubit', () {
    test('toggles password visibility and loading', () {
      final cubit = SignInCubit();
      addTearDown(cubit.close);

      expect(cubit.state.obscurePassword, isTrue);
      expect(cubit.state.isLoading, isFalse);

      cubit.toggleObscurePassword();
      cubit.setLoading(true);

      expect(cubit.state.obscurePassword, isFalse);
      expect(cubit.state.isLoading, isTrue);
    });
  });

  group('SignUpCubit', () {
    test('toggles form state', () {
      final cubit = SignUpCubit();
      addTearDown(cubit.close);

      expect(cubit.state.obscurePassword, isTrue);
      expect(cubit.state.obscureConfirm, isTrue);
      expect(cubit.state.saveInfo, isTrue);
      expect(cubit.state.isLoading, isFalse);

      cubit.toggleObscurePassword();
      cubit.toggleObscureConfirm();
      cubit.setSaveInfo(false);
      cubit.setLoading(true);

      expect(cubit.state.obscurePassword, isFalse);
      expect(cubit.state.obscureConfirm, isFalse);
      expect(cubit.state.saveInfo, isFalse);
      expect(cubit.state.isLoading, isTrue);
    });
  });
}
