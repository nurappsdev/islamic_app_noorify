import 'package:flutter/material.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/features/quran/data/quran_intro_store.dart';
import 'package:islami_app_noorify/features/quran/presentation/screens/quran_screen.dart';

/// Where the Quran card on the Home screen leads.
///
/// The first time Quran is opened it shows the [QuranScreen] intro; every time
/// after that it goes straight to the Quran home (the surah list).
class QuranEntryScreen extends StatefulWidget {
  const QuranEntryScreen({
    super.key,
    required this.surahListBuilder,
    this.store = const QuranIntroStore(),
  });

  final WidgetBuilder surahListBuilder;
  final QuranIntroStore store;

  @override
  State<QuranEntryScreen> createState() => _QuranEntryScreenState();
}

class _QuranEntryScreenState extends State<QuranEntryScreen> {
  late final Future<bool> _showIntro = _decide();

  Future<bool> _decide() async {
    try {
      return await widget.store.takeFirstVisit();
    } catch (_) {
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
            ? const QuranScreen()
            : widget.surahListBuilder(context);
      },
    );
  }
}
