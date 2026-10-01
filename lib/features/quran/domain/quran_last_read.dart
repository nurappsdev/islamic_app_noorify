import 'quran_reading_json.dart';
import 'quran_reading_progress.dart';

/// The most recently read ayah's stored progress (`lastRead` of
/// `GET /quran/reading/last-read` and of the dashboard).
class QuranLastReadRecord {
  const QuranLastReadRecord({
    required this.id,
    required this.userId,
    required this.ayahIndex,
    required this.surahNumber,
    required this.ayahNumber,
    required this.ayahKey,
    required this.paraNumber,
    required this.isRead,
    required this.readSeconds,
    required this.readMinutes,
    required this.sessionCount,
    required this.surahNameEnglish,
    required this.surahNameBangla,
    required this.surahNameArabic,
    this.createdAt,
    this.updatedAt,
    this.firstReadAt,
    this.lastReadAt,
    this.completedAt,
  });

  factory QuranLastReadRecord.fromJson(Map<String, dynamic> json) =>
      QuranLastReadRecord(
        id: readString(json['_id']),
        userId: readString(json['userId']),
        ayahIndex: readInt(json['ayahIndex']),
        surahNumber: readInt(json['surahNumber']),
        ayahNumber: readInt(json['ayahNumber']),
        ayahKey: readString(json['ayahKey']),
        paraNumber: readInt(json['paraNumber']),
        isRead: readBool(json['isRead']),
        readSeconds: readInt(json['readSeconds']),
        readMinutes: readDouble(json['readMinutes']),
        sessionCount: readInt(json['sessionCount']),
        surahNameEnglish: readString(json['surahNameEnglish']),
        surahNameBangla: readString(json['surahNameBangla']),
        surahNameArabic: readString(json['surahNameArabic']),
        createdAt: readInstant(json['createdAt']),
        updatedAt: readInstant(json['updatedAt']),
        firstReadAt: readInstant(json['firstReadAt']),
        lastReadAt: readInstant(json['lastReadAt']),
        completedAt: readInstant(json['completedAt']),
      );

  static QuranLastReadRecord? tryParse(Object? json) {
    final map = readMapOrNull(json);
    return map == null ? null : QuranLastReadRecord.fromJson(map);
  }

  final String id;
  final String userId;

  /// 1-6236 across the whole Quran.
  final int ayahIndex;
  final int surahNumber;
  final int ayahNumber;
  final String ayahKey;
  final int paraNumber;
  final bool isRead;
  final int readSeconds;
  final double readMinutes;
  final int sessionCount;
  final String surahNameEnglish;
  final String surahNameBangla;
  final String surahNameArabic;

  /// Instants from the API (UTC).
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? firstReadAt;
  final DateTime? lastReadAt;
  final DateTime? completedAt;
}

/// `GET /quran/reading/last-read`: where the user stopped, and the ayah to
/// continue from (ayah 1:1 for a new reader).
class QuranLastRead {
  const QuranLastRead({required this.lastRead, required this.continueFrom});

  factory QuranLastRead.fromJson(Map<String, dynamic> json) => QuranLastRead(
    lastRead: QuranLastReadRecord.tryParse(json['lastRead']),
    continueFrom: QuranAyahPosition.tryParse(json['continueFrom']),
  );

  /// Null until the user has read anything.
  final QuranLastReadRecord? lastRead;
  final QuranAyahPosition? continueFrom;
}
