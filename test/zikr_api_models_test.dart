import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/zikr/data/models/zikr_api_models.dart';

void main() {
  test('parses a profile response payload', () {
    final profile = UserTasbihProfile.fromJson({
      'lifetimeTotalCount': 176337,
      'mostPerformedZikrKey': 'subhanallah',
      'mostPerformedZikrName': 'Subhan-Allah',
      'mostPerformedCount': 42500,
      'lastZikr': {
        'zikrKey': 'subhanallah',
        'zikrName': 'Subhan-Allah',
        'nameArabic': 'سُبْحَانَ اللهِ',
        'targetCount': 33,
        'currentCount': 12,
      },
    });

    expect(profile.lifetimeTotalCount, 176337);
    expect(profile.mostPerformedZikrKey, 'subhanallah');
    expect(profile.lastZikr?.zikrName, 'Subhan-Allah');
    expect(profile.lastZikr?.currentCount, 12);
  });

  test('parses plans and their nested items', () {
    final plan = ZikrPlan.fromJson({
      '_id': '66d3a36f8a91012345678991',
      'planName': '30 Days Istighfar Challenge',
      'completionDays': 30,
      'totalTargetCount': 5000,
      'currentCount': 1283,
      'status': 'active',
      'items': [
        {
          'zikrKey': 'astaghfirullah',
          'zikrName': 'Astaghfirullah',
          'targetCount': 5000,
        },
      ],
    });

    expect(plan.id, '66d3a36f8a91012345678991');
    expect(plan.items.single.zikrKey, 'astaghfirullah');
    expect(plan.completed, isFalse);
  });
}
