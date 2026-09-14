import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/profile/domain/entities/family_member_entity.dart';

/// Contract for reading the signed-in user's family members.
abstract interface class FamilyRepository {
  /// Fetches the family members from `GET /user/family`. Returns [Right]
  /// with the list, or [Left] with a typed [Failure].
  Future<Either<Failure, List<FamilyMemberEntity>>> getFamilyMembers();
}
