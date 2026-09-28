import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/quran_ayah.dart';

String quranShareText(
  QuranAyah ayah, {
  required int translation,
  String surahName = '',
}) {
  final translated = ayah.translations[translation];
  return [
    ayah.textArabic,
    if (translated != null) translated.text,
    'Quran ${ayah.verseKey}${surahName.isEmpty ? '' : ' — $surahName'}',
    if (translated != null) 'Translation: ${translated.name}',
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ayah copied')));
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
        const SnackBar(
          content: Text('Unable to share this ayah. Please try again.'),
        ),
      );
    }
  }
}
