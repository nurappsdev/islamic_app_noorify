import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'package:tuhfatul_muslim/features/hadith/domain/entities/ebook.dart';

/// Saves e-book PDFs on the device (in the app's documents folder) so they can
/// be opened offline. Uses its own [Dio] rather than the API client: the file
/// lives on a storage host, so the API base URL and any auth headers must not
/// apply.
class EbookDownloader {
  EbookDownloader({Dio? dio, Future<Directory> Function()? documentsDirectory})
    : _dio = dio ?? Dio(),
      _documentsDirectory =
          documentsDirectory ?? getApplicationDocumentsDirectory;

  final Dio _dio;

  /// Where the downloads go. Injectable so a test can use a temp folder
  /// instead of the platform channel.
  final Future<Directory> Function() _documentsDirectory;

  Future<File> _fileFor(Ebook ebook) async {
    final dir = await _documentsDirectory();
    final name = (ebook.id.isNotEmpty ? ebook.id : ebook.title).replaceAll(
      RegExp(r'[^A-Za-z0-9_-]'),
      '_',
    );
    return File('${dir.path}/ebooks/$name.pdf');
  }

  /// The saved copy of [ebook], or null when it hasn't been downloaded.
  ///
  /// A saved file that is not a PDF (an error page or a login redirect that
  /// answered 200 and got written out) is deleted rather than reported: left
  /// in place it would read as "Downloaded" for good while the reader kept
  /// failing, with no way to download the book again.
  Future<File?> existing(Ebook ebook) async {
    final file = await _fileFor(ebook);
    if (!await file.exists() || await file.length() == 0) return null;
    if (await _looksLikePdf(file)) return file;
    try {
      await file.delete();
    } catch (_) {
      // Keeping the stale file is no worse than failing here.
    }
    return null;
  }

  /// Downloads [ebook]'s PDF. [onProgress] gets 0..1, or null while the total
  /// size is unknown. Throws on any failure; a partial file is never left
  /// behind as the saved copy.
  Future<File> download(
    Ebook ebook, {
    void Function(double? progress)? onProgress,
  }) async {
    if (!ebook.hasReadablePdf) {
      throw const FormatException('The e-book has no PDF file.');
    }
    final target = await _fileFor(ebook);
    await target.parent.create(recursive: true);
    final partial = File('${target.path}.part');
    try {
      await _dio.download(
        ebook.pdfFileUrl,
        partial.path,
        onReceiveProgress: (received, total) =>
            onProgress?.call(total > 0 ? received / total : null),
      );
      // A storage host can answer 200 with an error page or a sign-in
      // redirect. Saving that as the book would show "Downloaded" with a
      // reader that never opens, so check the content before keeping it.
      if (!await _looksLikePdf(partial)) {
        throw const FormatException('The e-book has no PDF file.');
      }
      return await partial.rename(target.path);
    } catch (_) {
      if (await partial.exists()) await partial.delete();
      rethrow;
    }
  }

  /// Whether [file] starts with the PDF marker. The spec allows leading bytes
  /// before `%PDF-`, so the head of the file is searched rather than only its
  /// first five bytes.
  static Future<bool> _looksLikePdf(File file) async {
    try {
      final head = await file
          .openRead(0, 1024)
          .fold<List<int>>(<int>[], (bytes, chunk) => bytes..addAll(chunk));
      return String.fromCharCodes(head).contains('%PDF-');
    } catch (_) {
      return false;
    }
  }
}
