/// Domain models for Quran Playlist.
///
/// Follows the server schema (`/quran/playlists`), keeping [counts], [nextAyah],
/// and item-level progress as calculated by the server. Retains convenience getters
/// ([title], [surahNo], [surahName], [arabicName], [startAyah], [endAyah], [totalAyah])
/// so existing player widgets and screens remain fully compatible.
library;

class QuranPlaylistItem {
  const QuranPlaylistItem({
    this.id = '',
    this.type = 'surah',
    int? surahNumber,
    int? surahNo,
    String? title,
    String? surahName,
    String? surahNameEnglish,
    String? surahNameBangla,
    String? surahNameArabic,
    String? arabicName,
    this.revelationPlace = 'Meccan',
    int? fromAyah,
    int? startAyah,
    int? toAyah,
    int? endAyah,
    int? totalAyahs,
    int? totalAyah,
    this.paraNumber,
    this.readAyahs = 0,
    int? remainingAyahs,
    this.percentage = 0.0,
    this.isCompleted = false,
    this.start,
    this.end,
  }) : surahNumber = surahNumber ?? surahNo ?? 1,
       title = title ?? surahName ?? surahNameEnglish ?? '',
       surahNameEnglish = surahNameEnglish ?? surahName ?? title ?? '',
       surahNameBangla = surahNameBangla ?? '',
       surahNameArabic = surahNameArabic ?? arabicName ?? '',
       fromAyah = fromAyah ?? startAyah ?? 1,
       toAyah = toAyah ?? endAyah ?? (totalAyahs ?? totalAyah ?? 1),
       totalAyahs = totalAyahs ?? totalAyah ?? 0,
       remainingAyahs = remainingAyahs ??
           (((totalAyahs ?? totalAyah ?? 0) - readAyahs) < 0
               ? 0
               : ((totalAyahs ?? totalAyah ?? 0) - readAyahs));

  final String id;
  final String type; // 'surah' | 'para' | 'ayahs'
  final int surahNumber;
  final String title;
  final String surahNameEnglish;
  final String surahNameBangla;
  final String surahNameArabic;
  final String revelationPlace;
  final int fromAyah;
  final int toAyah;
  final int totalAyahs;
  final int? paraNumber;
  final int readAyahs;
  final int remainingAyahs;
  final double percentage;
  final bool isCompleted;
  final int? start;
  final int? end;

  // Compatibility getters for existing UI and audio player
  int get surahNo => surahNumber;
  String get surahName =>
      surahNameEnglish.isNotEmpty
          ? surahNameEnglish
          : (title.isNotEmpty ? title : 'Surah $surahNumber');
  String get arabicName => surahNameArabic;
  int get startAyah => fromAyah;
  int get endAyah => toAyah;
  int get totalAyah =>
      totalAyahs > 0 ? totalAyahs : (endAyah - startAyah + 1).clamp(1, 999999);

  /// Localized display name depending on user language preference
  String localizedName(String langCode) {
    if (langCode == 'bn' && surahNameBangla.isNotEmpty) {
      return surahNameBangla;
    }
    if (langCode == 'ar' && surahNameArabic.isNotEmpty) {
      return surahNameArabic;
    }
    return surahName;
  }

  QuranPlaylistItem copyWith({
    String? id,
    String? type,
    int? surahNumber,
    String? title,
    String? surahNameEnglish,
    String? surahNameBangla,
    String? surahNameArabic,
    String? revelationPlace,
    int? fromAyah,
    int? toAyah,
    int? totalAyahs,
    int? paraNumber,
    int? readAyahs,
    int? remainingAyahs,
    double? percentage,
    bool? isCompleted,
    int? start,
    int? end,
  }) => QuranPlaylistItem(
    id: id ?? this.id,
    type: type ?? this.type,
    surahNumber: surahNumber ?? this.surahNumber,
    title: title ?? this.title,
    surahNameEnglish: surahNameEnglish ?? this.surahNameEnglish,
    surahNameBangla: surahNameBangla ?? this.surahNameBangla,
    surahNameArabic: surahNameArabic ?? this.surahNameArabic,
    revelationPlace: revelationPlace ?? this.revelationPlace,
    fromAyah: fromAyah ?? this.fromAyah,
    toAyah: toAyah ?? this.toAyah,
    totalAyahs: totalAyahs ?? this.totalAyahs,
    paraNumber: paraNumber ?? this.paraNumber,
    readAyahs: readAyahs ?? this.readAyahs,
    remainingAyahs: remainingAyahs ?? this.remainingAyahs,
    percentage: percentage ?? this.percentage,
    isCompleted: isCompleted ?? this.isCompleted,
    start: start ?? this.start,
    end: end ?? this.end,
  );

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) '_id': id,
    'type': type,
    'surahNumber': surahNumber,
    'surahNo': surahNumber,
    'title': title,
    'surahName': surahName,
    'surahNameEnglish': surahNameEnglish,
    'surahNameBangla': surahNameBangla,
    'surahNameArabic': surahNameArabic,
    'arabicName': surahNameArabic,
    'revelationPlace': revelationPlace,
    'fromAyah': fromAyah,
    'startAyah': fromAyah,
    'toAyah': toAyah,
    'endAyah': toAyah,
    'totalAyahs': totalAyah,
    'totalAyah': totalAyah,
    if (paraNumber != null) 'paraNumber': paraNumber,
    'readAyahs': readAyahs,
    'remainingAyahs': remainingAyahs,
    'percentage': percentage,
    'isCompleted': isCompleted,
    if (start != null) 'start': start,
    if (end != null) 'end': end,
  };

  factory QuranPlaylistItem.fromJson(Map<String, dynamic> json) {
    final sNo =
        (json['surahNumber'] as num?)?.toInt() ??
        (json['surahNo'] as num?)?.toInt() ??
        1;
    final fAyah =
        (json['fromAyah'] as num?)?.toInt() ??
        (json['startAyah'] as num?)?.toInt() ??
        (json['start'] as num?)?.toInt() ??
        1;
    final tAyah =
        (json['toAyah'] as num?)?.toInt() ??
        (json['endAyah'] as num?)?.toInt() ??
        (json['end'] as num?)?.toInt() ??
        (json['totalAyahs'] as num?)?.toInt() ??
        (json['totalAyah'] as num?)?.toInt() ??
        1;
    final tAyahs =
        (json['totalAyahs'] as num?)?.toInt() ??
        (json['totalAyah'] as num?)?.toInt() ??
        (tAyah - fAyah + 1).clamp(1, 999999);
    final rAyahs = (json['readAyahs'] as num?)?.toInt() ?? 0;
    final remAyahs =
        (json['remainingAyahs'] as num?)?.toInt() ??
        (tAyahs - rAyahs).clamp(0, 999999);

    final pctRaw = json['percentage'];
    final pct =
        (pctRaw is num)
            ? pctRaw.toDouble()
            : (tAyahs > 0
                ? ((rAyahs / tAyahs) * 100).clamp(0.0, 100.0)
                : 0.0);

    return QuranPlaylistItem(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'surah',
      surahNumber: sNo,
      title: json['title'] as String? ?? json['surahName'] as String? ?? '',
      surahNameEnglish:
          json['surahNameEnglish'] as String? ??
          json['surahName'] as String? ??
          json['title'] as String? ??
          '',
      surahNameBangla: json['surahNameBangla'] as String? ?? '',
      surahNameArabic:
          json['surahNameArabic'] as String? ??
          json['arabicName'] as String? ??
          '',
      revelationPlace: json['revelationPlace'] as String? ?? 'Meccan',
      fromAyah: fAyah,
      toAyah: tAyah,
      totalAyahs: tAyahs,
      paraNumber: (json['paraNumber'] as num?)?.toInt(),
      readAyahs: rAyahs,
      remainingAyahs: remAyahs,
      percentage: pct,
      isCompleted:
          json['isCompleted'] as bool? ?? (tAyahs > 0 && rAyahs >= tAyahs),
      start: (json['start'] as num?)?.toInt(),
      end: (json['end'] as num?)?.toInt(),
    );
  }
}

/// Progress counts for a Quran Playlist calculated by the server.
class QuranPlaylistCounts {
  const QuranPlaylistCounts({
    this.totalItems = 0,
    this.totalAyahs = 0,
    this.completedAyahs = 0,
    this.remainingAyahs = 0,
    this.percentage = 0.0,
    this.isCompleted = false,
  });

  final int totalItems;
  final int totalAyahs;
  final int completedAyahs;
  final int remainingAyahs;
  final double percentage;
  final bool isCompleted;

  factory QuranPlaylistCounts.fromJson(Map<String, dynamic> json) =>
      QuranPlaylistCounts(
        totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
        totalAyahs: (json['totalAyahs'] as num?)?.toInt() ?? 0,
        completedAyahs: (json['completedAyahs'] as num?)?.toInt() ?? 0,
        remainingAyahs: (json['remainingAyahs'] as num?)?.toInt() ?? 0,
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
    'totalItems': totalItems,
    'totalAyahs': totalAyahs,
    'completedAyahs': completedAyahs,
    'remainingAyahs': remainingAyahs,
    'percentage': percentage,
    'isCompleted': isCompleted,
  };
}

/// The next unread Ayah for continuing reading in a playlist.
class QuranPlaylistNextAyah {
  const QuranPlaylistNextAyah({
    required this.surahNumber,
    required this.ayahNumber,
    required this.ayahKey,
    this.paraNumber = 1,
    this.surahNameEnglish = '',
    this.surahNameBangla = '',
    this.surahNameArabic = '',
  });

  final int surahNumber;
  final int ayahNumber;
  final String ayahKey;
  final int paraNumber;
  final String surahNameEnglish;
  final String surahNameBangla;
  final String surahNameArabic;

  factory QuranPlaylistNextAyah.fromJson(Map<String, dynamic> json) =>
      QuranPlaylistNextAyah(
        surahNumber: (json['surahNumber'] as num?)?.toInt() ?? 1,
        ayahNumber: (json['ayahNumber'] as num?)?.toInt() ?? 1,
        ayahKey: json['ayahKey'] as String? ?? '',
        paraNumber: (json['paraNumber'] as num?)?.toInt() ?? 1,
        surahNameEnglish: json['surahNameEnglish'] as String? ?? '',
        surahNameBangla: json['surahNameBangla'] as String? ?? '',
        surahNameArabic: json['surahNameArabic'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'surahNumber': surahNumber,
    'ayahNumber': ayahNumber,
    'ayahKey': ayahKey,
    'paraNumber': paraNumber,
    'surahNameEnglish': surahNameEnglish,
    'surahNameBangla': surahNameBangla,
    'surahNameArabic': surahNameArabic,
  };
}

/// Resume point for reading or audio playback.
class QuranPlaylistResumeFrom {
  const QuranPlaylistResumeFrom({
    required this.surahNumber,
    required this.ayahNumber,
  });

  final int surahNumber;
  final int ayahNumber;

  factory QuranPlaylistResumeFrom.fromJson(Map<String, dynamic> json) =>
      QuranPlaylistResumeFrom(
        surahNumber: (json['surahNumber'] as num?)?.toInt() ?? 1,
        ayahNumber: (json['ayahNumber'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toJson() => {
    'surahNumber': surahNumber,
    'ayahNumber': ayahNumber,
  };
}

/// A Quran playlist.
class QuranPlaylist {
  const QuranPlaylist({
    required this.id,
    String? name,
    String? title,
    this.userId = '',
    this.description,
    this.reciterId,
    this.items = const [],
    this.counts = const QuranPlaylistCounts(),
    this.nextAyah,
    this.resumeFrom,
    this.lastPosition,
    this.lastPlayedAt,
    this.isActive = true,
    required this.createdAt,
    DateTime? updatedAt,
  }) : name = name ?? title ?? '',
       updatedAt = updatedAt ?? createdAt;

  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? reciterId;
  final List<QuranPlaylistItem> items;
  final QuranPlaylistCounts counts;
  final QuranPlaylistNextAyah? nextAyah;
  final QuranPlaylistResumeFrom? resumeFrom;
  final QuranPlaylistResumeFrom? lastPosition;
  final DateTime? lastPlayedAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Compatibility alias for existing screens
  String get title => name;

  int get totalAyahs =>
      counts.totalAyahs > 0
          ? counts.totalAyahs
          : items.fold<int>(0, (sum, item) => sum + item.totalAyah);

  int get completedAyahs => counts.completedAyahs;
  int get remainingAyahs =>
      counts.remainingAyahs > 0
          ? counts.remainingAyahs
          : (totalAyahs - completedAyahs).clamp(0, 999999);
  double get percentage =>
      counts.percentage > 0
          ? counts.percentage
          : (totalAyahs > 0
              ? ((completedAyahs / totalAyahs) * 100).clamp(0.0, 100.0)
              : 0.0);
  bool get isCompleted => counts.isCompleted || (percentage >= 100.0);

  String get surahSummaryText {
    if (items.isEmpty) return 'No Surahs';
    final names = items.map((e) => e.surahName).take(2).join(', ');
    return 'Sura ($names${items.length > 2 ? ', ...' : ''})';
  }

  QuranPlaylist copyWith({
    String? id,
    String? userId,
    String? name,
    String? title,
    String? description,
    String? reciterId,
    List<QuranPlaylistItem>? items,
    QuranPlaylistCounts? counts,
    QuranPlaylistNextAyah? nextAyah,
    QuranPlaylistResumeFrom? resumeFrom,
    QuranPlaylistResumeFrom? lastPosition,
    DateTime? lastPlayedAt,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => QuranPlaylist(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? title ?? this.name,
    description: description ?? this.description,
    reciterId: reciterId ?? this.reciterId,
    items: items ?? this.items,
    counts: counts ?? this.counts,
    nextAyah: nextAyah ?? this.nextAyah,
    resumeFrom: resumeFrom ?? this.resumeFrom,
    lastPosition: lastPosition ?? this.lastPosition,
    lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'id': id,
    'userId': userId,
    'name': name,
    'title': name,
    if (description != null) 'description': description,
    if (reciterId != null) 'reciterId': reciterId,
    'items': items.map((e) => e.toJson()).toList(),
    'counts': counts.toJson(),
    if (nextAyah != null) 'nextAyah': nextAyah!.toJson(),
    if (resumeFrom != null) 'resumeFrom': resumeFrom!.toJson(),
    if (lastPosition != null) 'lastPosition': lastPosition!.toJson(),
    if (lastPlayedAt != null) 'lastPlayedAt': lastPlayedAt!.toIso8601String(),
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory QuranPlaylist.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    final itemsList =
        (itemsJson is List)
            ? itemsJson
                .whereType<Map<String, dynamic>>()
                .map(QuranPlaylistItem.fromJson)
                .toList()
            : const <QuranPlaylistItem>[];

    final countsJson = json['counts'];
    final nextAyahJson = json['nextAyah'];
    final resumeFromJson = json['resumeFrom'];
    final lastPositionJson = json['lastPosition'];

    final id = json['_id'] as String? ?? json['id'] as String? ?? '';
    final name = json['name'] as String? ?? json['title'] as String? ?? '';

    return QuranPlaylist(
      id: id,
      userId: json['userId'] as String? ?? '',
      name: name,
      description: json['description'] as String?,
      reciterId: json['reciterId'] as String?,
      items: itemsList,
      counts:
          countsJson is Map<String, dynamic>
              ? QuranPlaylistCounts.fromJson(countsJson)
              : const QuranPlaylistCounts(),
      nextAyah:
          nextAyahJson is Map<String, dynamic>
              ? QuranPlaylistNextAyah.fromJson(nextAyahJson)
              : null,
      resumeFrom:
          resumeFromJson is Map<String, dynamic>
              ? QuranPlaylistResumeFrom.fromJson(resumeFromJson)
              : null,
      lastPosition:
          lastPositionJson is Map<String, dynamic>
              ? QuranPlaylistResumeFrom.fromJson(lastPositionJson)
              : null,
      lastPlayedAt:
          json['lastPlayedAt'] != null
              ? DateTime.tryParse(json['lastPlayedAt'] as String)
              : null,
      isActive: json['isActive'] as bool? ?? true,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// Pagination metadata for Quran playlists and ayahs.
class QuranPlaylistMeta {
  const QuranPlaylistMeta({
    this.page = 1,
    this.limit = 10,
    this.total = 0,
    this.totalPage = 0,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPage;

  bool get hasMore => page < totalPage;

  factory QuranPlaylistMeta.fromJson(Map<String, dynamic> json) =>
      QuranPlaylistMeta(
        page: (json['page'] as num?)?.toInt() ?? 1,
        limit: (json['limit'] as num?)?.toInt() ?? 10,
        total: (json['total'] as num?)?.toInt() ?? 0,
        totalPage: (json['totalPage'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'page': page,
    'limit': limit,
    'total': total,
    'totalPage': totalPage,
  };
}

/// Paginated wrapper returned by `GET /quran/playlists`.
class QuranPlaylistsResponse {
  const QuranPlaylistsResponse({
    required this.playlists,
    this.meta = const QuranPlaylistMeta(),
  });

  final List<QuranPlaylist> playlists;
  final QuranPlaylistMeta meta;

  factory QuranPlaylistsResponse.fromJson(Map<String, dynamic> json) {
    final list = json['data'] is List ? (json['data'] as List) : const [];
    final metaJson =
        json['meta'] is Map<String, dynamic>
            ? json['meta'] as Map<String, dynamic>
            : const <String, dynamic>{};
    return QuranPlaylistsResponse(
      playlists:
          list
              .whereType<Map<String, dynamic>>()
              .map(QuranPlaylist.fromJson)
              .toList(),
      meta: QuranPlaylistMeta.fromJson(metaJson),
    );
  }
}

/// An item input for creating or updating a playlist.
class PlaylistItemInput {
  const PlaylistItemInput({
    this.type = 'surah',
    this.surahNumber,
    this.fromAyah,
    this.toAyah,
    this.paraNumber,
  });

  final String type; // 'surah' | 'para' | 'ayahs'
  final int? surahNumber;
  final int? fromAyah;
  final int? toAyah;
  final int? paraNumber;

  Map<String, dynamic> toJson() => {
    'type': type,
    if (surahNumber != null) 'surahNumber': surahNumber,
    if (fromAyah != null) 'fromAyah': fromAyah,
    if (toAyah != null) 'toAyah': toAyah,
    if (paraNumber != null) 'paraNumber': paraNumber,
  };

  factory PlaylistItemInput.fromPlaylistItem(QuranPlaylistItem item) =>
      PlaylistItemInput(
        type: item.type,
        surahNumber: item.surahNumber,
        fromAyah: item.fromAyah,
        toAyah: item.toAyah,
        paraNumber: item.paraNumber,
      );
}

/// Request body for `POST /quran/playlists`.
class CreateQuranPlaylistRequest {
  const CreateQuranPlaylistRequest({
    required this.name,
    this.description,
    this.reciterId,
    this.items = const [],
  });

  final String name;
  final String? description;
  final String? reciterId;
  final List<PlaylistItemInput> items;

  Map<String, dynamic> toJson() => {
    'name': name,
    if (description != null && description!.isNotEmpty)
      'description': description,
    if (reciterId != null && reciterId!.isNotEmpty) 'reciterId': reciterId,
    'items': items.map((e) => e.toJson()).toList(),
  };
}

/// Request body for `PATCH /quran/playlists/{id}`.
class UpdateQuranPlaylistRequest {
  const UpdateQuranPlaylistRequest({
    this.name,
    this.description,
    this.reciterId,
    this.items,
  });

  final String? name;
  final String? description;
  final String? reciterId;
  final List<PlaylistItemInput>? items;

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (description != null) 'description': description,
    if (reciterId != null) 'reciterId': reciterId,
    if (items != null) 'items': items!.map((e) => e.toJson()).toList(),
  };
}

/// Text content for a playlist Ayah.
class QuranPlaylistAyahText {
  const QuranPlaylistAyahText({
    this.arabic = '',
    this.english = '',
    this.bangla = '',
  });

  final String arabic;
  final String english;
  final String bangla;

  factory QuranPlaylistAyahText.fromJson(Map<String, dynamic> json) =>
      QuranPlaylistAyahText(
        arabic: json['arabic'] as String? ?? '',
        english: json['english'] as String? ?? '',
        bangla: json['bangla'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'arabic': arabic,
    'english': english,
    'bangla': bangla,
  };
}

/// A single Ayah item from `GET /quran/playlists/{id}/ayahs`.
class QuranPlaylistAyah {
  const QuranPlaylistAyah({
    required this.surahNumber,
    required this.ayahNumber,
    required this.ayahKey,
    this.paraNumber = 1,
    this.isRead = false,
    this.readAt,
    this.text,
  });

  final int surahNumber;
  final int ayahNumber;
  final String ayahKey;
  final int paraNumber;
  final bool isRead;
  final DateTime? readAt;
  final QuranPlaylistAyahText? text;

  factory QuranPlaylistAyah.fromJson(Map<String, dynamic> json) {
    final textJson = json['text'];
    return QuranPlaylistAyah(
      surahNumber: (json['surahNumber'] as num?)?.toInt() ?? 1,
      ayahNumber: (json['ayahNumber'] as num?)?.toInt() ?? 1,
      ayahKey: json['ayahKey'] as String? ?? '',
      paraNumber: (json['paraNumber'] as num?)?.toInt() ?? 1,
      isRead: json['isRead'] as bool? ?? false,
      readAt:
          json['readAt'] != null
              ? DateTime.tryParse(json['readAt'] as String)
              : null,
      text:
          textJson is Map<String, dynamic>
              ? QuranPlaylistAyahText.fromJson(textJson)
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'surahNumber': surahNumber,
    'ayahNumber': ayahNumber,
    'ayahKey': ayahKey,
    'paraNumber': paraNumber,
    'isRead': isRead,
    if (readAt != null) 'readAt': readAt!.toIso8601String(),
    if (text != null) 'text': text!.toJson(),
  };
}

/// Paginated result of `GET /quran/playlists/{id}/ayahs`.
class PaginatedQuranPlaylistAyahs {
  const PaginatedQuranPlaylistAyahs({
    required this.ayahs,
    this.meta = const QuranPlaylistMeta(),
  });

  final List<QuranPlaylistAyah> ayahs;
  final QuranPlaylistMeta meta;

  factory PaginatedQuranPlaylistAyahs.fromJson(Map<String, dynamic> json) {
    final list = json['data'] is List ? (json['data'] as List) : const [];
    final metaJson =
        json['meta'] is Map<String, dynamic>
            ? json['meta'] as Map<String, dynamic>
            : const <String, dynamic>{};
    return PaginatedQuranPlaylistAyahs(
      ayahs:
          list
              .whereType<Map<String, dynamic>>()
              .map(QuranPlaylistAyah.fromJson)
              .toList(),
      meta: QuranPlaylistMeta.fromJson(metaJson),
    );
  }
}
