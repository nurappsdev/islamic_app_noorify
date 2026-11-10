import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/widgets/amol_dashboard_period.dart';

void main() {
  test('daily and weekly chart order includes Zikr and Dua', () {
    expect(
      kAmolPillarOrder,
      containsAllInOrder(['quiz', 'tasbih', 'dua', 'nafl_and_more']),
    );
  });
}
