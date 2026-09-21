import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/data/models/hadith_read_record_model.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_read_record.dart';
import 'package:islami_app_noorify/features/hadith/domain/repositories/hadith_library_repository.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_read_records.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_read_records/hadith_read_records_bloc.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_read_record_row.dart';

/// Serves [total] records, [limit] per page, and remembers each request.
class _FakeRepository implements HadithLibraryRepository {
  _FakeRepository({this.total = 25});

  final int total;
  final requests = <({int page, int limit})>[];

  @override
  Future<Either<Failure, HadithReadRecordPage>> getReadRecords({
    required int page,
    required int limit,
  }) async {
    requests.add((page: page, limit: limit));
    final first = (page - 1) * limit;
    final count = (total - first).clamp(0, limit);
    return Right(
      HadithReadRecordPage(
        records: [
          for (var i = 0; i < count; i++)
            HadithReadRecord(
              id: 'r${first + i}',
              hadithNumber: first + i,
              subCategoryName: 'n',
              subCategoryNameBangla: 'bn',
              subCategoryNameEnglish: 'en',
              lastReadAt: null,
            ),
        ],
        page: page,
        totalPage: (total / limit).ceil(),
        total: total,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('HadithReadRecordModel', () {
    // Trimmed from a real /hadiths/reading/recent response.
    final json = {
      '_id': '6ab0abbfac63e38856607949',
      'hadithId': {
        '_id': '6aae3488ac63e388565ffe63',
        'hadithNumber': 22,
        'sourceEnglish': 'Riyad as-Salihin',
      },
      'subCategoryId': {
        '_id': '6aae3487ac63e388565ffce1',
        'name': 'তওবার বিবরণ',
        'nameBangla': 'তওবার বিবরণ',
        'nameEnglish': 'Repentance',
      },
      'lastReadAt': '2026-09-21T03:59:59.300Z',
    };

    test('reads the sub-category name, hadith number and time', () {
      final r = HadithReadRecordModel.fromJson(json);
      expect(r.id, '6ab0abbfac63e38856607949');
      expect(r.hadithNumber, 22);
      expect(r.subCategoryNameBangla, 'তওবার বিবরণ');
      expect(r.subCategoryNameEnglish, 'Repentance');
      // The same instant, whatever the device's time zone.
      expect(r.lastReadAt!.toUtc(), DateTime.utc(2026, 9, 21, 3, 59, 59, 300));
    });

    test('the title follows the language, falling back when one is empty', () {
      final r = HadithReadRecordModel.fromJson(json);
      expect(r.title(bangla: true), 'তওবার বিবরণ');
      expect(r.title(bangla: false), 'Repentance');

      final noEnglish = HadithReadRecordModel.fromJson({
        'subCategoryId': {'name': 'তওবার', 'nameBangla': 'তওবার'},
      });
      expect(noEnglish.title(bangla: false), 'তওবার');
      expect(HadithReadRecordModel.fromJson(const {}).title(bangla: true), '');
    });

    test('tolerates a missing or invalid lastReadAt', () {
      expect(HadithReadRecordModel.fromJson(const {}).lastReadAt, isNull);
      expect(
        HadithReadRecordModel.fromJson({'lastReadAt': 'nope'}).lastReadAt,
        isNull,
      );
    });

    test('the page reads its meta', () {
      final p = HadithReadRecordPageModel.fromJson(
        [json],
        {'page': 1, 'limit': 10, 'total': 20, 'totalPage': 2},
      );
      expect(p.records, hasLength(1));
      expect(p.page, 1);
      expect(p.total, 20);
      expect(p.hasMore, isTrue);
      // No meta: what we got is the only page.
      expect(HadithReadRecordPageModel.fromJson([json], {}).hasMore, isFalse);
    });
  });

  group('formatHadithReadTime', () {
    test('matches the design, e.g. "17 Aug  At 5 : 35 PM"', () {
      expect(
        formatHadithReadTime(DateTime(2026, 8, 17, 17, 35)),
        '17 Aug  At 5 : 35 PM',
      );
      expect(
        formatHadithReadTime(DateTime(2026, 9, 21, 3, 5)),
        '21 Sep  At 3 : 05 AM',
      );
    });

    test('midnight is 12 AM and noon is 12 PM', () {
      expect(
        formatHadithReadTime(DateTime(2026, 1, 2, 0, 0)),
        '2 Jan  At 12 : 00 AM',
      );
      expect(
        formatHadithReadTime(DateTime(2026, 1, 2, 12, 30)),
        '2 Jan  At 12 : 30 PM',
      );
    });
  });

  group('HadithReadRecordsBloc', () {
    test('the dashboard preview asks for one page of 3', () async {
      final repo = _FakeRepository();
      final bloc = HadithReadRecordsBloc(
        GetHadithReadRecords(repo),
        pageSize: 3,
      );
      addTearDown(bloc.close);

      bloc.add(const LoadHadithReadRecords());
      final state = await bloc.stream.firstWhere((s) => !s.isLoading);

      expect(repo.requests, [(page: 1, limit: 3)]);
      expect(state.records, hasLength(3));
    });

    test(
      'the full list loads 10 per page and pages through to the end',
      () async {
        final repo = _FakeRepository(total: 25);
        final bloc = HadithReadRecordsBloc(
          GetHadithReadRecords(repo),
          pageSize: 10,
        );
        addTearDown(bloc.close);

        bloc.add(const LoadHadithReadRecords());
        var state = await bloc.stream.firstWhere((s) => !s.isLoading);
        expect(state.records, hasLength(10));
        expect(state.hasMore, isTrue);

        bloc.add(const LoadMoreHadithReadRecords());
        state = await bloc.stream.firstWhere(
          (s) => !s.isLoadingMore && s.records.length == 20,
        );
        expect(state.page, 2);

        bloc.add(const LoadMoreHadithReadRecords());
        state = await bloc.stream.firstWhere(
          (s) => !s.isLoadingMore && s.records.length == 25,
        );
        expect(state.page, 3);
        expect(state.hasMore, isFalse);
        expect(repo.requests.map((r) => r.page), [1, 2, 3]);

        // Nothing left: no further request.
        bloc.add(const LoadMoreHadithReadRecords());
        await Future<void>.delayed(Duration.zero);
        expect(repo.requests, hasLength(3));
      },
    );
  });
}
