import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/settings/domain/repositories/settings_support_repository.dart';

class SubmitSupportTicketParams {
  const SubmitSupportTicketParams({
    required this.reason,
    required this.description,
  });

  final String reason;
  final String description;
}

/// Opens a support ticket (`POST /support/tickets`).
class SubmitSupportTicket {
  const SubmitSupportTicket(this._repository);

  final SettingsSupportRepository _repository;

  Future<Either<Failure, String>> call(SubmitSupportTicketParams params) =>
      _repository.submitTicket(
        reason: params.reason,
        description: params.description,
      );
}
