import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tuhfatul_muslim/features/dua/data/models/dua_reading_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_repository.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/screens/dua_recitation_history_screen.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// An empty history: these tests are about which days the views offer and in
/// what order, not about the rows under them.
class _EmptyRepo extends Fake implements DuaRepository {
  @override
  Future<DuaReadingHistoryPage> getReadingHistory({
    int page = 1,
    int limit = 20,
  }) async => const DuaReadingHistoryPage(items: [], page: 1, totalPage: 1);
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

void main() {
  Future<void> pumpHistory(WidgetTester tester) async {
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
            home: DuaRecitationHistoryScreen(repository: _EmptyRepo()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The strip's seven day numbers: the first plain numbers either view
  /// writes out.
  List<String> stripDays(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data)
      .whereType<String>()
      .where((data) => int.tryParse(data) != null)
      .take(7)
      .toList();

  /// The seven days the strip should offer: a week ago first, today last —
  /// 16 → 22 on the 22nd, never forward into days still to come.
  List<String> expectedStripDays() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 6));
    return [
      for (var ahead = 0; ahead < 7; ahead++)
        '${weekAgo.add(Duration(days: ahead)).day}',
    ];
  }

  testWidgets('the daily strip covers the past week and ends on today', (
    tester,
  ) async {
    await pumpHistory(tester);

    // Daily is the tab the screen opens on.
    expect(stripDays(tester), expectedStripDays());
  });

  testWidgets('the weekly strip ends on today, while its cards start there', (
    tester,
  ) async {
    await pumpHistory(tester);
    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();

    expect(stripDays(tester), expectedStripDays());

    // The day cards below run the other way: today heads the list and a week
    // ago closes it, so the newest reading is the first card.
    String cardDate(DateTime date) =>
        '${date.day} ${_months[date.month - 1]} ${date.year}';
    final cards = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .whereType<String>()
        .where((data) => RegExp(r'^\d+ [A-Z][a-z]{2} \d{4}$').hasMatch(data))
        .toList();
    final today = DateTime.now();
    expect(cards, [
      for (var back = 0; back < 7; back++)
        cardDate(today.subtract(Duration(days: back))),
    ]);
  });
}
