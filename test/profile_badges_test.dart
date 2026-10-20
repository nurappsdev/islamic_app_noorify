import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/profile/data/models/profile_model.dart';
import 'package:tuhfatul_muslim/features/profile/presentation/widgets/profile_badges.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// Three tiers, as /users/me sends them for [points] (no icons, so nothing
/// is fetched).
Map<String, Object?> _me(num points) {
  final tiers = [
    ('bronze', 'Bronze', 0, 99),
    ('silver', 'Silver', 100, 249),
    ('gold', 'Gold', 250, 499),
  ];
  Map<String, Object?> tier((String, String, int, int) t, int level) => {
    '_id': 'id-${t.$1}',
    'slug': t.$1,
    'name': t.$2,
    'iconUrl': '',
    'level': level,
    'startPoints': t.$3,
    'endPoints': t.$4,
  };
  final reached = [
    for (final t in tiers)
      if (points >= t.$3) t,
  ];
  final next = tiers.where((t) => t.$3 > points).firstOrNull;
  return {
    '_id': 'u1',
    'email': 'a@b.c',
    'name': 'Reader',
    'totalPoints': points,
    'currentBadge': reached.isEmpty
        ? null
        : tier(reached.last, tiers.indexOf(reached.last) + 1),
    'nextBadge': next == null ? null : tier(next, tiers.indexOf(next) + 1),
    'pointsToNextBadge': next == null ? 0 : next.$3 - points,
    'badges': [
      for (final (i, t) in tiers.indexed)
        {...tier(t, i + 1), 'isUnlocked': points >= t.$3},
    ],
  };
}

Future<void> _pump(WidgetTester tester, Map<String, Object?> me) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => BlocProvider(
        create: (_) => LanguageBloc(initialLanguage: AppLanguage.english),
        child: MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFFA7B462),
            body: Center(
              child: ProfileBadges(profile: ProfileModel.fromJson(me)),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('the profile keeps badge progress through its cache', () {
    final profile = ProfileModel.fromJson(_me(120));
    expect(profile.currentBadge?.slug, 'silver');
    expect(profile.nextBadge?.slug, 'gold');
    expect(profile.pointsToNextBadge, 130);
    expect(profile.badges.map((b) => b.isUnlocked), [true, true, false]);
    expect(profile.badges[2].startPoints, 250);

    final cached = ProfileModel.fromJson(profile.toJson());
    expect(cached.nextBadge?.name, 'Gold');
    expect(cached.pointsToNextBadge, 130);
    expect(cached.badges[1].endPoints, 249);
  });

  testWidgets('shows the badge worn and how far the next one is', (
    tester,
  ) async {
    await _pump(tester, _me(120));
    expect(find.text('Silver'), findsOneWidget);
    expect(find.text('130 points to Gold'), findsOneWidget);
    // Gold is not reached yet: it carries a lock.
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('profile-badges')));
    await tester.pumpAndSettle();
    expect(find.text('Badges'), findsOneWidget);
    expect(find.text('Unlocked'), findsNWidgets(2));
    expect(find.text('250–499 points'), findsOneWidget);
    expect(find.text('130 more points'), findsOneWidget);
  });

  testWidgets('before any badge, the first is the goal', (tester) async {
    final me = _me(0)
      // Tiers starting above zero: nothing reached at 20 points.
      ..['badges'] = [
        {
          'slug': 'bronze',
          'name': 'Bronze',
          'startPoints': 50,
          'endPoints': 99,
          'isUnlocked': false,
        },
      ]
      ..['currentBadge'] = null
      ..['nextBadge'] = {'slug': 'bronze', 'name': 'Bronze', 'startPoints': 50}
      ..['pointsToNextBadge'] = 30
      ..['totalPoints'] = 20;
    await _pump(tester, me);
    expect(find.text('Bronze'), findsOneWidget);
    expect(find.text('30 points to Bronze'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsWidgets);
  });

  testWidgets('the highest badge says so', (tester) async {
    await _pump(tester, _me(300));
    expect(find.text('Gold'), findsOneWidget);
    expect(find.text('Highest badge reached'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsNothing);
  });

  testWidgets('no badges set up: nothing shows', (tester) async {
    await _pump(tester, {'_id': 'u1', 'email': 'a@b.c', 'badges': []});
    expect(find.byKey(const ValueKey('profile-badges')), findsNothing);
  });
}
