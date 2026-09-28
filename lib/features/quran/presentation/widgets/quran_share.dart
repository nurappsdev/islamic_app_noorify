import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/quran_ayah.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_preference.dart';

String quranShareText(
  QuranAyah ayah, {
  required int translation,
  String surahName = '',
}) {
  final translated = ayah.translations[translation];
  // The text goes to other apps, so it is written in the selected language.
  final text = AppText.forLanguage(LanguagePreference.current);
  return [
    ayah.textArabic,
    if (translated != null) translated.text,
    '${text.quranAyahTitle.fill({'key': ayah.verseKey})}${surahName.isEmpty ? '' : ' — $surahName'}',
    if (translated != null)
      text.quranShareTranslation.fill({'name': translated.name}),
  ].join('\n\n');
}

Future<void> shareQuranAyah(
  BuildContext context,
  QuranAyah ayah, {
  required int translation,
  String surahName = '',
  bool copy = false,
}) async {
  final text = quranShareText(
    ayah,
    translation: translation,
    surahName: surahName,
  );
  try {
    if (copy) {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppText.readOf(context).quranAyahCopied)),
        );
      }
    } else {
      final box = context.findRenderObject();
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: 'Quran ${ayah.verseKey}',
          sharePositionOrigin: box is RenderBox
              ? box.localToGlobal(Offset.zero) & box.size
              : null,
        ),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppText.readOf(context).quranShareFailed)),
      );
    }
  }
}
