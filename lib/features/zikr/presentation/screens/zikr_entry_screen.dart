import 'package:flutter/material.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/features/zikr/data/zikr_intro_store.dart';
import 'package:tuhfatul_muslim/features/zikr/presentation/screens/zikr_dashboard_screen.dart';
import 'package:tuhfatul_muslim/features/zikr/presentation/screens/zikr_intro_screen.dart';

/// The route opened from the Home Zikr tile. It shows the welcome screen only
/// on the first visit; every later visit goes directly to the Zikr dashboard.
class ZikrEntryScreen extends StatefulWidget {
  const ZikrEntryScreen({super.key, this.store = const ZikrIntroStore()});

  final ZikrIntroStore store;

  @override
  State<ZikrEntryScreen> createState() => _ZikrEntryScreenState();
}

class _ZikrEntryScreenState extends State<ZikrEntryScreen> {
  late final Future<bool> _showIntro = _decide();

  Future<bool> _decide() async {
    try {
      return await widget.store.takeFirstVisit();
    } catch (_) {
      // A storage failure must not trap the user in the onboarding screen.
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _showIntro,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(backgroundColor: context.pageColor(Colors.white));
        }
        return snapshot.requireData
            ? const ZikrIntroScreen()
            : const ZikrDashboardScreen();
      },
    );
  }
}
