import 'package:islami_app_noorify/features/profile/data/datasources/family_remote_data_source.dart';
import 'package:islami_app_noorify/features/profile/data/repositories/family_repository_impl.dart';
import 'package:islami_app_noorify/features/profile/domain/entities/family_member_entity.dart';
import 'package:islami_app_noorify/features/profile/domain/repositories/family_repository.dart';
import 'package:islami_app_noorify/features/profile/domain/usecases/get_family_members.dart';

/// Fetches the signed-in user's family members (`GET /user/family`) for
/// screens to render, the same way [ProfileService] fetches the profile.
class FamilyService {
  FamilyService._();

  static final FamilyService instance = FamilyService._();

  final FamilyRepository _repository = FamilyRepositoryImpl(
    FamilyRemoteDataSourceImpl(),
  );
  late final GetFamilyMembers _getFamilyMembers = GetFamilyMembers(_repository);

  /// Fetches the family members list; returns an empty list on failure so
  /// callers can render without special-casing errors.
  Future<List<FamilyMemberEntity>> fetchFamilyMembers() async {
    final result = await _getFamilyMembers();
    return result.fold((_) => const [], (members) => members);
  }
}
