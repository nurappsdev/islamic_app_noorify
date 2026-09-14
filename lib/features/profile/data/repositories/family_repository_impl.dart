import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/profile/data/datasources/family_remote_data_source.dart';
import 'package:islami_app_noorify/features/profile/domain/entities/family_member_entity.dart';
import 'package:islami_app_noorify/features/profile/domain/repositories/family_repository.dart';

class FamilyRepositoryImpl implements FamilyRepository {
  FamilyRepositoryImpl(this._remote);

  final FamilyRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<FamilyMemberEntity>>> getFamilyMembers() async {
    try {
      final members = await _remote.getFamilyMembers();
      return Right(members);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ParsingException catch (e) {
      return Left(ParsingFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
