import 'package:flutter/services.dart' show rootBundle;
import 'package:xml/xml.dart';

import 'hadith_database.dart';
import 'models/hadith_book.dart';

/// Which step of the one-time book download is running.
enum HadithSetupPhase { reading, saving }

class HadithSetupProgress {
  const HadithSetupProgress(this.phase, this.done, this.total);

  final HadithSetupPhase phase;
  final int done;
  final int total;

  double? get fraction => total > 0 ? (done / total).clamp(0.0, 1.0) : null;
}

class HadithSetupException implements Exception {
  const HadithSetupException(this.message);

  final String message;

  @override
  String toString() => 'HadithSetupException: $message';
}

/// "Downloads" a hadith book onto the device: reads its bundled XML source,
/// parses every hadith and writes them into [HadithDatabase] in small batches
/// so the reader screen can show real progress. Resumable — batches commit as
/// they are written and every write replaces on a UNIQUE key.
class HadithBookDownloader {
  HadithBookDownloader({HadithDatabase? database})
    : _db = database ?? HadithDatabase();

  final HadithDatabase _db;

  static const _batchSize = 4;

  Stream<HadithSetupProgress> download(HadithBook book) async* {
    final assetPath = book.assetXmlPath;
    if (assetPath == null) {
      throw const HadithSetupException('This book is not available yet.');
    }

    yield const HadithSetupProgress(HadithSetupPhase.reading, 0, 1);

    final List<Map<String, Object?>> entries;
    try {
      final raw = await rootBundle.loadString(assetPath);
      entries = _parse(raw);
    } catch (error) {
      throw HadithSetupException('Could not read the book file. ($error)');
    }
    if (entries.isEmpty) {
      throw const HadithSetupException('The book file has no hadith.');
    }

    yield const HadithSetupProgress(HadithSetupPhase.reading, 1, 1);

    final total = entries.length;
    var done = await _db.savedEntryCount(book.slug);
    yield HadithSetupProgress(HadithSetupPhase.saving, done, total);

    for (var start = 0; start < total; start += _batchSize) {
      if (start + _batchSize <= done) continue;
      final end = start + _batchSize > total ? total : start + _batchSize;
      try {
        await _db.insertEntries(book.slug, entries.sublist(start, end));
      } catch (error) {
        throw HadithSetupException('Download interrupted. ($error)');
      }
      done = end;
      // A small pause keeps the progress bar visible for a fast local parse.
      await Future<void>.delayed(const Duration(milliseconds: 90));
      yield HadithSetupProgress(HadithSetupPhase.saving, done, total);
    }

    await _db.markBookComplete(
      slug: book.slug,
      titleEn: book.titleEn,
      titleBn: book.titleBn,
      hadithCount: total,
    );
    yield HadithSetupProgress(HadithSetupPhase.saving, total, total);
  }

  List<Map<String, Object?>> _parse(String raw) {
    final doc = XmlDocument.parse(raw);
    final rows = <Map<String, Object?>>[];
    for (final row in doc.findAllElements('row')) {
      String text(String tag) => row.getElement(tag)?.innerText.trim() ?? '';
      String? nullable(String tag) {
        final value = text(tag);
        return (value.isEmpty || value.toLowerCase() == 'null') ? null : value;
      }

      final hadithNo = int.tryParse(text('hadith_no')) ?? 0;
      if (hadithNo == 0) continue;
      rows.add({
        'hadith_no': hadithNo,
        'title_ar': nullable('title_ar'),
        'title_bn': nullable('title_bn'),
        'arabic_text': nullable('arabic_text'),
        'bangla_narrator': nullable('bangla_narrator'),
        'bangla_text': nullable('bangla_text'),
        'references_text': nullable('references_text'),
      });
    }
    rows.sort(
      (a, b) => (a['hadith_no'] as int).compareTo(b['hadith_no'] as int),
    );
    return rows;
  }
}
