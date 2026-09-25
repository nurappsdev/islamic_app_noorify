import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/legal/domain/entities/legal_document.dart';
import 'package:islami_app_noorify/features/legal/domain/repositories/legal_repository.dart';

/// Fetches the Terms of Service (`GET /settings/terms-of-service`) or the
/// Privacy Policy (`GET /settings/privacy-policy`).
class GetLegalDocument {
  const GetLegalDocument(this._repository);

  final LegalRepository _repository;

  Future<Either<Failure, LegalDocument>> call(LegalDocumentType type) =>
      _repository.getDocument(type);
}
