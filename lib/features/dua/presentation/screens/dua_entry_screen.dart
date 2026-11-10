import 'package:flutter/material.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/features/dua/data/dua_intro_store.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/screens/dua_dashboard_screen.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/screens/dua_intro_screen.dart';

/// The route opened from the Home Dua tile. It shows the welcome screen only
/// on the first visit; every later visit goes directly to the Dua dashboard.
class DuaEntryScreen extends StatefulWidget {
  const DuaEntryScreen({super.key, this.store = const DuaIntroStore()});

  final DuaIntroStore store;

  @override
  State<DuaEntryScreen> createState() => _DuaEntryScreenState();
}

class _DuaEntryScreenState extends State<DuaEntryScreen> {
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
            ? const DuaIntroScreen()
            : const DuaDashboardScreen();
      },
    );
  }
}
