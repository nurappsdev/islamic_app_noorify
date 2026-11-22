import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/core/storage/hive_service.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/entities/hadith_last_read.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/repositories/hadith_library_repository.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/usecases/get_hadith_last_read.dart';
import 'package:tuhfatul_muslim/features/hadith/presentation/bloc/hadith_last_read/hadith_last_read_bloc.dart';

/// Never answers: a guest must not get as far as asking.
class _Repository implements HadithLibraryRepository {
  @override
  Future<Either<Failure, HadithLastRead?>> getLastRead() async {
    fail('a guest should not call the last-read API');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  late Directory dir;

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('hadith_refresh_test');
    Hive.init(dir.path);
    // Opened but empty: no token, so the app is in guest mode.
    await Hive.openBox<dynamic>(HiveService.authBox);
  });

  tearDownAll(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  // The library's pull-to-refresh waits for this bloc to stop loading, and
  // `initial` counts as loading. Before this, a guest's refresh left the
  // bloc on `initial` for good and the spinner never stopped.
  test('a guest load settles on a state that is not loading', () async {
    final bloc = HadithLastReadBloc(GetHadithLastRead(_Repository()));
    expect(bloc.state.isLoading, isTrue, reason: 'initial counts as loading');

    final settled = bloc.stream.firstWhere((state) => !state.isLoading);
    bloc.add(const LoadHadithLastRead());

    final state = await settled.timeout(const Duration(seconds: 5));
    expect(state.isLoading, isFalse);
    expect(state.lastRead, isNull);

    await bloc.close();
  });
}
