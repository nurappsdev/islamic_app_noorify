import 'package:audio_service/audio_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../core/bloc/app_preferences/app_preferences_bloc.dart';
import '../core/constants/route_names.dart';
import '../core/network/auth_refresh_interceptor.dart';
import '../core/services/facebook_auth_config.dart';
import '../core/storage/hive_service.dart';
import '../core/storage/session_cleaner.dart';
import '../core/utils/app_text.dart';
import '../firebase_options.dart';
import '../features/quran/data/services/quran_audio_handler.dart';
import '../main_app.dart';
import '../shared/bloc/language/language_bloc.dart';
import '../shared/services/firebase/firebase_service.dart';

/// Browser-only start-up. Native scheduling, Home Screen widgets, file-backed
/// audio and orientation controls deliberately stay in the mobile bootstrap.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Keep existing sqflite callers unchanged. On the browser this stores the
  // databases in IndexedDB through SQLite WASM; mobile keeps its native
  // sqflite factory in the mobile bootstrap.
  databaseFactory = databaseFactoryFfiWeb;

  if (DefaultFirebaseOptions.isWebConfigured) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
    await AppFirebaseService.initialize();
  } else if (kDebugMode) {
    debugPrint(
      'Firebase Web is not configured. Run with the FIREBASE_WEB_* '
      'dart-defines described in web/README.md to enable Firebase auth and '
      'messaging.',
    );
  }

  // flutter_facebook_auth requires the Facebook JavaScript SDK to be loaded
  // before any login attempt on Web. This is intentionally absent from the
  // mobile bootstrap, where Android/iOS initialize their native SDKs instead.
  if (FacebookAuthConfig.isConfigured) {
    try {
      await FacebookAuth.instance.webAndDesktopInitialize(
        appId: FacebookAuthConfig.appId,
        cookie: true,
        xfbml: true,
        version: FacebookAuthConfig.webSdkVersion,
      );
    } catch (error) {
      // A missing Meta domain setting must not stop guest browsing or REST
      // sign-in. The Facebook button will report its own provider error.
      if (kDebugMode) {
        debugPrint('Facebook Web SDK could not initialize: $error');
      }
    }
  }

  await HiveService.init();
  await AppText.load();
  // Browser playback is foreground-only, but `just_audio` can still stream
  // recitations. If a browser blocks the media-session integration, retain a
  // plain handler instead of preventing the rest of the app from starting.
  try {
    quranAudioHandler = await AudioService.init(
      builder: QuranAudioHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.islami_app_noorify.quran.audio',
        androidNotificationChannelName: 'Quran recitation',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
  } catch (_) {
    quranAudioHandler = QuranAudioHandler();
  }
  final preferences = await SharedPreferences.getInstance();
  final savedDarkTheme =
      preferences.getBool(AppPreferencesBloc.darkThemeKey) ?? false;
  final savedLanguage = LanguagePreference.read(preferences);

  AuthRefreshInterceptor.onSessionExpired = () async {
    await SessionCleaner.clearUserData();
    appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
      RouteNames.signIn,
      (_) => false,
    );
  };

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
}
