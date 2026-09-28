import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/quran_plan.dart';

class QuranPlanStore {
  static const _plansKey = 'quran_saved_plans_v1';

  static final List<QuranPlan> presetSearchPlans = [
    QuranPlan(
      id: 'preset_1_month',
      name: 'One month Quran',
      days: 30,
      startSurah: 1,
      startSurahName: 'Al-Fatiha',
      endSurah: 114,
      endSurahName: 'An-Nas',
      createdAt: DateTime.now(),
    ),
    QuranPlan(
      id: 'preset_2_month',
      name: 'Two month Quran',
      days: 60,
      startSurah: 1,
      startSurahName: 'Al-Fatiha',
      endSurah: 114,
      endSurahName: 'An-Nas',
      createdAt: DateTime.now(),
    ),
    QuranPlan(
      id: 'preset_3_month',
      name: 'Three month Quran',
      days: 90,
      startSurah: 1,
      startSurahName: 'Al-Fatiha',
      endSurah: 114,
      endSurahName: 'An-Nas',
      createdAt: DateTime.now(),
    ),
    QuranPlan(
      id: 'preset_juz_amma',
      name: 'Juz Amma (30th Para)',
      days: 15,
      startSurah: 78,
      startSurahName: 'An-Naba',
      endSurah: 114,
      endSurahName: 'An-Nas',
      createdAt: DateTime.now(),
    ),
    QuranPlan(
      id: 'preset_baqarah',
      name: 'Surah Al-Baqarah',
      days: 10,
      startSurah: 2,
      startSurahName: 'Al-Baqarah',
      endSurah: 2,
      endSurahName: 'Al-Baqarah',
      createdAt: DateTime.now(),
    ),
  ];

  static Future<List<QuranPlan>> loadPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_plansKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => QuranPlan.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> savePlan(QuranPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    final plans = await loadPlans();
    final index = plans.indexWhere((p) => p.id == plan.id);
    if (index >= 0) {
      plans[index] = plan;
    } else {
      plans.insert(0, plan);
    }
    await prefs.setString(
      _plansKey,
      jsonEncode(plans.map((p) => p.toJson()).toList()),
    );
  }

  static Future<void> toggleComplete(String planId) async {
    final prefs = await SharedPreferences.getInstance();
    final plans = await loadPlans();
    final index = plans.indexWhere((p) => p.id == planId);
    if (index >= 0) {
      final p = plans[index];
      plans[index] = p.copyWith(isCompleted: !p.isCompleted);
      await prefs.setString(
        _plansKey,
        jsonEncode(plans.map((e) => e.toJson()).toList()),
      );
    }
  }

  static Future<void> deletePlan(String planId) async {
    final prefs = await SharedPreferences.getInstance();
    final plans = await loadPlans();
    plans.removeWhere((p) => p.id == planId);
    await prefs.setString(
      _plansKey,
      jsonEncode(plans.map((e) => e.toJson()).toList()),
    );
  }
}
