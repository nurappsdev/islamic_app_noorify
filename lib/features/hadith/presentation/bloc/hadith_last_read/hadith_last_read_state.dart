import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_last_read.dart';

enum HadithLastReadStatus { initial, loading, success, failure }

class HadithLastReadState {
  const HadithLastReadState({
    this.status = HadithLastReadStatus.initial,
    this.lastRead,
    this.failure,
  });

  final HadithLastReadStatus status;

  /// Null while loading, on failure, or when the user has not read anything.
  final HadithLastRead? lastRead;
  final Failure? failure;

  bool get isLoading =>
      status == HadithLastReadStatus.initial ||
      status == HadithLastReadStatus.loading;
}
