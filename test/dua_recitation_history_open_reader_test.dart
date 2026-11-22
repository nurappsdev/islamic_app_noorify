import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_reading_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_repository.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/dua_route_args.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/screens/dua_recitation_history_screen.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// One dua read a moment ago, so the Daily view shows a single row.
class _Repo extends Fake implements DuaRepository {
  _Repo({this.detailFails = false});

  final bool detailFails;
  final requestedIds = <String>[];
  int historyRequests = 0;

  @override
  Future<DuaReadingHistoryPage> getReadingHistory({
    int page = 1,
    int limit = 20,
  }) async {
    historyRequests++;
    return DuaReadingHistoryPage(
      items: [
        DuaReadingHistoryItem(
          duaId: 'dua-1',
          title: const LocalizedText(en: 'Morning remembrance'),
          arabic: 'اللّهم',
          category: const LocalizedText(en: 'Daily Adhkar'),
          lastReadAt: DateTime.now(),
        ),
      ],
      page: 1,
      totalPage: 1,
    );
  }

  @override
  Future<DuaFeaturedModel> getDuaById(String id) async {
    requestedIds.add(id);
    if (detailFails) throw Exception('offline');
    return DuaFeaturedModel(
      id: id,
      categoryId: 'cat-1',
      title: const LocalizedText(en: 'Morning remembrance'),
      arabic: 'اللّهم',
      transliteration: const LocalizedText(en: 'Allahumma'),
      translation: const LocalizedText(en: 'O Allah'),
    );
  }
}

/// What the stub reader route was opened with, if it was opened at all.
class _PushedReader {
  bool opened = false;
  DuaReaderArgs? args;
}

void main() {
  /// Mounts the history screen with a stub reader route. The returned box
  /// holds the arguments that route was given — the real reader is not
  /// under test — and stays null while nothing has opened it.
  Future<_PushedReader> pumpHistory(WidgetTester tester, _Repo repo) async {
    final pushed = _PushedReader();
    tester.view.physicalSize = const Size(375 * 3, 812 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (context, child) => BlocProvider(
          create: (_) => LanguageBloc(initialLanguage: AppLanguage.english),
          child: MaterialApp(
            home: DuaRecitationHistoryScreen(repository: repo),
            onGenerateRoute: (settings) {
              if (settings.name == RouteNames.duaReader) {
                pushed.args = settings.arguments as DuaReaderArgs?;
                pushed.opened = true;
                return MaterialPageRoute(
                  // An app bar, so the stub has the back button
                  // `tester.pageBack` presses.
                  builder: (_) =>
                      Scaffold(appBar: AppBar(), body: const Text('reader')),
                );
              }
              return null;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return pushed;
  }

  testWidgets('tapping a recitation row opens that dua in the reader', (
    tester,
  ) async {
    final repo = _Repo();
    final pushed = await pumpHistory(tester, repo);

    await tester.tap(find.text('Morning remembrance'));
    await tester.pumpAndSettle();

    // The row's id was resolved to a full dua, which the reader received.
    expect(repo.requestedIds, ['dua-1']);
    expect(pushed.args?.featuredModel?.id, 'dua-1');
    expect(find.text('reader'), findsOneWidget);
  });

  testWidgets('returning from the reader reloads the history', (tester) async {
    final repo = _Repo();
    await pumpHistory(tester, repo);
    expect(repo.historyRequests, 1);

    await tester.tap(find.text('Morning remembrance'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    // The reading just made would otherwise leave the row out of date.
    expect(repo.historyRequests, 2);
  });

  testWidgets('a dua that cannot be fetched reports instead of opening', (
    tester,
  ) async {
    final repo = _Repo(detailFails: true);
    final pushed = await pumpHistory(tester, repo);

    await tester.tap(find.text('Morning remembrance'));
    await tester.pumpAndSettle();

    expect(pushed.opened, isFalse);
    expect(find.text("Couldn't open this dua."), findsOneWidget);
  });
}
