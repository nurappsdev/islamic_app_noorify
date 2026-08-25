import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/app_route_observer.dart';
import 'core/constants/app_routes.dart';
import 'core/constants/route_names.dart';
import 'core/bloc/app_preferences/app_preferences_bloc.dart';
import 'core/theme/brand_colors.dart';
import 'core/utils/app_text.dart';
import 'shared/bloc/language/language_bloc.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppText.load();
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LanguageBloc()),
        BlocProvider(create: (_) => AppPreferencesBloc()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.initialRoute});

  final String? initialRoute;

  @override
  Widget build(BuildContext context) {
    final appPreferences = context.watch<AppPreferencesBloc>().state;

    return ScreenUtilInit(
      designSize: const Size(375, 812), // Adjust this to your design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: appNavigatorKey,
          navigatorObservers: [appRouteObserver],
          title: 'Noorify',
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color.fromRGBO(30, 168, 184, 1),
            scaffoldBackgroundColor: BrandColors.screenBackground,
            textTheme: GoogleFonts.plusJakartaSansTextTheme(),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorSchemeSeed: BrandColors.primary,
            textTheme: GoogleFonts.plusJakartaSansTextTheme(
              ThemeData(brightness: Brightness.dark).textTheme,
            ),
          ),
          themeMode: appPreferences.darkThemeEnabled
              ? ThemeMode.dark
              : ThemeMode.light,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            final textScale = appFontScale(appPreferences.fontSize);
            return MediaQuery(
              data: media.copyWith(textScaler: TextScaler.linear(textScale)),
              child: child ?? const SizedBox.shrink(),
            );
          },
          initialRoute: initialRoute ?? RouteNames.splash,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        );
      },
    );
  }
}
