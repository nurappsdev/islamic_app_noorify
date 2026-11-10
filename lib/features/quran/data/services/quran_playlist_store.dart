import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/quran_playlist.dart';

class QuranPlaylistStore {
  static const _playlistsKey = 'quran_playlists_v1';

  static final List<QuranPlaylist> defaultPlaylists = [
    QuranPlaylist(
      id: 'pl_1',
      title: 'Play List 1',
      createdAt: DateTime.now(),
      items: const [
        QuranPlaylistItem(
          surahNo: 1,
          surahName: 'Al-Fatiah',
          arabicName: 'الفاتحة',
          revelationPlace: 'Meccan',
          startAyah: 1,
          endAyah: 2,
          totalAyah: 7,
        ),
        QuranPlaylistItem(
          surahNo: 2,
          surahName: 'Al-Baqarah',
          arabicName: 'البقرة',
          revelationPlace: 'Medinian',
          startAyah: 1,
          endAyah: 6,
          totalAyah: 286,
        ),
      ],
    ),
    QuranPlaylist(
      id: 'pl_2',
      title: 'Morning Recitation',
      createdAt: DateTime.now(),
      items: const [
        QuranPlaylistItem(
          surahNo: 36,
          surahName: 'Ya-Sin',
          arabicName: 'يس',
          revelationPlace: 'Meccan',
          startAyah: 1,
          endAyah: 12,
          totalAyah: 83,
        ),
        QuranPlaylistItem(
          surahNo: 67,
          surahName: 'Al-Mulk',
          arabicName: 'الملك',
          revelationPlace: 'Meccan',
          startAyah: 1,
          endAyah: 30,
          totalAyah: 30,
        ),
      ],
    ),
    QuranPlaylist(
      id: 'pl_3',
      title: 'Protection & Peace',
      createdAt: DateTime.now(),
      items: const [
        QuranPlaylistItem(
          surahNo: 112,
          surahName: 'Al-Ikhlas',
          arabicName: 'الإخلاص',
          revelationPlace: 'Meccan',
          startAyah: 1,
          endAyah: 4,
          totalAyah: 4,
        ),
        QuranPlaylistItem(
          surahNo: 113,
          surahName: 'Al-Falaq',
          arabicName: 'الفلق',
          revelationPlace: 'Meccan',
          startAyah: 1,
          endAyah: 5,
          totalAyah: 5,
        ),
        QuranPlaylistItem(
          surahNo: 114,
          surahName: 'An-Nas',
          arabicName: 'الناس',
          revelationPlace: 'Meccan',
          startAyah: 1,
          endAyah: 6,
          totalAyah: 6,
        ),
      ],
    ),
  ];

  static Future<List<QuranPlaylist>> loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_playlistsKey);
    if (raw == null || raw.isEmpty) {
      return defaultPlaylists;
    }
    try {
      final list = jsonDecode(raw) as List;
      final parsed = list
          .map((e) => QuranPlaylist.fromJson(e as Map<String, dynamic>))
          .toList();
      return parsed.isNotEmpty ? parsed : defaultPlaylists;
    } catch (_) {
      return defaultPlaylists;
    }
  }

  static Future<void> savePlaylists(List<QuranPlaylist> playlists) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _playlistsKey,
      jsonEncode(playlists.map((e) => e.toJson()).toList()),
    );
  }
}
