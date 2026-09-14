import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/profile/domain/entities/family_member_entity.dart';
import 'package:islami_app_noorify/features/profile/domain/repositories/family_repository.dart';

/// Fetches the signed-in user's family members from `GET /user/family`.
class GetFamilyMembers {
  const GetFamilyMembers(this._repository);

  final FamilyRepository _repository;

  Future<Either<Failure, List<FamilyMemberEntity>>> call() =>
      _repository.getFamilyMembers();
}
