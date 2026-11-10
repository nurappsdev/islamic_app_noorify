import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/home/domain/entities/home_dashboard.dart';
import 'package:tuhfatul_muslim/features/home/domain/repositories/home_repository.dart';

/// Fetches the Home screen's dashboard data (`GET /home/dashboard`).
class GetHomeDashboard {
  const GetHomeDashboard(this._repository);

  final HomeRepository _repository;

  Future<Either<Failure, HomeDashboard>> call() => _repository.getDashboard();
}
