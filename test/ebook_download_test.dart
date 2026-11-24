import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/hadith/data/ebook_downloader.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/entities/ebook.dart';
import 'package:tuhfatul_muslim/features/hadith/presentation/bloc/ebook_download/ebook_download_bloc.dart';

Ebook _ebook(String pdfFileUrl, {String id = 'book-1'}) => Ebook(
  id: id,
  title: 'A book',
  author: 'An author',
  category: '',
  coverImageUrl: '',
  pdfFileUrl: pdfFileUrl,
  totalPages: 10,
  description: '',
  language: 'English',
  publisher: '',
  reference: '',
  displayOrder: 0,
  isActive: true,
);

/// Writes [body] to the requested path instead of going to the network.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.body);

  final List<int> body;
  final requested = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requested.add(options.uri.toString());
    return ResponseBody.fromBytes(
      body,
      200,
      headers: {
        Headers.contentLengthHeader: [body.length.toString()],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

EbookDownloader _downloader(Directory dir, List<int> body) {
  final dio = Dio()..httpClientAdapter = _FakeAdapter(body);
  return EbookDownloader(dio: dio, documentsDirectory: () async => dir);
}

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('ebook_download_test');
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  group('Ebook.hasReadablePdf', () {
    test('accepts an absolute http(s) URL', () {
      expect(_ebook('https://minio.example/x/book.pdf').hasReadablePdf, isTrue);
      expect(_ebook('http://minio.example/x/book.pdf').hasReadablePdf, isTrue);
      expect(
        _ebook('  https://minio.example/x/book.pdf  ').hasReadablePdf,
        isTrue,
        reason: 'surrounding whitespace is not a broken URL',
      );
    });

    // The record that broke the shelf: the dashboard stored the browser's
    // in-memory handle, so the PDF was never uploaded anywhere.
    test('rejects a browser blob: URL', () {
      expect(
        _ebook(
          'blob:https://dashboard.example/5b30b266-59b0-4901-99f4-f5124af41b20',
        ).hasReadablePdf,
        isFalse,
      );
    });

    test('rejects an empty, relative or host-less URL', () {
      expect(_ebook('').hasReadablePdf, isFalse);
      expect(_ebook('   ').hasReadablePdf, isFalse);
      expect(_ebook('Ebooks/2026/09/19/book.pdf').hasReadablePdf, isFalse);
      expect(_ebook('file:///data/book.pdf').hasReadablePdf, isFalse);
      expect(_ebook('https:///book.pdf').hasReadablePdf, isFalse);
    });
  });

  group('EbookDownloader.download', () {
    test('saves a real PDF and reports it as downloaded', () async {
      final pdf = <int>[...'%PDF-1.7\n'.codeUnits, ...List.filled(64, 0x20)];
      final downloader = _downloader(dir, pdf);
      final ebook = _ebook('https://minio.example/x/book.pdf');

      final file = await downloader.download(ebook);

      expect(await file.exists(), isTrue);
      expect(file.path, endsWith('/ebooks/book-1.pdf'));
      expect(await file.length(), pdf.length);
      expect((await downloader.existing(ebook))?.path, file.path);
    });

    test('a blob: URL fails before any request is made', () async {
      final adapter = _FakeAdapter('%PDF-1.7'.codeUnits);
      final downloader = EbookDownloader(
        dio: Dio()..httpClientAdapter = adapter,
        documentsDirectory: () async => dir,
      );
      final ebook = _ebook('blob:https://dashboard.example/5b30b266');

      await expectLater(
        downloader.download(ebook),
        throwsA(isA<FormatException>()),
      );
      expect(adapter.requested, isEmpty, reason: 'nothing to fetch');
      expect(await downloader.existing(ebook), isNull);
    });

    // A storage host answering 200 with its SPA shell must not become the
    // book: that used to be saved as a .pdf the reader could never open.
    test('an HTML body answered with 200 is not kept', () async {
      final downloader = _downloader(
        dir,
        '<!doctype html><html><body>Dashboard</body></html>'.codeUnits,
      );
      final ebook = _ebook('https://dashboard.example/5b30b266');

      await expectLater(
        downloader.download(ebook),
        throwsA(isA<FormatException>()),
      );
      expect(await downloader.existing(ebook), isNull);
      final ebooks = Directory('${dir.path}/ebooks');
      expect(
        await ebooks.exists() ? ebooks.listSync() : const <FileSystemEntity>[],
        isEmpty,
        reason: 'no file and no leftover .part',
      );
    });
  });

  group('EbookDownloader.existing', () {
    test('drops a saved file that is not a PDF', () async {
      final ebook = _ebook('https://minio.example/x/book.pdf');
      final saved = File('${dir.path}/ebooks/book-1.pdf');
      await saved.parent.create(recursive: true);
      await saved.writeAsString('<!doctype html><html>Not a book</html>');

      final downloader = _downloader(dir, const <int>[]);

      expect(await downloader.existing(ebook), isNull);
      expect(
        await saved.exists(),
        isFalse,
        reason: 'a stale non-PDF would read as "Downloaded" for good',
      );
    });

    test('ignores an empty file', () async {
      final ebook = _ebook('https://minio.example/x/book.pdf');
      final saved = File('${dir.path}/ebooks/book-1.pdf');
      await saved.parent.create(recursive: true);
      await saved.create();

      expect(await _downloader(dir, const <int>[]).existing(ebook), isNull);
    });
  });

  group('EbookDownloadBloc', () {
    test('a blob: URL settles on failed, not downloaded', () async {
      final ebook = _ebook('blob:https://dashboard.example/5b30b266');
      final bloc = EbookDownloadBloc(
        ebook,
        _downloader(dir, '%PDF-1.7'.codeUnits),
      );

      final settled = bloc.stream.firstWhere(
        (state) => state.status == EbookDownloadStatus.idle,
      );
      bloc.add(const CheckEbookDownload());
      await settled.timeout(const Duration(seconds: 5));

      final failed = bloc.stream.firstWhere(
        (state) => state.status == EbookDownloadStatus.failed,
      );
      bloc.add(const StartEbookDownload());
      final state = await failed.timeout(const Duration(seconds: 5));

      expect(state.filePath, isNull);
      await bloc.close();
    });

    test('a real PDF settles on downloaded with a path', () async {
      final ebook = _ebook('https://minio.example/x/book.pdf');
      final bloc = EbookDownloadBloc(
        ebook,
        _downloader(dir, '%PDF-1.7\n'.codeUnits),
      );

      final done = bloc.stream.firstWhere(
        (state) => state.status == EbookDownloadStatus.downloaded,
      );
      bloc.add(const StartEbookDownload());
      final state = await done.timeout(const Duration(seconds: 5));

      expect(state.filePath, endsWith('/ebooks/book-1.pdf'));
      expect(await File(state.filePath!).exists(), isTrue);
      await bloc.close();
    });
  });
}
