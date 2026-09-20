import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'package:islami_app_noorify/features/hadith/domain/entities/ebook.dart';

/// Saves e-book PDFs on the device (in the app's documents folder) so they can
/// be opened offline. Uses its own [Dio] rather than the API client: the file
/// lives on a storage host, so the API base URL and any auth headers must not
/// apply.
class EbookDownloader {
  EbookDownloader({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<File> _fileFor(Ebook ebook) async {
    final dir = await getApplicationDocumentsDirectory();
    final name = (ebook.id.isNotEmpty ? ebook.id : ebook.title).replaceAll(
      RegExp(r'[^A-Za-z0-9_-]'),
      '_',
    );
    return File('${dir.path}/ebooks/$name.pdf');
  }

  /// The saved copy of [ebook], or null when it hasn't been downloaded.
  Future<File?> existing(Ebook ebook) async {
    final file = await _fileFor(ebook);
    return await file.exists() && await file.length() > 0 ? file : null;
  }

  /// Downloads [ebook]'s PDF. [onProgress] gets 0..1, or null while the total
  /// size is unknown. Throws on any failure; a partial file is never left
  /// behind as the saved copy.
  Future<File> download(
    Ebook ebook, {
    void Function(double? progress)? onProgress,
  }) async {
    if (ebook.pdfFileUrl.isEmpty) {
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
      return await partial.rename(target.path);
    } catch (_) {
      if (await partial.exists()) await partial.delete();
      rethrow;
    }
  }
}
