import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_route_observer.dart';
import 'core/constants/app_routes.dart';
import 'core/constants/route_names.dart';
import 'core/storage/hive_service.dart';
import 'core/bloc/app_preferences/app_preferences_bloc.dart';
import 'core/theme/dark_theme.dart';
import 'core/theme/light_theme.dart';
import 'core/utils/app_text.dart';
import 'features/alarm/data/services/alarm_scheduler.dart';
import 'features/alarm/domain/entities/alarm_ring_payload.dart';
import 'features/alarm/presentation/screens/alarm_ringing_screen.dart';
import 'features/quran/data/services/quran_audio_handler.dart';
import 'shared/bloc/language/language_bloc.dart';
import 'package:flutter/services.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await HiveService.init();
  await AppText.load();
  quranAudioHandler = await AudioService.init(
    builder: QuranAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.islami_app_noorify.quran.audio',
      androidNotificationChannelName: 'Quran recitation',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  final savedDarkTheme =
      (await SharedPreferences.getInstance()).getBool(
        AppPreferencesBloc.darkThemeKey,
      ) ??
      false;

  await AlarmScheduler.init();
  // Alarms are re-armed from the server's list whenever the alarm screen
  // loads (see `AlarmListBloc`), not from the local cache here: the cache
  // holds client-made ids, so re-arming it too made every alarm ring twice.
  // Tapping the alarm notification — or its Stop/Snooze buttons — opens the
  // ringing screen, which is where stopping/snoozing reliably silences the
  // alarm. A Stop/Snooze press carries its action so the screen applies it
  // straight away. If that screen is already up it handles the event itself.
  alarmNotificationEvents.stream.listen((event) {
    if (AlarmRingingScreen.isShowing(event.payload.alarmId)) return;
    appNavigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => AlarmRingingScreen(
          payload: event.payload,
          autoAction: event.action == 'open' ? null : event.action,
        ),
      ),
    );
  });
  final launchDetails = await AlarmScheduler.launchDetails();
  final launchPayload = launchDetails?.didNotificationLaunchApp == true
      ? AlarmRingPayload.tryDecode(launchDetails?.notificationResponse?.payload)
      : null;
  final launchAction = AlarmScheduler.actionFor(
    launchDetails?.notificationResponse?.actionId,
  );

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LanguageBloc()),
        BlocProvider(
          create: (_) => AppPreferencesBloc(darkThemeEnabled: savedDarkTheme),
        ),
      ],
      child: const MyApp(),
    ),
  );

  if (launchPayload != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appNavigatorKey.currentState?.push(
        MaterialPageRoute<void>(
          builder: (_) => AlarmRingingScreen(
            payload: launchPayload,
            autoAction: launchAction,
          ),
        ),
      );
    });
  }
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
          theme: lightTheme(),
          darkTheme: darkTheme(),
          themeAnimationDuration: const Duration(milliseconds: 300),
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
