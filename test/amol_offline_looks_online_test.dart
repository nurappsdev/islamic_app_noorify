import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_daily_dashboard.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/repositories/amol_tracking_repository.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/usecases/delete_amol_item.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/usecases/get_amol_daily.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/usecases/log_amol_item.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/bloc/amol_daily/amol_daily_bloc.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/screens/amol_tracking_screen.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

import 'amol_offline_sync_test.dart' show day;

const _date = '2026-10-21';

/// A repository whose writes never answer — what a tick looks like with no
/// network, where the request sits until the 20s connect timeout.
class _HangingRepository implements AmolTrackingRepository {
  _HangingRepository(this.dashboard);
  final AmolDailyDashboard dashboard;

  @override
  Future<Either<Failure, AmolDailyDashboard>> getDaily({
    required String date,
  }) async => Right(dashboard);

  @override
  Future<Either<Failure, AmolDailyDashboard>> logItem({
    required String logDate,
    required String pillarKey,
    required String itemKey,
  }) => Completer<Either<Failure, AmolDailyDashboard>>().future;

  @override
  Future<Either<Failure, AmolDailyDashboard>> deleteItem({
    required String logDate,
    required String pillarKey,
    required String itemKey,
  }) => Completer<Either<Failure, AmolDailyDashboard>>().future;

  @override
  Future<({int sent, int pending})> syncPending({
    AmolDailyDashboard? known,
  }) async => (sent: 0, pending: 0);
}

/// The ticked marks on screen: a filled olive circle with a white check is
/// the one and only "done" look.
int _ticks(WidgetTester tester) => tester
    .widgetList<Icon>(find.byIcon(Icons.check))
    .where((icon) => icon.color == Colors.white)
    .length;

Future<AmolDailyBloc> _pump(
  WidgetTester tester,
  AmolDailyDashboard dashboard,
) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.runAsync(AppText.load);
  final repository = _HangingRepository(dashboard);
  final bloc = AmolDailyBloc(
    GetAmolDaily(repository),
    LogAmolItem(repository),
    DeleteAmolItem(repository),
    initialDashboard: dashboard,
  );
  addTearDown(bloc.close);
  final language = LanguageBloc(
    initialLanguage: AppLanguage.english,
    persist: (_) async {},
  );
  addTearDown(language.close);
  await tester.pumpWidget(
    BlocProvider.value(
      value: language,
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          home: AmolTrackingScreen(
            bloc: bloc,
            initialExpandedCategory: 'Fardh Prayer',
            now: () => DateTime(2026, 10, 21),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  // The screen's own first load depends on prayer times, which aren't
  // available here; load the day explicitly so the bloc accepts ticks for it.
  bloc.add(const LoadAmolDaily(_date, silent: true));
  await tester.pumpAndSettle();
  return bloc;
}

void main() {
  testWidgets('a tick saved offline looks exactly like a synced one', (
    tester,
  ) async {
    // The same day, told twice: once with Fajr already on the server, once
    // with it only on this device.
    await _pump(tester, day(_date, done: {'fajr'}));
    final synced = _ticks(tester);

    await _pump(
      tester,
      day(_date, done: {'fajr'}).copyWith(pendingItemKeys: {'fajr'}),
    );

    expect(_ticks(tester), synced);
    expect(_ticks(tester), 1);
    // Nothing anywhere says "waiting", in any form: no badge, no second
    // shade of tick, no spinner, no banner, no snackbar.
    expect(find.byIcon(Icons.schedule), findsNothing);
    expect(find.byIcon(Icons.cloud_off), findsNothing);
    expect(find.byIcon(Icons.sync), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(Dialog), findsNothing);
  });

  group('while the request is still outstanding', () {
    /// A bloc on a repository whose writes never answer, with [_date] loaded
    /// so it accepts ticks for that day.
    Future<AmolDailyBloc> loaded(AmolDailyDashboard dashboard) async {
      final repository = _HangingRepository(dashboard);
      final bloc = AmolDailyBloc(
        GetAmolDaily(repository),
        LogAmolItem(repository),
        DeleteAmolItem(repository),
        initialDashboard: dashboard,
      );
      addTearDown(bloc.close);
      final ready = bloc.stream.firstWhere((s) => s.hasData);
      bloc.add(const LoadAmolDaily(_date, silent: true));
      await ready;
      return bloc;
    }

    test('a tick is checked at once, and stays checked', () async {
      final bloc = await loaded(day(_date));

      final ticked = bloc.stream.firstWhere(
        (s) => s.isItemChecked('fajr', false),
      );
      bloc.add(
        const LogAmolDailyItem(
          logDate: _date,
          pillarKey: 'fardh_prayer',
          itemKey: 'fajr',
        ),
      );
      await ticked;

      // Nothing has come back, and never will, yet it reads as done.
      expect(bloc.state.isItemChecked('fajr', false), isTrue);
      expect(bloc.state.loggingItemKeys, {'fajr'});
      expect(bloc.state.hasData, isTrue);
    });

    test('an untick is cleared at once, and stays cleared', () async {
      final bloc = await loaded(day(_date, done: {'fajr'}));

      final unticked = bloc.stream.firstWhere(
        (s) => !s.isItemChecked('fajr', true),
      );
      bloc.add(
        const UncheckAmolDailyItem(
          logDate: _date,
          pillarKey: 'fardh_prayer',
          itemKey: 'fajr',
        ),
      );
      await unticked;

      expect(bloc.state.isItemChecked('fajr', true), isFalse);
      expect(bloc.state.loggingItemKeys, {'fajr'});
    });

    test('other items can still be ticked, so a run of them is kept', () async {
      // The case that used to be lost: offline, the first request sits until
      // the connect timeout and every later tick was dropped.
      final bloc = await loaded(day(_date));

      final both = bloc.stream.firstWhere(
        (s) =>
            s.isItemChecked('fajr', false) && s.isItemChecked('dhuhr', false),
      );
      for (final itemKey in ['fajr', 'dhuhr']) {
        bloc.add(
          LogAmolDailyItem(
            logDate: _date,
            pillarKey: 'fardh_prayer',
            itemKey: itemKey,
          ),
        );
      }
      await both;

      expect(bloc.state.loggingItemKeys, {'fajr', 'dhuhr'});
    });

    test(
      'tapping the same item twice while it waits changes nothing',
      () async {
        final bloc = await loaded(day(_date));
        final ticked = bloc.stream.firstWhere(
          (s) => s.isItemChecked('fajr', false),
        );
        const event = LogAmolDailyItem(
          logDate: _date,
          pillarKey: 'fardh_prayer',
          itemKey: 'fajr',
        );
        bloc.add(event);
        await ticked;
        bloc.add(event);
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state.isItemChecked('fajr', false), isTrue);
        expect(bloc.state.loggingItemKeys, {'fajr'});
      },
    );
  });
}
