import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:islami_app_noorify/features/planner/data/datasources/quiz_plan_remote_data_source.dart';
import 'package:islami_app_noorify/features/planner/data/models/quiz_plan_model.dart';
import 'package:islami_app_noorify/features/planner/data/repositories/quiz_plan_repository_impl.dart';
import 'package:islami_app_noorify/features/planner/domain/entities/quiz_plan.dart';
import 'package:islami_app_noorify/features/planner/domain/usecases/abandon_quiz_plan.dart';
import 'package:islami_app_noorify/features/planner/domain/usecases/get_planned_questions.dart';
import 'package:islami_app_noorify/features/planner/domain/usecases/get_quiz_plan.dart';
import 'package:islami_app_noorify/features/planner/domain/usecases/get_quiz_plans.dart';
import 'package:islami_app_noorify/features/planner/domain/usecases/start_quiz_plan.dart';
import 'package:islami_app_noorify/features/planner/domain/usecases/submit_planned_quiz.dart';
import 'package:islami_app_noorify/features/planner/domain/usecases/update_quiz_plan.dart';
import 'package:islami_app_noorify/features/planner/presentation/bloc/planned_quiz_bloc.dart';
import 'package:islami_app_noorify/features/planner/presentation/bloc/planner_bloc.dart';
import 'package:islami_app_noorify/features/planner/presentation/bloc/quiz_plan_detail_bloc.dart';
import 'package:islami_app_noorify/features/planner/presentation/quiz_plan_failure_message.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_enums.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_state.dart';

typedef _Handler = (int, Object) Function(RequestOptions);

/// Answers by `METHOD /path`, and remembers every request.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.routes);

  final Map<String, _Handler> routes;
  final requests = <RequestOptions>[];

  RequestOptions get last => requests.last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final key = '${options.method} ${options.uri.path.split('/api/v1').last}';
    final handler = routes[key];
    final (status, body) = handler == null
        ? (404, {'success': false, 'message': 'Quiz plan not found'})
        : handler(options);
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

({QuizPlanRemoteDataSourceImpl source, _StubAdapter http}) _setup(
  Map<String, _Handler> routes,
) {
  final http = _StubAdapter(routes);
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://example.test/api/v1',
      validateStatus: (s) => s != null && s < 500,
    ),
  )..httpClientAdapter = http;
  return (
    source: QuizPlanRemoteDataSourceImpl(dio: dio, local: _FakeLocal()),
    http: http,
  );
}

Map<String, Object?> _ok(Object? data, {Object? meta}) => {
  'statusCode': 200,
  'success': true,
  'message': 'ok',
  'data': data,
  'meta': ?meta,
};

Map<String, Object?> _portion(
  String id,
  int order, {
  bool done = false,
  num? score,
}) => {
  'id': id,
  'order': order,
  'categoryId': 'cat1',
  'categoryName': {'bn': 'হাদিস ও সুন্নাহ', 'en': 'Hadith & Sunnah'},
  'totalQuestions': 2,
  'isCompleted': done,
  'attemptId': done ? 'att_$id' : null,
  'scorePercentage': done ? score : null,
  'completedAt': done ? '2026-09-26T06:00:00.000Z' : null,
};

Map<String, Object?> _plan(
  String id, {
  String status = 'planned',
  List<Map<String, Object?>>? portions,
  String name = 'Evening practice',
}) {
  final parts = portions ?? [_portion('p1', 1), _portion('p2', 2)];
  final done = parts.where((p) => p['isCompleted'] == true).length;
  return {
    'id': id,
    'name': name,
    'scheduledAt': '2026-09-30T12:00:00.000Z',
    'startedAt': status == 'planned' ? null : '2026-09-26T05:00:00.000Z',
    'createdAt': '2026-09-26T04:00:00.000Z',
    'status': status,
    'totalQuizzes': parts.length,
    'completedQuizzes': done,
    'remainingQuizzes': parts.length - done,
    'totalQuestions': parts.length * 2,
    'completionPercentage': parts.isEmpty ? 0 : (done * 100 ~/ parts.length),
    'portions': parts,
  };
}

Map<String, Object?> _question(String id, int order) => {
  'id': id,
  'categoryId': 'cat1',
  'question': {'bn': 'প্রশ্ন $id', 'en': 'Question $id'},
  'options': [
    {
      'key': 'A',
      'text': {'bn': 'ক', 'en': 'a'},
    },
    {
      'key': 'D',
      'text': {'bn': 'ঘ', 'en': null},
    },
  ],
  'difficulty': 'easy',
  'checkedBy': null,
  'portionId': 'p1',
  'questionOrder': order,
};

Map<String, Object?> _attempt(List<Map<String, Object?>> answers) => {
  'statusCode': 201,
  'success': true,
  'message': 'Planned quiz completed',
  'data': {
    'id': 'att1',
    'planId': 'plan1',
    'portionId': 'p1',
    'attemptType': 'plan',
    'answeredQuestions': 1,
    'unansweredQuestions': 1,
    'wrongAnswers': 0,
    'answeredPercentage': 50,
    'correctPercentage': 50,
    'accuracyPercentage': 100,
    'totalQuestions': 2,
    'correctAnswers': 1,
    'incorrectAnswers': 1,
    'scorePercentage': 50,
    'pointsEarned': 0,
    'maxPoints': 2.5,
    'amol': null,
    'timeSpentSeconds': 42,
    'completedAt': '2026-09-26T06:00:00.000Z',
    'answers': answers,
  },
};

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 30));

void main() {
  final appText = AppText.forLanguage(AppLanguage.english);

  group('dates', () {
    test('UTC from the API is shown in local time, never shifted by hand', () {
      final parsed = readQuizPlanDate('2026-09-30T12:00:00.000Z')!;
      expect(parsed.isUtc, isFalse);
      expect(parsed, DateTime.utc(2026, 9, 30, 12).toLocal());
      // An offset is honoured too: 18:00 in Dhaka is the same instant.
      expect(
        readQuizPlanDate('2026-09-30T18:00:00+06:00'),
        DateTime.utc(2026, 9, 30, 12).toLocal(),
      );
      expect(readQuizPlanDate(null), isNull);
    });

    test('a local schedule is sent as the same instant in UTC', () {
      final local = DateTime.utc(2026, 9, 30, 12).toLocal();
      expect(writeQuizPlanDate(local), '2026-09-30T12:00:00.000Z');
    });
  });

  group('QuizPlanRemoteDataSource', () {
    test('create: body, auth and the parsed plan', () async {
      final s = _setup({
        'POST /quizzes/plans': (_) => (201, _ok(_plan('plan1'))),
      });
      final plan = await s.source.createPlan(
        QuizPlanDraft(
          name: '  Evening practice ',
          scheduledAt: DateTime.utc(2026, 9, 30, 12).toLocal(),
          portions: const [
            QuizPlanPortionDraft(
              categoryId: '6ab60214ac63e388566ec6de',
              categoryName: LocalizedText.empty,
              quizCount: 1,
              questionCount: 15,
            ),
          ],
        ),
      );
      expect(s.http.last.headers['Authorization'], 'Bearer tkn');
      expect(s.http.last.data, {
        'name': 'Evening practice',
        'scheduledAt': '2026-09-30T12:00:00.000Z',
        'portions': [
          {
            'categoryId': '6ab60214ac63e388566ec6de',
            'quizCount': 1,
            'questionCount': 15,
          },
        ],
      });
      expect(plan.status, QuizPlanStatus.planned);
      expect(plan.startedAt, isNull);
      expect(plan.portions.map((p) => p.order), [1, 2]);
      expect(plan.portions.first.attemptId, isNull);
      expect(plan.portions.first.scorePercentage, isNull);
      expect(
        plan.portions.first.categoryName.resolve(AppLanguage.bangla),
        'হাদিস ও সুন্নাহ',
      );
    });

    test('a plan without a schedule sends no scheduledAt', () {
      const draft = QuizPlanDraft(name: 'x', scheduledAt: null, portions: []);
      expect(draft.toJson().containsKey('scheduledAt'), isFalse);
    });

    test('list: page and limit, meta, and an empty page', () async {
      final s = _setup({
        'GET /quizzes/plans': (r) => (
          200,
          _ok(
            r.uri.queryParameters['page'] == '1' ? [_plan('plan1')] : [],
            meta: {'page': 1, 'limit': 1, 'total': 3, 'totalPage': 3},
          ),
        ),
      });
      final page = await s.source.getPlans(page: 1, limit: 1);
      expect(s.http.last.uri.queryParameters, {'page': '1', 'limit': '1'});
      expect(page.plans.single.id, 'plan1');
      expect(page.meta.hasMore, isTrue);
      final empty = await s.source.getPlans(page: 9, limit: 1);
      expect(empty.plans, isEmpty);
    });

    test('statuses, including one this build does not know', () {
      for (final (raw, status) in [
        ('planned', QuizPlanStatus.planned),
        ('in_progress', QuizPlanStatus.inProgress),
        ('completed', QuizPlanStatus.completed),
        ('abandoned', QuizPlanStatus.abandoned),
        ('paused', QuizPlanStatus.unknown),
      ]) {
        final plan = QuizPlanModel.fromJson(_plan('p', status: raw));
        expect(plan.status, status);
        expect(plan.rawStatus, raw);
      }
      final unknown = QuizPlanModel.fromJson(_plan('p', status: 'paused'));
      expect(unknown.canStart, isFalse);
      expect(unknown.canContinue, isFalse);
    });

    test('update sends only what changed; clearing sends null', () async {
      final s = _setup({
        'PATCH /quizzes/plans/plan1': (_) =>
            (200, _ok(_plan('plan1', name: 'New One Practice'))),
      });
      final plan = await s.source.updatePlan(
        'plan1',
        const QuizPlanUpdate(name: 'New One Practice'),
      );
      expect(s.http.last.data, {'name': 'New One Practice'});
      expect(plan.name, 'New One Practice');
      await s.source.updatePlan(
        'plan1',
        const QuizPlanUpdate(clearSchedule: true),
      );
      expect(s.http.last.data, {'scheduledAt': null});
    });

    test('DELETE abandons: the plan comes back as abandoned', () async {
      final s = _setup({
        'DELETE /quizzes/plans/plan1': (_) =>
            (200, _ok(_plan('plan1', status: 'abandoned'))),
      });
      final plan = await s.source.abandonPlan('plan1');
      expect(s.http.last.method, 'DELETE');
      expect(plan.status, QuizPlanStatus.abandoned);
      expect(plan.canAbandon, isFalse);
      expect(plan.canStart, isFalse);
    });

    test('start posts no body and returns in_progress', () async {
      final s = _setup({
        'POST /quizzes/plans/plan1/start': (_) =>
            (200, _ok(_plan('plan1', status: 'in_progress'))),
      });
      final plan = await s.source.startPlan('plan1');
      expect(s.http.last.data, isNull);
      expect(plan.status, QuizPlanStatus.inProgress);
      expect(plan.startedAt, isNotNull);
      expect(plan.canContinue, isTrue);
      expect(plan.nextPortion?.id, 'p1');
    });

    test('questions: query, string difficulty, bilingual text', () async {
      final s = _setup({
        'GET /quizzes/plans/plan1/questions': (_) => (
          200,
          _ok(
            [_question('q1', 1), _question('q2', 2)],
            meta: {'page': 1, 'limit': 10, 'total': 2, 'totalPage': 1},
          ),
        ),
      });
      final page = await s.source.getQuestions(
        planId: 'plan1',
        portionId: 'p1',
        page: 1,
        limit: 10,
      );
      expect(s.http.last.uri.queryParameters, {
        'portionId': 'p1',
        'page': '1',
        'limit': '10',
      });
      final q = page.questions.first;
      expect(q.difficulty, QuizDifficulty.easy);
      expect(q.questionOrder, 1);
      expect(q.portionId, 'p1');
      expect(q.question.resolve(AppLanguage.english), 'Question q1');
      expect(q.options.last.key, 'D');
      expect(q.options.last.text.resolve(AppLanguage.english), 'ঘ');
    });

    test('submit: path, body and the server-scored result', () async {
      final s = _setup({
        'POST /quizzes/plans/plan1/portions/p1/attempts': (_) => (
          201,
          _attempt([
            {
              'questionId': 'q1',
              'checkedBy': 'A',
              'correctAnswerKey': 'A',
              'isCorrect': true,
            },
            {
              'questionId': 'q2',
              'checkedBy': null,
              'correctAnswerKey': 'D',
              'isCorrect': false,
            },
          ]),
        ),
      });
      final result = await s.source.submitAttempt(
        planId: 'plan1',
        portionId: 'p1',
        submission: const PlannedQuizSubmission(
          timeSpentSeconds: 42,
          used5050Lifeline: false,
          answers: [],
        ),
      );
      expect(result.attemptType, QuizAttemptType.plan);
      expect(result.planId, 'plan1');
      expect(result.portionId, 'p1');
      expect(result.amol, isNull);
      expect(result.answers.last.correctAnswerKey, 'D');
      expect(result.answers.last.checkedBy, isNull);
      expect(result.accuracyPercentage, 100);
    });
  });

  group('errors', () {
    test('localized messages; server text never shown', () async {
      final s = _setup({
        'POST /quizzes/plans/plan1/start': (_) =>
            (409, {'success': false, 'message': 'This plan was abandoned'}),
        'GET /quizzes/plans/plan1/questions': (_) =>
            (409, {'success': false, 'message': 'Start the quiz plan first'}),
        'POST /quizzes/plans/plan1/portions/p1/attempts': (_) => (
          409,
          {
            'success': false,
            'message': 'This quiz portion is already completed',
          },
        ),
        'POST /quizzes/plans': (_) => (
          400,
          {'success': false, 'message': 'Category x has only 3 available'},
        ),
      });
      final repo = QuizPlanRepositoryImpl(s.source);
      Future<Failure> fail(Future<dynamic> call) async =>
          (await call).fold((f) => f, (_) => throw StateError('no failure'));

      final start = await fail(repo.startPlan('plan1'));
      expect(
        quizPlanFailureMessage(appText, start, QuizPlanAction.start),
        appText.planErrorAbandoned,
      );
      final questions = await fail(repo.getQuestions(planId: 'plan1'));
      expect(
        quizPlanFailureMessage(appText, questions, QuizPlanAction.questions),
        appText.planErrorNotStarted,
      );
      final submit = await fail(
        repo.submitAttempt(
          planId: 'plan1',
          portionId: 'p1',
          submission: const PlannedQuizSubmission(
            timeSpentSeconds: 1,
            used5050Lifeline: false,
            answers: [],
          ),
        ),
      );
      expect(
        quizPlanFailureMessage(appText, submit, QuizPlanAction.submit),
        appText.planErrorPortionDone,
      );
      final missing = await fail(repo.getPlan('nope'));
      expect(
        quizPlanFailureMessage(appText, missing, QuizPlanAction.load),
        appText.planErrorNotFound,
      );
      final invalid = await fail(
        repo.createPlan(
          const QuizPlanDraft(name: 'x', scheduledAt: null, portions: []),
        ),
      );
      final message = quizPlanFailureMessage(
        appText,
        invalid,
        QuizPlanAction.create,
      );
      expect(message, appText.planErrorInvalid);
      expect(message, isNot(contains('Category x')));
      // The server's text is kept on the failure for debugging.
      expect(invalid.message, contains('Category x'));
      expect(
        quizPlanFailureMessage(
          appText,
          const ServerFailure('expired', statusCode: 401),
          QuizPlanAction.load,
        ),
        appText.quizErrorSession,
      );
      expect(
        quizPlanFailureMessage(
          appText,
          const NetworkFailure(),
          QuizPlanAction.load,
        ),
        appText.quizErrorNetwork,
      );
    });
  });

  group('PlannerBloc', () {
    PlannerBloc bloc(QuizPlanRemoteDataSourceImpl source) {
      final repo = QuizPlanRepositoryImpl(source);
      return PlannerBloc(
        getPlans: GetQuizPlans(repo),
        updatePlan: UpdateQuizPlan(repo),
        abandonPlan: AbandonQuizPlan(repo),
        pageSize: 2,
      );
    }

    test('pages, tabs, and abandon moving a plan out of My Plan', () async {
      final s = _setup({
        'GET /quizzes/plans': (r) => r.uri.queryParameters['page'] == '1'
            ? (
                200,
                _ok(
                  [_plan('a'), _plan('b', status: 'completed')],
                  meta: {'page': 1, 'limit': 2, 'total': 3, 'totalPage': 2},
                ),
              )
            : (
                200,
                _ok(
                  [_plan('c', status: 'in_progress')],
                  meta: {'page': 2, 'limit': 2, 'total': 3, 'totalPage': 2},
                ),
              ),
        'DELETE /quizzes/plans/a': (_) =>
            (200, _ok(_plan('a', status: 'abandoned'))),
      });
      final b = bloc(s.source)..add(const LoadQuizPlans());
      await _settle();
      expect(b.state.plans.map((p) => p.id), ['a', 'b']);
      expect(b.state.hasMore, isTrue);
      b.add(const LoadMoreQuizPlans());
      await _settle();
      expect(b.state.plans.map((p) => p.id), ['a', 'b', 'c']);
      expect(b.state.hasMore, isFalse);
      expect(b.state.activePlans.map((p) => p.id), ['a', 'c']);
      expect(b.state.closedPlans.map((p) => p.id), ['b']);

      b.add(const AbandonQuizPlanRequested('a'));
      await _settle();
      expect(b.state.activePlans.map((p) => p.id), ['c']);
      expect(b.state.closedPlans.map((p) => p.id), ['a', 'b']);
      expect(b.state.notice?.action, QuizPlanAction.abandon);
      expect(b.state.notice?.failure, isNull);
      await b.close();
    });

    test('an empty list and a failed load', () async {
      final empty = _setup({
        'GET /quizzes/plans': (_) => (
          200,
          _ok([], meta: {'page': 1, 'limit': 10, 'total': 0, 'totalPage': 0}),
        ),
      });
      final b = bloc(empty.source)..add(const LoadQuizPlans());
      await _settle();
      expect(b.state.status, PlannerStatus.success);
      expect(b.state.visiblePlans, isEmpty);
      await b.close();

      final failing = _setup({
        'GET /quizzes/plans': (_) =>
            (401, {'success': false, 'message': 'Please provide a token'}),
      });
      final f = bloc(failing.source)..add(const LoadQuizPlans());
      await _settle();
      expect(f.state.status, PlannerStatus.failure);
      expect(f.state.failure?.statusCode, 401);
      await f.close();
    });
  });

  group('complete flow', () {
    test('start, play two pages, submit, and the plan progresses', () async {
      var progressed = false;
      final s = _setup({
        'GET /quizzes/plans/plan1': (_) => (
          200,
          _ok(
            progressed
                ? _plan(
                    'plan1',
                    status: 'in_progress',
                    portions: [
                      _portion('p1', 1, done: true, score: 50),
                      _portion('p2', 2),
                    ],
                  )
                : _plan('plan1'),
          ),
        ),
        'POST /quizzes/plans/plan1/start': (_) =>
            (200, _ok(_plan('plan1', status: 'in_progress'))),
        'GET /quizzes/plans/plan1/questions': (r) =>
            r.uri.queryParameters['page'] == '1'
            ? (
                200,
                _ok(
                  [_question('q1', 1)],
                  meta: {'page': 1, 'limit': 1, 'total': 2, 'totalPage': 2},
                ),
              )
            : (
                200,
                _ok(
                  [_question('q2', 2)],
                  meta: {'page': 2, 'limit': 1, 'total': 2, 'totalPage': 2},
                ),
              ),
        'POST /quizzes/plans/plan1/portions/p1/attempts': (_) {
          progressed = true;
          return (201, _attempt([]));
        },
      });
      final repo = QuizPlanRepositoryImpl(s.source);
      final detail = QuizPlanDetailBloc(
        planId: 'plan1',
        getPlan: GetQuizPlan(repo),
        startPlan: StartQuizPlan(repo),
        updatePlan: UpdateQuizPlan(repo),
        abandonPlan: AbandonQuizPlan(repo),
      )..add(const LoadQuizPlanDetail());
      await _settle();
      expect(detail.state.plan?.canStart, isTrue);

      detail.add(const StartQuizPlanRequested());
      await _settle();
      expect(detail.state.plan?.status, QuizPlanStatus.inProgress);
      expect(detail.state.startedSerial, 1);
      final plan = detail.state.plan!;

      final quiz = PlannedQuizBloc(
        plan: plan,
        portion: plan.nextPortion!,
        getQuestions: GetPlannedQuestions(repo),
        submit: SubmitPlannedQuiz(repo),
        pageSize: 1,
        tickInterval: const Duration(hours: 1),
      )..add(const LoadPlannedQuestions());
      await _settle();
      expect(quiz.state.totalQuestions, 2);
      expect(quiz.state.isLastQuestion, isFalse);

      quiz.add(const SelectPlannedAnswer('A'));
      quiz.add(const NextPlannedQuestion()); // fetches page 2
      await _settle();
      expect(quiz.state.currentIndex, 1);
      expect(quiz.state.isLastQuestion, isTrue);

      // Left unanswered; submitted twice in a row.
      quiz
        ..add(const SubmitPlannedQuizAttempt())
        ..add(const SubmitPlannedQuizAttempt());
      await _settle();
      final posts = s.http.requests.where(
        (r) => r.method == 'POST' && r.uri.path.endsWith('/attempts'),
      );
      expect(posts, hasLength(1));
      final body = posts.single.data as Map<String, dynamic>;
      expect(body['used5050Lifeline'], isFalse);
      expect(body['answers'], [
        {'questionId': 'q1', 'checkedBy': 'A'},
        {'questionId': 'q2', 'checkedBy': null},
      ]);
      expect(body.containsKey('scorePercentage'), isFalse);
      expect(quiz.state.submissionStatus, QuizSubmissionStatus.submitted);
      expect(quiz.state.result?.scorePercentage, 50);

      // Back on the plan: the first quiz is completed, the second is next.
      detail.add(const LoadQuizPlanDetail());
      await _settle();
      final after = detail.state.plan!;
      expect(after.portions.first.isCompleted, isTrue);
      expect(after.portions.first.scorePercentage, 50);
      expect(after.completedQuizzes, 1);
      expect(after.nextPortion?.id, 'p2');
      await quiz.close();
      await detail.close();
    });

    test('an already completed portion fails and can be retried', () async {
      final s = _setup({
        'GET /quizzes/plans/plan1/questions': (_) => (
          200,
          _ok(
            [_question('q1', 1)],
            meta: {'page': 1, 'limit': 10, 'total': 1, 'totalPage': 1},
          ),
        ),
        'POST /quizzes/plans/plan1/portions/p1/attempts': (_) => (
          409,
          {
            'success': false,
            'message': 'This quiz portion is already completed',
          },
        ),
      });
      final repo = QuizPlanRepositoryImpl(s.source);
      final plan = QuizPlanModel.fromJson(
        _plan('plan1', status: 'in_progress'),
      );
      final quiz = PlannedQuizBloc(
        plan: plan,
        portion: plan.portions.first,
        getQuestions: GetPlannedQuestions(repo),
        submit: SubmitPlannedQuiz(repo),
        tickInterval: const Duration(hours: 1),
      )..add(const LoadPlannedQuestions());
      await _settle();
      quiz.add(const SelectPlannedAnswer('D'));
      quiz.add(const SubmitPlannedQuizAttempt());
      await _settle();
      expect(quiz.state.submissionStatus, QuizSubmissionStatus.failed);
      expect(quiz.state.submitFailure?.statusCode, 409);
      expect(quiz.state.answers, {'q1': 'D'});
      await quiz.close();
    });
  });
}
