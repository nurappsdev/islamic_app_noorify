import 'package:dio/dio.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/network/dio_client.dart';
import 'package:islami_app_noorify/core/services/api_constants.dart';
import 'package:islami_app_noorify/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:islami_app_noorify/features/planner/data/models/quiz_plan_model.dart';
import 'package:islami_app_noorify/features/planner/domain/entities/quiz_plan.dart';
import 'package:islami_app_noorify/features/quiz/data/datasources/quiz_api_requests.dart';

/// Talks to the `/quizzes/plans` endpoints. Throws [ServerException] /
/// [NetworkException] / [ParsingException]; never returns error states.
abstract interface class QuizPlanRemoteDataSource {
  /// `POST /quizzes/plans`.
  Future<QuizPlan> createPlan(QuizPlanDraft draft);

  /// `GET /quizzes/plans?page=N&limit=N`.
  Future<QuizPlanPage> getPlans({required int page, required int limit});

  /// `GET /quizzes/plans/{planId}`.
  Future<QuizPlan> getPlan(String planId);

  /// `PATCH /quizzes/plans/{planId}`.
  Future<QuizPlan> updatePlan(String planId, QuizPlanUpdate update);

  /// `DELETE /quizzes/plans/{planId}` - abandons the plan; the record stays.
  Future<QuizPlan> abandonPlan(String planId);

  /// `POST /quizzes/plans/{planId}/start`.
  Future<QuizPlan> startPlan(String planId);

  /// `GET /quizzes/plans/{planId}/questions?portionId=..&page=N&limit=N`.
  Future<PlannedQuestionPage> getQuestions({
    required String planId,
    String? portionId,
    String? categoryId,
    required int page,
    required int limit,
  });

  /// `POST /quizzes/plans/{planId}/portions/{portionId}/attempts`.
  Future<PlannedQuizResult> submitAttempt({
    required String planId,
    required String portionId,
    required PlannedQuizSubmission submission,
  });
}

class QuizPlanRemoteDataSourceImpl
    with QuizApiRequests
    implements QuizPlanRemoteDataSource {
  QuizPlanRemoteDataSourceImpl({Dio? dio, AuthLocalDataSource? local})
    : dio = dio ?? DioClient().dio,
      local = local ?? AuthLocalDataSourceImpl();

  @override
  final Dio dio;
  @override
  final AuthLocalDataSource local;

  @override
  Future<QuizPlan> createPlan(QuizPlanDraft draft) => _plan(
    () => dio.post<dynamic>(
      ApiConstants.quizPlansEndPoint,
      data: draft.toJson(),
      options: quizAuthOptions(),
    ),
  );

  @override
  Future<QuizPlanPage> getPlans({required int page, required int limit}) async {
    final json = await sendQuizRequest(
      () => dio.get<dynamic>(
        ApiConstants.quizPlansEndPoint,
        queryParameters: {'page': page, 'limit': limit},
        options: quizAuthOptions(),
      ),
    );
    final data = json['data'];
    if (data is! List) {
      throw ParsingException('Quiz plans response is missing "data".');
    }
    final plans = QuizPlanModel.listFromJson(data);
    return QuizPlanPage(
      plans: plans,
      meta: readQuizPlanMeta(json['meta'], plans.length),
    );
  }

  @override
  Future<QuizPlan> getPlan(String planId) => _plan(
    () => dio.get<dynamic>(
      ApiConstants.quizPlanEndPoint(planId),
      options: quizAuthOptions(),
    ),
  );

  @override
  Future<QuizPlan> updatePlan(String planId, QuizPlanUpdate update) => _plan(
    () => dio.patch<dynamic>(
      ApiConstants.quizPlanEndPoint(planId),
      data: update.toJson(),
      options: quizAuthOptions(),
    ),
  );

  @override
  Future<QuizPlan> abandonPlan(String planId) => _plan(
    () => dio.delete<dynamic>(
      ApiConstants.quizPlanEndPoint(planId),
      options: quizAuthOptions(),
    ),
  );

  @override
  Future<QuizPlan> startPlan(String planId) => _plan(
    () => dio.post<dynamic>(
      ApiConstants.quizPlanStartEndPoint(planId),
      options: quizAuthOptions(),
    ),
  );

  @override
  Future<PlannedQuestionPage> getQuestions({
    required String planId,
    String? portionId,
    String? categoryId,
    required int page,
    required int limit,
  }) async {
    final json = await sendQuizRequest(
      () => dio.get<dynamic>(
        ApiConstants.quizPlanQuestionsEndPoint(planId),
        queryParameters: {
          'portionId': ?portionId,
          'categoryId': ?categoryId,
          'page': page,
          'limit': limit,
        },
        options: quizAuthOptions(),
      ),
    );
    final data = json['data'];
    if (data is! List) {
      throw ParsingException('Planned questions response is missing "data".');
    }
    final questions = PlannedQuestionModel.listFromJson(data);
    return PlannedQuestionPage(
      questions: questions,
      meta: readQuizPlanMeta(json['meta'], questions.length),
    );
  }

  @override
  Future<PlannedQuizResult> submitAttempt({
    required String planId,
    required String portionId,
    required PlannedQuizSubmission submission,
  }) async {
    final json = await sendQuizRequest(
      () => dio.post<dynamic>(
        ApiConstants.quizPlanPortionAttemptsEndPoint(planId, portionId),
        data: submission.toJson(),
        options: quizAuthOptions(),
      ),
    );
    return PlannedQuizResultModel.fromJson(
      quizDataMap(json, 'Planned quiz attempt'),
    );
  }

  Future<QuizPlan> _plan(Future<Response<dynamic>> Function() request) async {
    final json = await sendQuizRequest(request);
    return QuizPlanModel.fromJson(quizDataMap(json, 'Quiz plan'));
  }
}
