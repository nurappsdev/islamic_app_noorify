import 'package:flutter/foundation.dart';

import 'package:tuhfatul_muslim/core/storage/hive_service.dart';
import 'package:tuhfatul_muslim/features/zikr/data/zikr_plan_model.dart';

/// Hive-backed store for the Zikr planner (My Plans / Search / Completed
/// Plans).
///
/// A singleton [ValueNotifier] — the same pattern the Home Screen's Zikr
/// stores use: every listener shares one in-memory copy and rebuilds
/// immediately on every create / count / completion. [HiveService.zikrPlanner]
/// is the single source of truth, so plans and their progress survive an app
/// restart without any backend call.
class ZikrPlannerStore extends ValueNotifier<List<ZikrPlanModel>> {
  ZikrPlannerStore._() : super(_readAll());

  static final instance = ZikrPlannerStore._();

  static List<ZikrPlanModel> _readAll() {
    final box = HiveService.zikrPlanner;
    final items = [
      for (final key in box.keys)
        ZikrPlanModel.fromMap(box.get(key) as Map<dynamic, dynamic>),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(items);
  }

  List<ZikrPlanModel> get activePlans => [
    for (final plan in value)
      if (!plan.completed) plan,
  ];

  List<ZikrPlanModel> get completedPlans => [
    for (final plan in value)
      if (plan.completed) plan,
  ];

  ZikrPlanModel? byId(String id) {
    for (final plan in value) {
      if (plan.id == id) return plan;
    }
    return null;
  }

  int countOf(String planId, int itemIndex) {
    final plan = byId(planId);
    if (plan == null || itemIndex >= plan.items.length) return 0;
    return plan.items[itemIndex].currentCount;
  }

  /// Creates a new plan and persists it immediately.
  ZikrPlanModel create({
    required String name,
    required int durationDays,
    required List<PlanZikrItem> items,
  }) {
    final plan = ZikrPlanModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      durationDays: durationDays < 1 ? 1 : durationDays,
      items: items,
      createdAt: DateTime.now(),
    );
    HiveService.zikrPlanner.put(plan.id, plan.toMap());
    value = _readAll();
    return plan;
  }

  /// Taps the zikr at [itemIndex] in [planId] once, clamped at its target.
  /// Marks the plan completed once every item has reached its target.
  void incrementItem(String planId, int itemIndex) {
    final plan = byId(planId);
    if (plan == null || itemIndex >= plan.items.length) return;
    final item = plan.items[itemIndex];
    if (item.currentCount >= item.target) return;

    final items = [...plan.items];
    items[itemIndex] = item.copyWith(currentCount: item.currentCount + 1);
    final fullyDone = items.isNotEmpty && items.every((i) => i.isDone);
    final next = plan.copyWith(
      items: items,
      completed: fullyDone,
      completedAt: fullyDone ? DateTime.now() : plan.completedAt,
    );
    HiveService.zikrPlanner.put(planId, next.toMap());
    value = _readAll();
  }

  /// Resets the zikr at [itemIndex] in [planId] back to 0, and un-completes
  /// the plan if it had reached 100%.
  void resetItem(String planId, int itemIndex) {
    final plan = byId(planId);
    if (plan == null || itemIndex >= plan.items.length) return;

    final items = [...plan.items];
    items[itemIndex] = items[itemIndex].copyWith(currentCount: 0);
    final next = plan.copyWith(items: items, completed: false);
    HiveService.zikrPlanner.put(planId, next.toMap());
    value = _readAll();
  }
}
