import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/home/domain/entities/highlight_card.dart';
import 'package:tuhfatul_muslim/features/home/domain/entities/home_dashboard.dart';
import 'package:tuhfatul_muslim/features/home/domain/entities/pillar_card.dart';
import 'package:tuhfatul_muslim/features/home/domain/entities/user_summary.dart';
import 'package:tuhfatul_muslim/features/home/domain/repositories/home_repository.dart';
import 'package:tuhfatul_muslim/features/home/domain/usecases/get_home_dashboard.dart';
import 'package:tuhfatul_muslim/features/home/presentation/bloc/home_dashboard/home_dashboard_bloc.dart';
import 'package:tuhfatul_muslim/features/home/presentation/widgets/amal_tracker_card.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

class _Repository implements HomeRepository {
  const _Repository(this.dashboard);

  final HomeDashboard dashboard;

  @override
  Future<Either<Failure, HomeDashboard>> getDashboard() async =>
      Right(dashboard);
}

Future<void> _pumpCard(
  WidgetTester tester,
  HighlightCard card, {
  AppLanguage language = AppLanguage.english,
}) async {
  tester.view.physicalSize = const Size(375 * 3, 812 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final bloc = HomeDashboardBloc(
    GetHomeDashboard(
      _Repository(
        HomeDashboard(
          userSummary: const UserSummary(fullName: 'Me', greetingText: ''),
          topHighlightCards: [card],
          pillarCards: const <PillarCard>[],
          dashboardDate: DateTime(2023, 9, 14),
        ),
      ),
    ),
  )..add(const LoadHomeDashboard());
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<HomeDashboardBloc>.value(value: bloc),
        BlocProvider(
          create: (_) => LanguageBloc()..add(UpdateLanguage(language)),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => const MaterialApp(
          home: Scaffold(body: Center(child: AmalTrackerCard())),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

// The slider is endless, so with one card it also builds that card on the
// neighbouring pages: assert `findsWidgets` for what must show.
void main() {
  testWidgets('shows the slide\'s points instead of the month and year', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      const HighlightCard(
        id: '1',
        type: 'monthly_first',
        title: 'First in the month',
        userName: 'Nizam Ilmi',
        pointsText: 'Point : 72.25/1120',
        percentage: 6.5,
      ),
    );

    expect(find.text('First in the month'), findsWidgets);
    // The overlapping badge uses this card's backend-provided name.
    expect(find.text('Nizam Ilmi'), findsWidgets);
    expect(find.text('Point : 72.25/1120'), findsWidgets);
    // No date or year anywhere on the card.
    expect(find.textContaining('Sep'), findsNothing);
    expect(find.textContaining('2023'), findsNothing);

    await tester.pumpWidget(const SizedBox()); // stops the auto-slide timer
  });

  testWidgets('uses the points line of a monthly subtitle when there is no '
      'points text', (tester) async {
    await _pumpCard(
      tester,
      const HighlightCard(
        id: '2',
        type: 'monthly_second',
        title: 'Second in the month',
        userName: 'Khalid',
        subtitle: 'Second in the month\nPoint : 421/560',
        percentage: 75,
      ),
    );

    expect(find.text('Point : 421/560'), findsWidgets);
    expect(find.textContaining('Second in the month\n'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shows the Bangla points text in Bangla mode', (tester) async {
    await _pumpCard(
      tester,
      const HighlightCard(
        id: '3',
        type: 'monthly_first',
        title: 'First in the month',
        userName: 'Nizam Ilmi',
        pointsText: 'Point : 72.25/1120',
        percentage: 6.5,
        localizedTitle: LocalizedText(
          en: 'First in the month',
          bn: 'মাসে প্রথম',
        ),
        localizedPointsText: LocalizedText(
          en: 'Point : 72.25/1120',
          bn: 'পয়েন্ট : ৭২.২৫/১১২০',
        ),
      ),
      language: AppLanguage.bangla,
    );

    expect(find.text('মাসে প্রথম'), findsWidgets);
    expect(find.text('পয়েন্ট : ৭২.২৫/১১২০'), findsWidgets);
    expect(find.text('Point : 72.25/1120'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });
}
