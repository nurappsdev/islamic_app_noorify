import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/bloc/app_preferences/app_preferences_bloc.dart';
import '../core/constants/route_names.dart';
import '../core/network/auth_refresh_interceptor.dart';
import '../core/services/app_startup.dart';
import '../core/storage/hive_service.dart';
import '../core/storage/session_cleaner.dart';
import '../core/utils/app_text.dart';
import '../features/alarm/data/services/alarm_migration.dart';
import '../features/alarm/data/services/alarm_scheduler.dart';
import '../features/alarm/data/services/alarm_sync.dart';
import '../features/alarm/domain/entities/alarm_ring_payload.dart';
import '../features/alarm/presentation/screens/alarm_ringing_screen.dart';
import '../features/amol_tracking/presentation/controllers/amol_sync.dart';
import '../features/amol_tracking/presentation/state/amol_day_clock.dart';
import '../features/dua/data/services/dua_read_completion_store.dart';
import '../features/dua/presentation/controllers/dua_reading_sync.dart';
import '../features/home/data/services/prayer_location_service.dart';
import '../features/home/domain/prayer_location.dart';
import '../features/prayer_widget/data/services/prayer_widget_service.dart';
import '../features/quran/data/services/quran_audio_handler.dart';
import '../features/quran/presentation/controllers/quran_reading_sync.dart';
import '../firebase_options.dart';
import '../main_app.dart';
import '../shared/bloc/language/language_bloc.dart';
import '../shared/services/firebase/firebase_service.dart';
import '../shared/services/firebase/firebase_token_service.dart';

/// The original Android/iOS bootstrap, kept separate so no native service is
/// initialized by the browser entry point.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive backs the authenticated session and is read while Home is built.
  // Keep these small, essential initializers before runApp so no route can
  // access an unopened box. They run concurrently and normally finish within
  // the requested 2–3 second native launch window.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final initialization = await Future.wait<dynamic>([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    HiveService.init(),
    AppText.load(),
    SharedPreferences.getInstance(),
  ]);
  final preferences = initialization[3] as SharedPreferences;
  final savedDarkTheme =
      preferences.getBool(AppPreferencesBloc.darkThemeKey) ?? false;
  final savedLanguage = LanguagePreference.read(preferences);
  final languageBloc = LanguageBloc(initialLanguage: savedLanguage);
  final appPreferencesBloc = AppPreferencesBloc(
    darkThemeEnabled: savedDarkTheme,
  );

  AuthRefreshInterceptor.onSessionExpired = () async {
    await SessionCleaner.clearUserData();
    appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
      RouteNames.signIn,
      (_) => false,
    );
  };

  // The essential storage/auth setup above makes the first Home build safe.
  // The remaining native services continue behind the Flutter splash instead
  // of holding Android's img_17-style launch screen for a long time.
  AppStartup.begin(_initializeServices(savedLanguage: savedLanguage));
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: languageBloc),
        BlocProvider.value(value: appPreferencesBloc),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _initializeServices({required AppLanguage savedLanguage}) async {
  try {
    await AppFirebaseService.initialize();
    if (kDebugMode) {
      debugPrint(
        '[FCM] token: ${await FirebaseTokenService.instance.getToken()}',
      );
    }
    quranAudioHandler = await AudioService.init(
      builder: QuranAudioHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.islami_app_noorify.quran.audio',
        androidNotificationChannelName: 'Quran recitation',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
    await AlarmScheduler.init();
    await AlarmScheduler.logScheduledAlarms();
    await migrateToOnDeviceAlarms();
    unawaited(syncLocalAlarms());
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
    unawaited(PrayerWidgetService.init());
    unawaited(PrayerWidgetService.syncPrayerWidget(language: savedLanguage));
    unawaited(
      HomeWidget.registerInteractivityCallback(refreshPrayerWidgetCallback),
    );
    PrayerLocationService.instance.addListener(() {
      if (PrayerLocationService.instance.state.status ==
          PrayerLocationStatus.ready) {
        unawaited(PrayerWidgetService.syncPrayerWidget());
      }
    });
    HomeWidget.widgetClicked.listen((uri) {
      appNavigatorKey.currentState?.pushNamed(RouteNames.prayerTimes);
    });
    QuranReadingSync.shared.start();
    DuaReadingSync.shared.start();
    AmolDayClock.instance.refresh();
    unawaited(DuaReadCompletionStore.shared.restore());
    AmolSync.shared.start();
    final launchDetails = await AlarmScheduler.launchDetails();
    final launchPayload = launchDetails?.didNotificationLaunchApp == true
        ? AlarmRingPayload.tryDecode(
            launchDetails?.notificationResponse?.payload,
          )
        : null;
    final launchAction = AlarmScheduler.actionFor(
      launchDetails?.notificationResponse?.actionId,
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
  } catch (error, stackTrace) {
    // A nonessential native service must not keep the opening splash on
    // screen forever. Features which need the unavailable service handle
    // their own error state when opened.
    debugPrint('Deferred app startup failed: $error\n$stackTrace');
  }
}
