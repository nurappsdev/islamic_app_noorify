import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/constants/app_route_observer.dart';
import 'core/constants/app_routes.dart';
import 'core/constants/route_names.dart';
import 'core/bloc/app_preferences/app_preferences_bloc.dart';
import 'core/theme/app_typography.dart';
import 'core/theme/dark_theme.dart';
import 'core/theme/light_theme.dart';
import 'shared/bloc/language/language_bloc.dart';

/// Shared application shell. Platform bootstraps initialize their own
/// services and then run this exact widget tree.
final appNavigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.initialRoute});

  final String? initialRoute;

  @override
  Widget build(BuildContext context) {
    return _buildApp(context);
  }

  Widget _buildApp(BuildContext context) {
    final appPreferences = context.watch<AppPreferencesBloc>().state;
    final language = context.watch<LanguageBloc>().state.language;
    final fontFamily = appFontFamilyFor(language);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: appNavigatorKey,
          navigatorObservers: [appRouteObserver],
          title: 'Tuhfatul Muslim',
          theme: lightTheme(fontFamily: fontFamily),
          darkTheme: darkTheme(fontFamily: fontFamily),
          themeAnimationDuration: const Duration(milliseconds: 300),
          themeMode: appPreferences.darkThemeEnabled
              ? ThemeMode.dark
              : ThemeMode.light,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            final textScale = appFontScale(appPreferences.fontSize);
            final content = MediaQuery(
              data: media.copyWith(textScaler: TextScaler.linear(textScale)),
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontFamilyFallback: appFontFamilyFallback,
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            );
            return appPreferences.darkThemeEnabled
                ? AnnotatedRegion<SystemUiOverlayStyle>(
                    value: SystemUiOverlayStyle.light,
                    child: content,
                  )
                : content;
          },
          initialRoute: initialRoute ?? RouteNames.splash,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        );
      },
    );
  }
}
