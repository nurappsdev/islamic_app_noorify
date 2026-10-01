import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/quiz/data/datasources/quiz_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/quiz/data/repositories/quiz_repository_impl.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_enums.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/usecases/get_category_quiz.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/usecases/get_daily_quiz.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/usecases/submit_quiz_attempt.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/bloc/quiz_question_bloc.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/quiz_route_args.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_category.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_state.dart';

/// Answers each request by path, and remembers the requests.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.routes);

  /// `"METHOD /path"` -> (status, body). A missing route answers 404.
  final Map<String, (int, Object)> routes;
  final requests = <RequestOptions>[];

  RequestOptions get last => requests.last;

  /// When set, POST requests wait for it, so a test can overlap submissions.
  Completer<void>? postGate;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.method == 'POST') await postGate?.future;
    final key = '${options.method} ${options.uri.path.split('/api/v1').last}';
    final (status, body) =
        routes[key] ?? (404, {'success': false, 'message': 'Not found'});
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeLocal implements AuthLocalDataSource {
  _FakeLocal(this.token);

  final String? token;

  @override
  String? getToken() => token;

  @override
  bool get hasToken => token != null;

  @override
  Future<void> cacheToken(String token) async {}

  @override
  Future<void> clearToken() async {}
}

Map<String, Object> _ok(Object data, {Object? meta}) => {
  'statusCode': 200,
  'success': true,
  'message': 'ok',
  'data': data,
  'meta': ?meta,
};

Map<String, Object?> _question(String id, {bool isActive = true}) => {
  'id': id,
  'categoryId': 'cat1',
  'category': {
    'id': 'cat1',
    'name': {'bn': 'সালাত', 'en': 'Salah'},
  },
  'checkedBy': null,
  'question': {'bn': 'প্রশ্ন $id', 'en': null},
  'options': [
    {
      'key': 'A',
      'text': {'bn': '৩', 'en': '3'},
    },
    {
      'key': 'C',
      'text': {'bn': '৫', 'en': '5'},
    },
  ],
  'difficulty': {'key': 'medium', 'bn': 'মধ্যম', 'en': 'Medium'},
  'displayOrder': 1,
  'isActive': isActive,
};

final _dailyQuiz = _ok({
  'source': 'daily',
  'id': 'quiz1',
  'quizDate': '2026-09-26',
  'pointsReward': 2.5,
  'timeLimitSeconds': 180,
  'totalQuestions': 2,
  'questions': [_question('q1'), _question('q2')],
});

final _attemptResult = {
  'statusCode': 201,
  'success': true,
  'message': 'ok',
  'data': {
    'id': 'att1',
    'attemptType': 'daily',
    'totalQuestions': 2,
    'correctAnswers': 1,
    'incorrectAnswers': 1,
    'scorePercentage': 50,
    'pointsEarned': 1.25,
    'maxPoints': 2.5,
    'timeSpentSeconds': 40,
    'amol': {
      'logDate': '2026-09-26',
      'quizPoints': 1.25,
      'quizMaxPoints': 2.5,
      'dayTotalPoints': 10,
      'dayMaxPoints': 40,
    },
  },
};

({QuizRemoteDataSourceImpl source, _StubAdapter http}) _setup(
  Map<String, (int, Object)> routes, {
  String? token = 'tkn',
}) {
  final http = _StubAdapter(routes);
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://example.test/api/v1',
      validateStatus: (s) => s != null && s < 500,
    ),
  )..httpClientAdapter = http;
  return (
    source: QuizRemoteDataSourceImpl(dio: dio, local: _FakeLocal(token)),
    http: http,
  );
}

QuizQuestionBloc _bloc(
  QuizRemoteDataSourceImpl source,
  QuizLaunchArgs launch,
  DateTime Function() clock,
) {
  final repo = QuizRepositoryImpl(source);
  return QuizQuestionBloc(
    launch: launch,
    getDailyQuiz: GetDailyQuiz(repo),
    getCategoryQuiz: GetCategoryQuiz(repo),
    submitAttempt: SubmitQuizAttempt(repo),
    clock: clock,
    // Ticks are sent by hand; keep the real ticker out of the way.
    tickInterval: const Duration(hours: 1),
  );
}

final now0 = DateTime(2026, 9, 26, 10);

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  group('LocalizedText', () {
    test('picks the language and falls back when a side is missing', () {
      const text = LocalizedText(bn: 'বাংলা', en: null);
      expect(text.resolve(AppLanguage.bangla), 'বাংলা');
      expect(text.resolve(AppLanguage.english), 'বাংলা');
      expect(
        LocalizedText.fromJson({
          'bn': 'ক',
          'en': 'A',
        }).resolve(AppLanguage.english),
        'A',
      );
      expect(LocalizedText.fromJson(null).resolve(AppLanguage.english), '');
    });
  });

  group('QuizRemoteDataSource', () {
    test('categories: public, active only, in display order', () async {
      final s = _setup({
        'GET /quizzes/categories': (
          200,
          _ok([
            {
              'id': 'b',
              'name': {'bn': 'খ', 'en': 'B'},
              'description': null,
              'iconUrl': null,
              'displayOrder': 2,
              'totalQuestions': {'value': 17, 'bn': '১৭', 'en': '17'},
              'isActive': true,
            },
            {
              'id': 'a',
              'name': {'bn': 'ক', 'en': 'A'},
              'displayOrder': 1,
              'totalQuestions': {'value': 3, 'bn': '৩', 'en': '3'},
              'isActive': true,
            },
            {
              'id': 'off',
              'name': {'bn': 'x', 'en': 'x'},
              'displayOrder': 0,
              'isActive': false,
            },
          ]),
        ),
      });
      final categories = await s.source.getCategories();
      expect(categories.map((c) => c.id), ['a', 'b']);
      expect(categories.last.totalQuestions.value, 17);
      expect(categories.last.iconUrl, isNull);
      expect(s.http.last.headers.containsKey('Authorization'), isFalse);
    });

    test('daily quiz: local date, bearer token, no answer key', () async {
      final s = _setup({'GET /quizzes/daily': (200, _dailyQuiz)});
      final quiz = await s.source.getDailyQuiz(DateTime(2026, 9, 26, 23, 50));
      expect(s.http.last.uri.queryParameters, {'date': '2026-09-26'});
      expect(s.http.last.headers['Authorization'], 'Bearer tkn');
      expect(quiz.id, 'quiz1');
      expect(quiz.timeLimitSeconds, 180);
      expect(quiz.pointsReward, 2.5);
      expect(quiz.questions.first.difficulty, QuizDifficulty.medium);
      expect(quiz.questions.first.options.map((o) => o.key), ['A', 'C']);
    });

    test('daily quiz status: bearer token, completed fields', () async {
      final s = _setup({
        'GET /quizzes/daily/status': (
          200,
          _ok({
            'date': '2026-09-26',
            'quizId': '6b0ffddb0f85723fd3e8d900',
            'isAvailable': true,
            'isCompleted': true,
            'hasCompleted': true,
            'attemptCount': 1,
            'pointsEarned': 2.5,
            'pointsGained': 2.5,
            'quizScore': 2.5,
            'maxPoints': 2.5,
            'bestScorePercentage': 100,
            'latestAttemptId': '6b0ffddb0f85723fd3e8d902',
            'completedAt': '2026-09-26T08:00:00.000Z',
          }),
        ),
      });
      final status = await s.source.getDailyQuizStatus();
      expect(s.http.last.uri.path, '/api/v1/quizzes/daily/status');
      expect(s.http.last.headers['Authorization'], 'Bearer tkn');
      expect(status.date, '2026-09-26');
      expect(status.quizId, '6b0ffddb0f85723fd3e8d900');
      expect(status.isCompleted, isTrue);
      expect(status.hasCompleted, isTrue);
      expect(status.completed, isTrue);
      expect(status.pointsEarned, 2.5);
      expect(status.displayPoints, 2.5);
      expect(status.latestAttemptId, '6b0ffddb0f85723fd3e8d902');
    });

    test('category quiz: dynamic id, limit and difficulty', () async {
      final s = _setup({
        'GET /quizzes/categories/cat9/quiz': (
          200,
          _ok({
            'source': 'category',
            'category': {
              'id': 'cat9',
              'name': {'bn': 'ক', 'en': 'A'},
            },
            'pointsReward': 0,
            'timeLimitSeconds': 35,
            'totalQuestions': 2,
            'questions': [_question('q1'), _question('q2', isActive: false)],
          }),
        ),
      });
      final quiz = await s.source.getCategoryQuiz(
        categoryId: 'cat9',
        limit: 5,
        difficulty: QuizDifficulty.hard,
      );
      expect(s.http.last.uri.queryParameters, {
        'limit': '5',
        'difficulty': 'hard',
      });
      expect(quiz.questions.map((q) => q.id), ['q1']);
    });

    test('attempts: query, summary from server, pagination', () async {
      final s = _setup({
        'GET /quizzes/attempts': (
          200,
          _ok(
            {
              'summary': {
                'attempts': 12,
                'bestScorePercentage': 92,
                'averageScorePercentage': 61,
              },
              'attempts': [
                {
                  'id': 'att1',
                  'attemptType': 'category',
                  'category': {'id': 'c1'},
                  'totalQuestions': 10,
                  'scorePercentage': 70,
                },
              ],
            },
            meta: {'page': 1, 'limit': 10, 'total': 12, 'totalPage': 2},
          ),
        ),
      });
      final page = await s.source.getAttempts(
        page: 1,
        limit: 10,
        attemptType: QuizAttemptType.daily,
      );
      expect(s.http.last.uri.queryParameters, {
        'attemptType': 'daily',
        'page': '1',
        'limit': '10',
      });
      expect(page.summary.bestScorePercentage, 92);
      expect(page.hasMore, isTrue);
      expect(page.attempts.single.category?.name.isEmpty, isTrue);
    });

    test(
      'attempt detail keeps server correctness and removed questions',
      () async {
        final s = _setup({
          'GET /quizzes/attempts/att1/review': (
            200,
            _ok({
              'id': 'att1',
              'attemptType': 'daily',
              'totalQuestions': 2,
              'correctAnswers': 1,
              'incorrectAnswers': 1,
              'scorePercentage': 50,
              'questions': [
                {
                  ..._question('q1'),
                  'checkedBy': 'C',
                  'correctAnswerKey': 'C',
                  'explanation': {'bn': 'ব্যাখ্যা', 'en': null},
                  'isCorrect': true,
                },
                {
                  'id': 'gone',
                  'question': null,
                  'checkedBy': null,
                  'isCorrect': false,
                },
              ],
            }),
          ),
        });
        final detail = await s.source.getAttemptReview('att1');
        expect(detail.questions.first.isCorrect, isTrue);
        expect(detail.questions.first.correctAnswerKey, 'C');
        expect(detail.questions.last.question.isEmpty, isTrue);
      },
    );

    test('an error envelope becomes a ServerException with its message', () {
      final s = _setup({
        'GET /quizzes/daily': (
          401,
          {'success': false, 'message': 'Please provide a valid access token.'},
        ),
      });
      expect(
        s.source.getDailyQuiz(DateTime(2026)),
        throwsA(
          isA<ServerException>()
              .having((e) => e.statusCode, 'status', 401)
              .having((e) => e.message, 'message', contains('access token')),
        ),
      );
    });
  });

  group('QuizQuestionBloc', () {
    test('submits keys only, unanswered as null, with server result', () async {
      var now = DateTime(2026, 9, 26, 10);
      final s = _setup({
        'GET /quizzes/daily': (200, _dailyQuiz),
        'POST /quizzes/attempts': (201, _attemptResult),
      });
      final bloc = _bloc(s.source, const QuizLaunchArgs.daily(), () => now);
      bloc.add(const LoadQuiz());
      await _settle();
      await _settle();
      expect(bloc.state.loadStatus, QuizLoadStatus.success);

      bloc.add(const SelectAnswer('C'));
      bloc.add(const GoToNextQuestion());
      now = now.add(const Duration(seconds: 40));
      bloc.add(const SubmitQuiz());
      await _settle();
      await _settle();

      final body = s.http.last.data as Map<String, dynamic>;
      expect(body, {
        'attemptType': 'daily',
        'quizId': 'quiz1',
        'timeSpentSeconds': 40,
        'used5050Lifeline': false,
        'answers': [
          {'questionId': 'q1', 'checkedBy': 'C'},
          {'questionId': 'q2', 'checkedBy': null},
        ],
      });
      expect(bloc.state.submissionStatus, QuizSubmissionStatus.submitted);
      expect(bloc.state.result?.pointsEarned, 1.25);
      await bloc.close();
    });

    test('taps, timer expiry and retries never submit twice', () async {
      var now = DateTime(2026, 9, 26, 10);
      final s = _setup({
        'GET /quizzes/daily': (200, _dailyQuiz),
        'POST /quizzes/attempts': (201, _attemptResult),
      });
      s.http.postGate = Completer<void>();
      final bloc = _bloc(s.source, const QuizLaunchArgs.daily(), () => now);
      bloc.add(const LoadQuiz());
      await _settle();
      await _settle();

      // Time runs out while the user also taps Submit twice.
      now = now.add(const Duration(minutes: 10));
      bloc
        ..add(const QuizTimerTicked())
        ..add(const SubmitQuiz())
        ..add(const SubmitQuiz());
      await _settle();
      s.http.postGate!.complete();
      await _settle();
      await _settle();
      bloc.add(const SubmitQuiz());
      await _settle();

      final posts = s.http.requests.where((r) => r.method == 'POST');
      expect(posts, hasLength(1));
      // Capped at the time limit, however long the app was away.
      expect((posts.single.data as Map)['timeSpentSeconds'], 180);
      expect(bloc.state.submissionStatus, QuizSubmissionStatus.submitted);
      await bloc.close();
    });

    test('a failed submission keeps answers and can be retried', () async {
      final now = DateTime(2026, 9, 26, 10);
      final routes = <String, (int, Object)>{
        'GET /quizzes/daily': (200, _dailyQuiz),
        'POST /quizzes/attempts': (400, {'success': false, 'message': 'Nope'}),
      };
      final s = _setup(routes);
      final bloc = _bloc(s.source, const QuizLaunchArgs.daily(), () => now);
      bloc.add(const LoadQuiz());
      await _settle();
      await _settle();
      bloc.add(const SelectAnswer('A'));
      bloc.add(const SubmitQuiz());
      await _settle();
      await _settle();
      expect(bloc.state.submissionStatus, QuizSubmissionStatus.failed);
      expect(bloc.state.submitErrorMessage, 'Nope');
      expect(bloc.state.answers, {'q1': 'A'});

      routes['POST /quizzes/attempts'] = (201, _attemptResult);
      bloc.add(const SubmitQuiz());
      await _settle();
      await _settle();
      expect(bloc.state.submissionStatus, QuizSubmissionStatus.submitted);
      await bloc.close();
    });

    test('50/50 leaves two options, keeps the pick, works once', () async {
      final four = _question('q1')
        ..['options'] = [
          for (final key in ['A', 'B', 'C', 'D'])
            {
              'key': key,
              'text': {'bn': key, 'en': key},
            },
        ];
      final s = _setup({
        'GET /quizzes/daily': (
          200,
          _ok({
            'source': 'daily',
            'id': 'quiz1',
            'timeLimitSeconds': 180,
            'totalQuestions': 2,
            'questions': [
              four,
              {...four, 'id': 'q2'},
            ],
          }),
        ),
        'POST /quizzes/attempts': (201, _attemptResult),
      });
      final bloc = _bloc(s.source, const QuizLaunchArgs.daily(), () => now0);
      bloc.add(const LoadQuiz());
      await _settle();
      await _settle();
      expect(bloc.state.canUseFiftyFifty, isTrue);

      bloc.add(const SelectAnswer('B'));
      bloc.add(const UseFiftyFifty());
      await _settle();
      final visible = bloc.state.visibleOptions.map((o) => o.key);
      expect(visible, hasLength(2));
      expect(visible, contains('B'));
      expect(bloc.state.canUseFiftyFifty, isFalse);

      // A hidden option can no longer be picked.
      final hidden = [
        'A',
        'B',
        'C',
        'D',
      ].firstWhere((k) => !visible.contains(k));
      bloc.add(SelectAnswer(hidden));
      await _settle();
      expect(bloc.state.selectedAnswer, 'B');

      // Spent: the next question keeps all four.
      bloc.add(const GoToNextQuestion());
      bloc.add(const UseFiftyFifty());
      await _settle();
      expect(bloc.state.visibleOptions, hasLength(4));

      bloc.add(const SubmitQuiz());
      await _settle();
      final body = s.http.last.data as Map<String, dynamic>;
      expect(body['used5050Lifeline'], isTrue);
      await bloc.close();
    });

    test('category quiz submits as "category" with its categoryId', () async {
      final s = _setup({
        'GET /quizzes/categories/cat1/quiz': (
          200,
          _ok({
            'source': 'category',
            'category': {'id': 'cat1'},
            'pointsReward': 0,
            'timeLimitSeconds': 70,
            'totalQuestions': 1,
            'questions': [_question('q1')],
          }),
        ),
        'POST /quizzes/attempts': (201, _attemptResult),
      });
      const category = QuizCategory(
        id: 'cat1',
        name: LocalizedText(bn: 'ক', en: 'A'),
        description: LocalizedText.empty,
        iconUrl: null,
        displayOrder: 1,
        totalQuestions: LocalizedCount(value: 1, text: LocalizedText.empty),
        isActive: true,
      );
      final bloc = _bloc(
        s.source,
        QuizLaunchArgs.category(category),
        () => DateTime(2026),
      );
      bloc.add(const LoadQuiz());
      await _settle();
      await _settle();
      bloc.add(const SelectAnswer('A'));
      bloc.add(const SubmitQuiz());
      await _settle();
      final body = s.http.last.data as Map<String, dynamic>;
      expect(body['attemptType'], 'category');
      expect(body['categoryId'], 'cat1');
      expect(body.containsKey('quizId'), isFalse);
      await bloc.close();
    });

    test('a 404 quiz is shown as empty, not as an error', () async {
      final s = _setup({});
      final bloc = _bloc(
        s.source,
        const QuizLaunchArgs.daily(),
        () => DateTime(2026),
      );
      bloc.add(const LoadQuiz());
      await _settle();
      await _settle();
      expect(bloc.state.loadStatus, QuizLoadStatus.empty);
      await bloc.close();
    });
  });
}
