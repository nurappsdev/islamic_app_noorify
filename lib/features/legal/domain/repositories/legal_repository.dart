import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/legal/domain/entities/legal_document.dart';

/// Contract for reading the app's legal pages.
abstract interface class LegalRepository {
  Future<Either<Failure, LegalDocument>> getDocument(LegalDocumentType type);
}
