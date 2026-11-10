/// One entry from the signed-in user's family list, as returned by
/// `GET /user/family`.
class FamilyMemberEntity {
  const FamilyMemberEntity({
    required this.id,
    required this.familyMemberUserId,
    required this.relationship,
    required this.memberName,
    this.memberAvatarUrl,
    this.memberTotalPoints = 0,
    this.globalRank = 0,
    this.gender,
    this.addedVia,
  });

  final String id;
  final String familyMemberUserId;
  final String relationship;
  final String memberName;
  final String? memberAvatarUrl;
  final int memberTotalPoints;
  final int globalRank;
  final String? gender;
  final String? addedVia;
}
