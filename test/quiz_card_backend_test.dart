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
  maxPoints: 7,
  percentage: 33,
  formattedSubtext: '',
);

Future<void> _pump(
  WidgetTester tester,
  QuizTileData? firstQuiz, {
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
              child: QuizCardContent(firstQuiz: firstQuiz),
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
  group('quizTileFromPillar', () {
    test('no backend quiz: nothing, so the tile keeps its default', () {
      expect(quizTileFromPillar(null, title: 'Quiz'), isNull);
    });

    test('a quiz with points is played: title, points, selected', () {
      final tile = quizTileFromPillar(_quiz(points: 2.3), title: 'Quiz')!;
      expect(tile.title, 'Quiz');
      expect(tile.points, 2.3);
      expect(tile.completed, isTrue);
    });

    test('a quiz with no points yet is not selected and keeps its worth', () {
      final tile = quizTileFromPillar(_quiz(points: 0), title: 'Quiz')!;
      expect(tile.title, 'Quiz');
      expect(tile.points, 1);
      expect(tile.completed, isFalse);
    });
  });

  group('Quiz card', () {
    testWidgets('the first tile is the backend quiz, selected; the second is '
        'unchanged', (tester) async {
      await _pump(
        tester,
        quizTileFromPillar(_quiz(points: 2.3), title: 'Quiz'),
      );

      final tiles = _tiles(tester);
      expect(tiles, hasLength(2)); // never more than two
      expect(
        (tiles[0].title, tiles[0].points, tiles[0].completed),
        ('Quiz', 2.3, true),
      );
      expect(
        (tiles[1].title, tiles[1].points, tiles[1].completed),
        ('Quiz 2', 1, false),
      );
      expect(find.text('+2.3'), findsOneWidget);
      expect(find.text('+1'), findsOneWidget);
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

    testWidgets('the backend points are written with Bangla digits in Bangla', (
      tester,
    ) async {
      await _pump(
        tester,
        quizTileFromPillar(_quiz(points: 2.3), title: 'কুইজ'),
        language: AppLanguage.bangla,
      );

      expect(find.text('+২.৩'), findsOneWidget);
      expect(find.text('কুইজ'), findsOneWidget);
      expect(_tiles(tester), hasLength(2));
    });

    testWidgets('a whole number of points has no trailing zero', (
      tester,
    ) async {
      await _pump(
        tester,
        quizTileFromPillar(_quiz(points: 3.0), title: 'Quiz'),
      );
      expect(find.text('+3'), findsOneWidget);
    });
  });
}
