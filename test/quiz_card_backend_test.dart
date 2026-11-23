import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/home/domain/entities/pillar_card.dart';
import 'package:tuhfatul_muslim/features/home/presentation/widgets/quiz_card_content.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

PillarCard _quiz({required num points}) => PillarCard(
  pillarKey: 'quiz',
  title: 'Quiz',
  points: points,
  maxPoints: 2,
  percentage: 33,
  formattedSubtext: '',
);

List<QuizTileData>? _tilesFrom(PillarCard? pillar, {String title = 'Quiz'}) =>
    quizTilesFromPillar(pillar, titleFor: (index) => '$title $index');

Future<void> _pump(
  WidgetTester tester,
  List<QuizTileData>? tiles, {
  AppLanguage language = AppLanguage.english,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final bloc = LanguageBloc(initialLanguage: language, persist: (_) async {});
  addTearDown(bloc.close);
  await tester.pumpWidget(
    BlocProvider.value(
      value: bloc,
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 340,
              height: 380,
              child: QuizCardContent(tiles: tiles),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

List<QuizGlassCard> _tiles(WidgetTester tester) =>
    tester.widgetList<QuizGlassCard>(find.byType(QuizGlassCard)).toList();

void main() {
  group('quizTilesFromPillar', () {
    test('no backend quiz: nothing, so the tiles keep their defaults', () {
      expect(_tilesFrom(null), isNull);
    });

    test('every tile is worth one point, never the pillar total', () {
      final tiles = _tilesFrom(_quiz(points: 2))!;
      expect(tiles, hasLength(quizTilesPerDay));
      expect(tiles.map((t) => t.points), everyElement(quizPointsPerQuiz));
      expect(tiles.map((t) => t.title), ['Quiz 1', 'Quiz 2']);
    });

    test('the points earned are the quizzes played: one point, one tile', () {
      expect(_tilesFrom(_quiz(points: 0))!.map((t) => t.completed), [
        false,
        false,
      ]);
      expect(_tilesFrom(_quiz(points: 1))!.map((t) => t.completed), [
        true,
        false,
      ]);
      expect(_tilesFrom(_quiz(points: 2))!.map((t) => t.completed), [
        true,
        true,
      ]);
    });
  });

  group('Quiz card', () {
    testWidgets('one quiz played: that tile is selected, both show one point', (
      tester,
    ) async {
      await _pump(tester, _tilesFrom(_quiz(points: 1)));

      final tiles = _tiles(tester);
      expect(tiles, hasLength(2)); // never more than two
      expect(
        (tiles[0].title, tiles[0].points, tiles[0].completed),
        ('Quiz 1', 1, true),
      );
      expect(
        (tiles[1].title, tiles[1].points, tiles[1].completed),
        ('Quiz 2', 1, false),
      );
      expect(find.text('+1'), findsNWidgets(2));
    });

    testWidgets('without backend data both tiles keep their defaults', (
      tester,
    ) async {
      await _pump(tester, null);

      final tiles = _tiles(tester);
      expect(tiles.map((t) => t.title), ['Quiz 1', 'Quiz 2']);
      expect(tiles.every((t) => !t.completed), isTrue);
      expect(find.text('+1'), findsNWidgets(2));
    });

    testWidgets('the points are written with Bangla digits in Bangla', (
      tester,
    ) async {
      await _pump(
        tester,
        _tilesFrom(_quiz(points: 1), title: 'কুইজ'),
        language: AppLanguage.bangla,
      );

      expect(find.text('+১'), findsNWidgets(2));
      expect(find.text('কুইজ 1'), findsOneWidget);
      expect(_tiles(tester), hasLength(2));
    });

    testWidgets('a fractional badge has no trailing zero', (tester) async {
      await _pump(tester, const [
        QuizTileData(title: 'Quiz 1', points: 2.3),
        QuizTileData(title: 'Quiz 2', points: 3.0),
      ]);
      expect(find.text('+2.3'), findsOneWidget);
      expect(find.text('+3'), findsOneWidget);
    });
  });
}
