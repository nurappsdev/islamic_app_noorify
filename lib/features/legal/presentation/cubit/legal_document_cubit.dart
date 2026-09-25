import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:islami_app_noorify/features/legal/domain/entities/legal_document.dart';
import 'package:islami_app_noorify/features/legal/domain/usecases/get_legal_document.dart';

enum LegalDocumentStatus { loading, success, failure }

class LegalDocumentState {
  const LegalDocumentState({
    this.status = LegalDocumentStatus.loading,
    this.document,
    this.errorMessage,
  });

  final LegalDocumentStatus status;
  final LegalDocument? document;
  final String? errorMessage;
}

class LegalDocumentCubit extends Cubit<LegalDocumentState> {
  LegalDocumentCubit(this._getDocument, this._type)
    : super(const LegalDocumentState());

  final GetLegalDocument _getDocument;
  final LegalDocumentType _type;

  Future<void> load() async {
    emit(const LegalDocumentState());
    final result = await _getDocument(_type);
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => LegalDocumentState(
          status: LegalDocumentStatus.failure,
          errorMessage: failure.message,
        ),
        (document) => LegalDocumentState(
          status: LegalDocumentStatus.success,
          document: document,
        ),
      ),
    );
  }
}
