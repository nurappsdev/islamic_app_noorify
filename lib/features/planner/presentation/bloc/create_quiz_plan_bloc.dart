import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/planner/domain/entities/quiz_plan.dart';
import 'package:islami_app_noorify/features/planner/domain/usecases/create_quiz_plan.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_category.dart';
import 'package:islami_app_noorify/features/quiz/domain/usecases/get_quiz_categories.dart';

enum CreateQuizPlanCategoriesStatus { loading, success, failure }

class CreateQuizPlanState {
  const CreateQuizPlanState({
    this.categoriesStatus = CreateQuizPlanCategoriesStatus.loading,
    this.categories = const [],
    this.categoriesFailure,
    this.portions = const [],
    this.isSubmitting = false,
    this.submitFailure,
    this.submitSerial = 0,
    this.created,
  });

  final CreateQuizPlanCategoriesStatus categoriesStatus;

  /// The quiz categories to pick from (`GET /quizzes/categories`).
  final List<QuizCategory> categories;
  final Failure? categoriesFailure;

  /// The quizzes added so far.
  final List<QuizPlanPortionDraft> portions;
  final bool isSubmitting;
  final Failure? submitFailure;

  /// Bumped per failed submit, so the same failure is shown each time.
  final int submitSerial;

  /// The server's plan, once created.
  final QuizPlan? created;

  CreateQuizPlanState copyWith({
    CreateQuizPlanCategoriesStatus? categoriesStatus,
    List<QuizCategory>? categories,
    Failure? categoriesFailure,
    List<QuizPlanPortionDraft>? portions,
    bool? isSubmitting,
    Failure? submitFailure,
    int? submitSerial,
    QuizPlan? created,
  }) {
    return CreateQuizPlanState(
      categoriesStatus: categoriesStatus ?? this.categoriesStatus,
      categories: categories ?? this.categories,
      categoriesFailure: categoriesFailure ?? this.categoriesFailure,
      portions: portions ?? this.portions,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitFailure: submitFailure ?? this.submitFailure,
      submitSerial: submitSerial ?? this.submitSerial,
      created: created ?? this.created,
    );
  }
}

abstract class CreateQuizPlanEvent {
  const CreateQuizPlanEvent();
}

/// Fetches the categories; also used by Try Again.
class LoadQuizPlanCategories extends CreateQuizPlanEvent {
  const LoadQuizPlanCategories();
}

class AddQuizPlanPortion extends CreateQuizPlanEvent {
  const AddQuizPlanPortion(this.portion);

  final QuizPlanPortionDraft portion;
}

class RemoveQuizPlanPortion extends CreateQuizPlanEvent {
  const RemoveQuizPlanPortion(this.index);

  final int index;
}

class SubmitQuizPlan extends CreateQuizPlanEvent {
  const SubmitQuizPlan({
    required this.name,
    required this.scheduledAt,
    this.pending,
  });

  final String name;
  final DateTime? scheduledAt;

  /// A quiz filled in on the form but not yet added with Add; it is sent
  /// with the others rather than silently dropped.
  final QuizPlanPortionDraft? pending;
}

/// The Create Plan form: the categories to pick from, the quizzes added, and
/// `POST /quizzes/plans`.
class CreateQuizPlanBloc
    extends Bloc<CreateQuizPlanEvent, CreateQuizPlanState> {
  CreateQuizPlanBloc({required this._getCategories, required this._createPlan})
    : super(const CreateQuizPlanState()) {
    on<LoadQuizPlanCategories>((event, emit) async {
      emit(
        state.copyWith(
          categoriesStatus: CreateQuizPlanCategoriesStatus.loading,
        ),
      );
      final result = await _getCategories();
      if (emit.isDone) return;
      result.fold(
        (failure) => emit(
          state.copyWith(
            categoriesStatus: CreateQuizPlanCategoriesStatus.failure,
            categoriesFailure: failure,
          ),
        ),
        (categories) => emit(
          state.copyWith(
            categoriesStatus: CreateQuizPlanCategoriesStatus.success,
            categories: categories,
          ),
        ),
      );
    });
    on<AddQuizPlanPortion>(
      (event, emit) =>
          emit(state.copyWith(portions: [...state.portions, event.portion])),
    );
    on<RemoveQuizPlanPortion>((event, emit) {
      if (event.index < 0 || event.index >= state.portions.length) return;
      emit(
        state.copyWith(portions: [...state.portions]..removeAt(event.index)),
      );
    });
    on<SubmitQuizPlan>((event, emit) async {
      final pending = event.pending;
      final portions = [...state.portions, ?pending];
      if (state.isSubmitting ||
          state.created != null ||
          event.name.trim().isEmpty ||
          portions.isEmpty) {
        return;
      }
      emit(state.copyWith(isSubmitting: true));
      final result = await _createPlan(
        QuizPlanDraft(
          name: event.name.trim(),
          scheduledAt: event.scheduledAt,
          portions: portions,
        ),
      );
      if (emit.isDone) return;
      result.fold(
        (failure) => emit(
          state.copyWith(
            isSubmitting: false,
            submitFailure: failure,
            submitSerial: state.submitSerial + 1,
          ),
        ),
        (plan) => emit(state.copyWith(isSubmitting: false, created: plan)),
      );
    });
  }

  final GetQuizCategories _getCategories;
  final CreateQuizPlan _createPlan;
}
