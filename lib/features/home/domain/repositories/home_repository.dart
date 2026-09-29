import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/home/domain/entities/home_dashboard.dart';

/// Contract for reading the Home screen's dashboard data.
abstract interface class HomeRepository {
  /// Fetches `GET /home/dashboard`. Returns [Right] with the [HomeDashboard],
  /// or [Left] with a typed [Failure].
  Future<Either<Failure, HomeDashboard>> getDashboard();
}
