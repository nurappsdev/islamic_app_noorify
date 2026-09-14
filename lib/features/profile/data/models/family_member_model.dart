import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/features/profile/domain/entities/family_member_entity.dart';

/// Data-layer representation of [FamilyMemberEntity] that knows how to read
/// the API JSON (one item of `GET /user/family`'s `data` array).
///
/// Expected API shape (one item):
/// ```json
/// {
///   "_id": "67cb250f8a91012345678901",
///   "familyMemberUserId": "66d30f1e8a91012345678901",
///   "relationship": "FATHER",
///   "memberName": "Mohammad Ali (Father)",
///   "memberAvatarUrl": "https://cdn.tuhfatulmuslim.app/avatars/01.jpg",
///   "memberTotalPoints": 1250,
///   "globalRank": 2,
///   "gender": "male",
///   "addedVia": "demo"
/// }
/// ```
class FamilyMemberModel extends FamilyMemberEntity {
  const FamilyMemberModel({
    required super.id,
    required super.familyMemberUserId,
    required super.relationship,
    required super.memberName,
    super.memberAvatarUrl,
    super.memberTotalPoints,
    super.globalRank,
    super.gender,
    super.addedVia,
  });

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id']?.toString();
    if (id == null) {
      throw ParsingException('Family member is missing "_id".');
    }
    return FamilyMemberModel(
      id: id,
      familyMemberUserId: json['familyMemberUserId']?.toString() ?? '',
      relationship: json['relationship']?.toString() ?? '',
      memberName: json['memberName']?.toString() ?? '',
      memberAvatarUrl: json['memberAvatarUrl']?.toString(),
      memberTotalPoints: (json['memberTotalPoints'] as num?)?.toInt() ?? 0,
      globalRank: (json['globalRank'] as num?)?.toInt() ?? 0,
      gender: json['gender']?.toString(),
      addedVia: json['addedVia']?.toString(),
    );
  }
}
