import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/home/domain/entities/home_dashboard.dart';
import 'package:tuhfatul_muslim/features/home/domain/entities/user_summary.dart';
import 'package:tuhfatul_muslim/features/home/domain/repositories/home_repository.dart';
import 'package:tuhfatul_muslim/features/home/domain/usecases/get_home_dashboard.dart';
import 'package:tuhfatul_muslim/features/home/presentation/bloc/home_dashboard/home_dashboard_bloc.dart';

void main() {
  test('coalesces overlapping dashboard loads into one API request', () async {
    final repository = _DelayedHomeRepository();
    final bloc = HomeDashboardBloc(GetHomeDashboard(repository));
    addTearDown(bloc.close);

    bloc
      ..add(const LoadHomeDashboard())
      ..add(const LoadHomeDashboard(silent: true))
      ..add(const LoadHomeDashboard());
    await Future<void>.delayed(Duration.zero);

    expect(repository.callCount, 1);

    repository.complete();
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.hasData, isTrue);
  });
}

class _DelayedHomeRepository implements HomeRepository {
  final Completer<Either<Failure, HomeDashboard>> _response = Completer();
  int callCount = 0;

  @override
  Future<Either<Failure, HomeDashboard>> getDashboard() {
    callCount++;
    return _response.future;
  }

  void complete() {
    _response.complete(
      const Right(
        HomeDashboard(
          userSummary: UserSummary(
            fullName: 'Guest User',
            greetingText: 'Assalamu-Alaikum',
          ),
          topHighlightCards: [],
          pillarCards: [],
        ),
      ),
    );
  }
}
