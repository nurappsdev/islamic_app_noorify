import 'package:flutter/material.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/features/hadith/data/hadith_intro_store.dart';
import 'package:islami_app_noorify/features/hadith/presentation/screens/hadith_intro_screen.dart';
import 'package:islami_app_noorify/features/hadith/presentation/screens/hadith_library_screen.dart';

/// Where the Hadith card on the Home screen leads.
///
/// The first time Hadith is opened it shows [HadithIntroScreen] (the hadith
/// and "Let's Get Start"); every time after that it goes straight to
/// [HadithLibraryScreen]. The intro counts as seen as soon as it is shown, so
/// it never comes back — even if the user leaves without pressing its button.
class HadithEntryScreen extends StatefulWidget {
  const HadithEntryScreen({
    super.key,
    this.store = const HadithIntroStore(),
    this.introBuilder,
    this.libraryBuilder,
  });

  final HadithIntroStore store;

  /// The two destinations; the real screens unless a test supplies its own.
  final WidgetBuilder? introBuilder;
  final WidgetBuilder? libraryBuilder;

  @override
  State<HadithEntryScreen> createState() => _HadithEntryScreenState();
}

class _HadithEntryScreenState extends State<HadithEntryScreen> {
  /// Decided once per opening, not on every rebuild.
  late final Future<bool> _showIntro = _decide();

  Future<bool> _decide() async {
    try {
      return await widget.store.takeFirstVisit();
    } catch (_) {
      // If the flag can't be read or saved, don't get in the user's way: go to
      // the library rather than risk showing the intro every time.
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _showIntro,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // A blank page for the instant the flag is being read.
          return Scaffold(backgroundColor: context.pageColor(Colors.white));
        }
        return snapshot.requireData
            ? (widget.introBuilder ?? (_) => const HadithIntroScreen())(context)
            : (widget.libraryBuilder ?? (_) => const HadithLibraryScreen())(
                context,
              );
      },
    );
  }
}
