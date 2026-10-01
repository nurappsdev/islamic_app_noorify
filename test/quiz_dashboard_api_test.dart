import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/dashboard/presentation/bloc/quiz_dashboard_bloc.dart';
import 'package:tuhfatul_muslim/features/quiz/data/datasources/quiz_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/quiz/data/repositories/quiz_repository_impl.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_dashboard.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_enums.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/usecases/get_quiz_dashboard.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/usecases/get_quiz_dashboard_comparison.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/quiz_failure_message.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_state.dart';

/// Answers by path; a route may give one body per page.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.routes);

  final Map<String, (int, Object Function(RequestOptions))> routes;
  final requests = <RequestOptions>[];

  List<RequestOptions> to(String path) =>
      requests.where((r) => r.uri.path.endsWith(path)).toList();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final key = options.uri.path.split('/api/v1').last;
    final route = routes[key];
    final (status, body) = route == null
        ? (404, {'success': false, 'message': 'API not found'})
        : (route.$1, route.$2(options));
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
  @override
  String? getToken() => 'tkn';

  @override
  bool get hasToken => true;

  @override
  Future<void> cacheToken(String token) async {}

  @override
  Future<void> clearToken() async {}
}

({QuizRemoteDataSourceImpl source, _StubAdapter http}) _setup(
  Map<String, (int, Object Function(RequestOptions))> routes,
) {
  final http = _StubAdapter(routes);
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://example.test/api/v1',
      validateStatus: (s) => s != null && s < 500,
    ),
  )..httpClientAdapter = http;
  return (
    source: QuizRemoteDataSourceImpl(dio: dio, local: _FakeLocal()),
    http: http,
  );
}

Map<String, Object?> _day(
  String date, {
  int attempts = 1,
  bool legacy = false,
}) => {
  'date': date,
  'attempts': attempts,
  'totalQuestions': 12 * attempts,
  'correctAnswers': 9 * attempts,
  'answeredQuestions': legacy ? null : 11 * attempts,
  'unansweredQuestions': legacy ? null : attempts,
  'wrongAnswers': legacy ? null : 2 * attempts,
  'answeredPercentage': legacy ? null : 91.67,
  'correctPercentage': 75,
  'accuracyPercentage': legacy ? null : 81.82,
  'totalSeconds': 150 * attempts,
  'totalMinutes': 2.5 * attempts,
  'totalPoints': 1.88 * attempts,
  'bestScorePercentage': 75,
  'averageScorePercentage': 75,
};

Map<String, Object?> _totals() => {
  ..._day('x', attempts: 3),
  'daysTracked': 2,
  'currentStreak': 1,
  'averageMinutesPerDay': 1.07,
}..remove('date');

Map<String, Object?> _dashboard(
  List<Map<String, Object?>> days, {
  int page = 1,
  int totalPage = 1,
  int total = 7,
}) => {
  'statusCode': 200,
  'success': true,
  'message': 'Quiz dashboard retrieved successfully!',
  'data': {
    'from': '2026-09-20',
    'to': '2026-09-26',
    'period': 'weekly',
    'days': days,
    'totals': _totals(),
  },
  'meta': {
    'page': page,
    'limit': days.length,
    'total': total,
    'totalPage': totalPage,
  },
};

Map<String, Object?> _user(
  String key, {
  required int rank,
  required bool me,
  String name = 'User',
  List<Map<String, Object?>>? days,
}) => {
  'key': key,
  'rank': rank,
  'isCurrentUser': me,
  'userId': '${key}_id',
  'name': name,
  'avatarUrl': null,
  'totalPoints': me ? 120.5 : 340,
  'from': '2026-09-20',
  'to': '2026-09-26',
  'period': 'weekly',
  'meta': {'page': 1, 'limit': 7, 'total': 7, 'totalPage': 1},
  'days': days ?? [_day('2026-09-26')],
  'totals': _totals(),
};

Map<String, Object?> _comparison({
  List<Map<String, Object?>>? users,
  Object? difference = const {
    'attempts': -2,
    'totalPoints': -3.5,
    'totalMinutes': 4,
    'correctPercentage': 6.25,
    'isAhead': false,
  },
  int page = 1,
  int totalPage = 1,
}) => {
  'statusCode': 200,
  'success': true,
  'message': 'Quiz comparison retrieved successfully!',
  'data': {
    'from': '2026-09-20',
    'to': '2026-09-26',
    'period': 'weekly',
    'comparedWith': users == null || users.length > 1 ? 'first_place' : null,
    // The server lists the current user first; the order must not matter.
    'users':
        users ??
        [
          _user('user2', rank: 1, me: false, name: 'Leader'),
          _user('user1', rank: 7, me: true, name: 'Me'),
        ],
    'difference': difference,
  },
  'meta': {'page': page, 'limit': 7, 'total': 7, 'totalPage': totalPage},
};

Map<String, Object?> _evaluated(
  String id, {
  required String status,
  String? checkedBy,
}) => {
  'id': id,
  'categoryId': 'cat1',
  'category': {
    'id': 'cat1',
    'name': {'bn': 'সালাত', 'en': 'Salah'},
    'iconUrl': null,
  },
  'checkedBy': checkedBy,
  'question': {'bn': 'প্রশ্ন $id', 'en': 'Question $id'},
  'options': [
    {
      'key': 'A',
      'text': {'bn': '৩', 'en': '3'},
    },
    {
      'key': 'C',
      'text': {'bn': '৫', 'en': null},
    },
  ],
  'correctAnswerKey': 'C',
  'explanation': {'bn': 'পাঁচ ওয়াক্ত', 'en': 'Five times'},
  'difficulty': {'key': 'hard', 'bn': 'কঠিন', 'en': 'Hard'},
  'displayOrder': 4,
  'isActive': true,
  'isCorrect': status == 'correct',
  'status': status,
};

void main() {
  final weekly = QuizDashboardFilter(
    period: QuizDashboardPeriod.weekly,
    from: DateTime(2026, 9, 20),
    to: DateTime(2026, 9, 26),
    limit: 7,
  );

  group('GET /quizzes/dashboard', () {
    test('sends only the set parameters, dates as YYYY-MM-DD', () async {
      final s = _setup({
        '/quizzes/dashboard': (200, (_) => _dashboard([_day('2026-09-26')])),
      });
      await s.source.getDashboard(
        const QuizDashboardFilter(period: QuizDashboardPeriod.daily, days: 1),
      );
      await s.source.getDashboard(weekly);
      await s.source.getDashboard(
        QuizDashboardFilter(
          period: QuizDashboardPeriod.monthly,
          from: DateTime(2026, 9),
          to: DateTime(2026, 9, 30),
          page: 2,
          limit: 30,
        ),
      );
      final queries = s.http.requests.map((r) => r.uri.queryParameters);
      expect(queries.elementAt(0), {
        'period': 'daily',
        'days': '1',
        'page': '1',
        'limit': '10',
      });
      expect(queries.elementAt(1), {
        'period': 'weekly',
        'from': '2026-09-20',
        'to': '2026-09-26',
        'page': '1',
        'limit': '7',
      });
      expect(queries.elementAt(2), {
        'period': 'monthly',
        'from': '2026-09-01',
        'to': '2026-09-30',
        'page': '2',
        'limit': '30',
      });
      expect(s.http.requests.first.headers['Authorization'], 'Bearer tkn');
    });

    test('parses days, totals and meta; legacy nulls stay null', () async {
      final s = _setup({
        '/quizzes/dashboard': (
          200,
          (_) => _dashboard([
            _day('2026-09-25', legacy: true),
            _day('2026-09-26', attempts: 0),
          ], totalPage: 3),
        ),
      });
      final data = await s.source.getDashboard(weekly);
      expect(data.period, QuizDashboardPeriod.weekly);
      expect(data.days.map((d) => d.date), ['2026-09-25', '2026-09-26']);
      expect(data.days.first.accuracyPercentage, isNull);
      expect(data.days.first.correctPercentage, 75);
      expect(data.days.last.attempts, 0);
      expect(data.totals.currentStreak, 1);
      expect(data.totals.averageMinutesPerDay, 1.07);
      expect(data.totals.accuracyPercentage, 81.82);
      expect(data.meta.hasMore, isTrue);
    });

    test('an empty range parses to no days', () async {
      final s = _setup({'/quizzes/dashboard': (200, (_) => _dashboard([]))});
      final data = await s.source.getDashboard(weekly);
      expect(data.days, isEmpty);
    });

    test('a 400 becomes a ServerException', () {
      final s = _setup({
        '/quizzes/dashboard': (
          400,
          (_) => {'success': false, 'message': 'from must be on or before to'},
        ),
      });
      expect(
        s.source.getDashboard(weekly),
        throwsA(isA<ServerException>().having((e) => e.statusCode, 's', 400)),
      );
    });
  });

  group('comparison endpoints', () {
    test('compare and history/compare are separate requests', () async {
      final s = _setup({
        '/quizzes/dashboard/compare': (200, (_) => _comparison()),
        '/quizzes/dashboard/history/compare': (200, (_) => _comparison()),
      });
      await s.source.getDashboardComparison(weekly);
      await s.source.getDashboardHistoryComparison(weekly);
      expect(s.http.requests.map((r) => r.uri.path.split('/api/v1').last), [
        '/quizzes/dashboard/compare',
        '/quizzes/dashboard/history/compare',
      ]);
      expect(s.http.requests.last.uri.queryParameters['from'], '2026-09-20');
    });

    test(
      'current user by isCurrentUser, rank and difference as sent',
      () async {
        final s = _setup({
          '/quizzes/dashboard/compare': (200, (_) => _comparison()),
        });
        final c = await s.source.getDashboardComparison(weekly);
        expect(c.currentUser?.name, 'Me');
        expect(c.currentUser?.rank, 7);
        expect(c.otherUser?.name, 'Leader');
        expect(c.otherUser?.rank, 1);
        expect(c.comparedWith, 'first_place');
        expect(c.difference?.isAhead, isFalse);
        expect(c.difference?.totalPoints, -3.5);
        expect(c.currentUser?.dashboard.totals.attempts, 3);
      },
    );

    test('nobody to compare with: one user, no difference', () async {
      final s = _setup({
        '/quizzes/dashboard/compare': (
          200,
          (_) => _comparison(
            users: [_user('user1', rank: 1, me: true)],
            difference: null,
          ),
        ),
      });
      final c = await s.source.getDashboardComparison(weekly);
      expect(c.otherUser, isNull);
      expect(c.difference, isNull);
    });

    test('an empty users list parses', () async {
      final s = _setup({
        '/quizzes/dashboard/compare': (
          200,
          (_) => _comparison(users: [], difference: null),
        ),
      });
      final c = await s.source.getDashboardComparison(weekly);
      expect(c.users, isEmpty);
      expect(c.currentUser, isNull);
    });
  });

  group('GET /quizzes/attempts/{id}/review', () {
    Map<String, Object?> review() => {
      'statusCode': 200,
      'success': true,
      'data': {
        'answeredQuestions': 2,
        'unansweredQuestions': 1,
        'wrongAnswers': 1,
        'answeredPercentage': 66.67,
        'correctPercentage': 33.33,
        'accuracyPercentage': 50,
        'id': 'att1',
        'attemptType': 'daily',
        'planId': null,
        'portionId': null,
        'quizId': 'quiz1',
        'category': null,
        'totalQuestions': 3,
        'correctAnswers': 1,
        'incorrectAnswers': 2,
        'scorePercentage': 33,
        'pointsEarned': 0.83,
        'maxPoints': 2.5,
        'timeSpentSeconds': 95,
        'used5050Lifeline': true,
        'completedAt': '2026-09-26T08:00:00.000Z',
        'questions': [
          _evaluated('q1', status: 'correct', checkedBy: 'C'),
          _evaluated('q2', status: 'incorrect', checkedBy: 'A'),
          _evaluated('q3', status: 'unanswered'),
        ],
        'review': {
          'correct': [_evaluated('q1', status: 'correct', checkedBy: 'C')],
          'incorrect': [_evaluated('q2', status: 'incorrect', checkedBy: 'A')],
          'unanswered': [_evaluated('q3', status: 'unanswered')],
        },
      },
    };

    test('parses the summary, statuses and groups', () async {
      final s = _setup({
        '/quizzes/attempts/att1/review': (200, (_) => review()),
      });
      final d = await s.source.getAttemptReview('att1');
      expect(s.http.requests.single.uri.path, endsWith('/att1/review'));
      expect(d.attempt.used5050Lifeline, isTrue);
      expect(d.attempt.pointsEarned, 0.83);
      expect(d.attempt.completedAt, DateTime.utc(2026, 9, 26, 8).toLocal());
      expect(d.unansweredQuestions, 1);
      expect(d.accuracyPercentage, 50);
      expect(d.questions.map((q) => q.status), [
        QuizAnswerStatus.correct,
        QuizAnswerStatus.incorrect,
        QuizAnswerStatus.unanswered,
      ]);
      expect(d.review.correct.single.id, 'q1');
      expect(d.review.incorrect.single.checkedBy, 'A');
      expect(d.review.unanswered.single.checkedBy, isNull);
    });

    test('bilingual question, options, explanation and difficulty', () async {
      final s = _setup({
        '/quizzes/attempts/att1/review': (200, (_) => review()),
      });
      final q = (await s.source.getAttemptReview('att1')).questions.first;
      expect(q.question.resolve(AppLanguage.bangla), 'প্রশ্ন q1');
      expect(q.question.resolve(AppLanguage.english), 'Question q1');
      // English missing: falls back to Bangla.
      expect(q.options.last.text.resolve(AppLanguage.english), '৫');
      expect(q.explanation.resolve(AppLanguage.english), 'Five times');
      expect(q.difficulty, QuizDifficulty.hard);
      expect(q.difficultyLabel.resolve(AppLanguage.bangla), 'কঠিন');
      expect(q.category?.name.resolve(AppLanguage.english), 'Salah');
      expect(q.correctAnswerKey, 'C');
    });

    test('status is taken as sent, even against isCorrect', () async {
      final s = _setup({
        '/quizzes/attempts/att1/review': (
          200,
          (_) => {
            'success': true,
            'data': {
              'id': 'att1',
              'questions': [
                {..._evaluated('q1', status: 'unanswered'), 'isCorrect': true},
              ],
            },
          },
        ),
      });
      final d = await s.source.getAttemptReview('att1');
      expect(d.questions.single.status, QuizAnswerStatus.unanswered);
    });

    test('404 is a ServerException and reads as "attempt not found"', () async {
      final s = _setup({});
      final repo = QuizRepositoryImpl(s.source);
      final result = await repo.getAttemptReview('missing');
      final failure = result.fold((f) => f, (_) => null);
      expect(failure?.statusCode, 404);
      final appText = AppText.forLanguage(AppLanguage.english);
      expect(
        quizFailureMessage(appText, failure, forAttempt: true),
        appText.quizErrorNotFound,
      );
      // The server's own text is never what the user sees.
      expect(
        quizFailureMessage(appText, failure, forAttempt: true),
        isNot(contains('API not found')),
      );
      expect(
        quizFailureMessage(appText, const NetworkFailure()),
        appText.quizErrorNetwork,
      );
      expect(
        quizFailureMessage(appText, const ServerFailure('x', statusCode: 401)),
        appText.quizErrorSession,
      );
    });
  });

  group('QuizDashboardBloc', () {
    QuizDashboardBloc bloc(QuizRemoteDataSourceImpl source) {
      final repo = QuizRepositoryImpl(source);
      return QuizDashboardBloc(
        getDashboard: GetQuizDashboard(repo),
        getComparison: GetQuizDashboardComparison(repo),
      );
    }

    Future<void> settle() =>
        Future<void>.delayed(const Duration(milliseconds: 30));

    test('ranges follow the date selector: day, Mon-Sun week, month', () {
      final date = DateTime(2026, 9, 26); // a Saturday
      final day = quizDashboardRange(QuizDashboardPeriod.daily, date);
      final week = quizDashboardRange(QuizDashboardPeriod.weekly, date);
      final month = quizDashboardRange(QuizDashboardPeriod.monthly, date);
      expect((day.from, day.to), (date, date));
      expect(
        (week.from, week.to),
        (DateTime(2026, 9, 21), DateTime(2026, 9, 27)),
      );
      expect(
        (month.from, month.to),
        (DateTime(2026, 9), DateTime(2026, 9, 30)),
      );
    });

    test('each period change requests the API again', () async {
      final s = _setup({
        '/quizzes/dashboard': (200, (_) => _dashboard([_day('2026-09-26')])),
        '/quizzes/dashboard/compare': (200, (_) => _comparison()),
      });
      final b = bloc(s.source)..add(const LoadQuizDashboard());
      await settle();
      b.add(const SelectPeriod(1));
      await settle();
      b.add(const SelectPeriod(2));
      await settle();
      final periods = s.http
          .to('/quizzes/dashboard')
          .map((r) => r.uri.queryParameters['period']);
      expect(periods, ['daily', 'weekly', 'monthly']);
      expect(s.http.to('/quizzes/dashboard/compare'), hasLength(3));
      expect(b.state.dashboardStatus, QuizDashboardLoadStatus.success);
      expect(b.state.comparison?.currentUser?.name, 'Me');
      await b.close();
    });

    test('a new date range replaces the old one', () async {
      final s = _setup({
        '/quizzes/dashboard': (200, (_) => _dashboard([_day('2026-09-26')])),
        '/quizzes/dashboard/compare': (200, (_) => _comparison()),
      });
      final b = bloc(s.source)..add(const LoadQuizDashboard());
      await settle();
      final first = s.http.to('/quizzes/dashboard').last.uri.queryParameters;
      b.add(const GoToPreviousDate());
      await settle();
      final second = s.http.to('/quizzes/dashboard').last.uri.queryParameters;
      expect(second['from'], isNot(first['from']));
      expect(
        DateTime.parse(
          first['from']!,
        ).difference(DateTime.parse(second['from']!)),
        const Duration(days: 1),
      );
      await b.close();
    });

    test('follows every page and merges the days', () async {
      final s = _setup({
        '/quizzes/dashboard': (
          200,
          (r) => r.uri.queryParameters['page'] == '1'
              ? _dashboard([_day('2026-09-20')], page: 1, totalPage: 2)
              : _dashboard([_day('2026-09-21')], page: 2, totalPage: 2),
        ),
        '/quizzes/dashboard/compare': (
          200,
          (r) => r.uri.queryParameters['page'] == '1'
              ? _comparison(totalPage: 2)
              : _comparison(page: 2, totalPage: 2),
        ),
      });
      final b = bloc(s.source)..add(const LoadQuizDashboard());
      await settle();
      expect(b.state.dashboard?.days.map((d) => d.date), [
        '2026-09-20',
        '2026-09-21',
      ]);
      expect(b.state.comparison?.currentUser?.dashboard.days, hasLength(2));
      await b.close();
    });

    test('a failure shows as failure, with nothing stale kept', () async {
      final s = _setup({
        '/quizzes/dashboard': (401, (_) => {'success': false, 'message': 'x'}),
        '/quizzes/dashboard/compare': (200, (_) => _comparison()),
      });
      final b = bloc(s.source)..add(const LoadQuizDashboard());
      await settle();
      expect(b.state.dashboardStatus, QuizDashboardLoadStatus.failure);
      expect(b.state.dashboardFailure?.statusCode, 401);
      expect(b.state.dashboard, isNull);
      await b.close();
    });

    test('rapid switching keeps only the latest period', () async {
      final s = _setup({
        '/quizzes/dashboard': (
          200,
          (r) => _dashboard([_day(r.uri.queryParameters['from']!)]),
        ),
        '/quizzes/dashboard/compare': (200, (_) => _comparison()),
      });
      final b = bloc(s.source)
        ..add(const SelectPeriod(1))
        ..add(const SelectPeriod(2));
      await settle();
      expect(b.state.selectedPeriod, 2);
      expect(b.state.dashboard?.days.single.date, endsWith('-01'));
      await b.close();
    });
  });
}
