import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/asma_husna/domain/entities/asma_name_detail.dart';

enum AsmaNameDetailStatus { loading, success, failure }

class AsmaNameDetailState {
  const AsmaNameDetailState({
    this.status = AsmaNameDetailStatus.loading,
    this.detail,
    this.failure,
  });

  final AsmaNameDetailStatus status;
  final AsmaNameDetail? detail;
  final Failure? failure;

  AsmaNameDetailState copyWith({
    AsmaNameDetailStatus? status,
    AsmaNameDetail? detail,
    Failure? failure,
  }) {
    return AsmaNameDetailState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      failure: failure ?? this.failure,
    );
  }
}
