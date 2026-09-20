import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/ebook.dart';

enum EbooksStatus { initial, loading, success, failure }

class EbooksState {
  const EbooksState({
    this.status = EbooksStatus.initial,
    this.ebooks = const [],
    this.failure,
  });

  final EbooksStatus status;
  final List<Ebook> ebooks;
  final Failure? failure;

  bool get isLoading =>
      status == EbooksStatus.initial || status == EbooksStatus.loading;
}
