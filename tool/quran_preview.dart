// Standalone native entry point for checking the Quran module against devImg.
// Uses real APIs and the same audio engine without unrelated app bootstrapping.
import 'package:audio_service/audio_service.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/features/quran/data/services/quran_audio_handler.dart';
import 'package:tuhfatul_muslim/features/quran/data/services/quran_audio_downloader.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/bloc/last_read/last_read_bloc.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/bloc/offline_quran/offline_quran_bloc.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/bloc/reciter/reciter_bloc.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/bloc/surah_playback/surah_playback_bloc.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/bloc/surah_audio_download/surah_audio_download_bloc.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/bloc/bookmarks/bookmarks_bloc.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/bloc/reading_history/reading_history_bloc.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/screens/surah_list_screen.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/screens/quran_reading_screen.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/screens/para_detail_screen.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/screens/bookmarks_screen.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/screens/reading_history_screen.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/quran_route_args.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppText.load();
  quranAudioHandler = await AudioService.init(
    builder: QuranAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.noorify.quran.audio',
      androidNotificationChannelName: 'Quran recitation',
      androidNotificationOngoing: true,
    ),
  );
  runApp(
    BlocProvider(
      create: (_) => LanguageBloc(),
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xffa1ae57),
          ),
          onGenerateRoute: (settings) {
            Widget child;
            switch (settings.name) {
              case RouteNames.quranSurahDetail:
              case RouteNames.quranFullSurah:
                final args = settings.arguments as SurahRouteArgs;
                final downloader = QuranAudioDownloader();
                child = MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (_) => ReciterBloc()..add(const LoadReciters()),
                    ),
                    BlocProvider(
                      create: (_) => SurahPlaybackBloc(
                        downloader: downloader,
                        startAyah: args.paraNumber == null ? 1 : args.ayahNo,
                        endAyah: args.endAyah,
                      ),
                    ),
                    BlocProvider(
                      create: (_) =>
                          SurahAudioDownloadBloc(downloader: downloader),
                    ),
                  ],
                  child: QuranReadingScreen(args: args),
                );
              case RouteNames.quranJuzReader:
                child = ParaDetailScreen(number: settings.arguments as int);
              case RouteNames.quranBookmarks:
                child = BlocProvider(
                  create: (_) => BookmarksBloc()..add(const LoadBookmarks()),
                  child: const BookmarksScreen(),
                );
              case RouteNames.quranReadingHistory:
                child = BlocProvider(
                  create: (_) =>
                      ReadingHistoryBloc()..add(const LoadReadingHistory()),
                  child: const ReadingHistoryScreen(),
                );
              default:
                child = MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (_) => LastReadBloc()..add(const LoadLastRead()),
                    ),
                    BlocProvider(
                      create: (_) =>
                          OfflineQuranBloc()..add(const CheckOfflineQuran()),
                    ),
                  ],
                  child: const SurahListScreen(),
                );
            }
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => child,
            );
          },
        ),
      ),
    ),
  );
}
