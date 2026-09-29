import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/legal/domain/entities/legal_document.dart';

/// Contract for reading the app's legal pages.
abstract interface class LegalRepository {
  Future<Either<Failure, LegalDocument>> getDocument(LegalDocumentType type);
}
