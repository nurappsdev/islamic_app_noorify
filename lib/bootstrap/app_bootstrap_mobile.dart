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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AppFirebaseService.initialize();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await HiveService.init();
  if (kDebugMode) {
    debugPrint(
      '[FCM] token: ${await FirebaseTokenService.instance.getToken()}',
    );
  }
  AuthRefreshInterceptor.onSessionExpired = () async {
    await SessionCleaner.clearUserData();
    appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
      RouteNames.signIn,
      (_) => false,
    );
  };
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

  final preferences = await SharedPreferences.getInstance();
  final savedDarkTheme =
      preferences.getBool(AppPreferencesBloc.darkThemeKey) ?? false;
  final savedLanguage = LanguagePreference.read(preferences);
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
      ? AlarmRingPayload.tryDecode(launchDetails?.notificationResponse?.payload)
      : null;
  final launchAction = AlarmScheduler.actionFor(
    launchDetails?.notificationResponse?.actionId,
  );

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => LanguageBloc(initialLanguage: savedLanguage),
        ),
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
