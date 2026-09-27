# Quran migration

## Content and storage

`QuranContentService` uses the application's `DioClient` and `/api/v1/quran` base path. It provides the Surah catalog/details, Para catalog/details, translation catalog, bounded ayah requests, and individual ayahs. These response shapes were checked against the live server.

The interactive reader requests at most 16 ayahs at a time. It follows `meta.page` / `meta.totalPage` when the server subdivides that range. Each displayed page contains only ayahs with the same API `pageNumber`, gathering adjacent cached batches when needed. Horizontal swipes advance one actual page at a time; the bottom page-number and arrow row has been removed. Page transitions and vertical scrolling are clipped inside the stationary ornamental frame. Translation changes keep the current page and scroll position; stale asynchronous responses cannot overwrite a newer selection. Translations are indexed by resource ID.

Memory caching is bounded to 48 responses. The existing SQLite database now also stores internal metadata and ayahs, merging translations by resource ID. SharedPreferences provides a recent-response fallback if SQLite is unavailable. Explicit offline download still exists; entering Quran no longer starts a whole-Quran download. Older offline content is retained, but does not count as a completed internal-API download. The database migration adds tables and preserves existing audio files and audio records.

## Design and navigation

All eight PNGs in `devImg/quran` were inspected. The five supplied artwork assets are copied into `assets/images/quran` and registered in `pubspec.yaml`.

The landing page uses the reference's gradient artwork card, three tabs, search field, numbered list rows, and olive navigation. Surah and Para search filters actual catalog data locally, including Bangla and Arabic names. The Page tab explicitly indicates that browsing is unavailable; no page or full-text search endpoint was invented.

Both existing Surah route names now open the framed reader. Bookmark, history, and last-read navigation carry the saved ayah number. Para details show the API's Surahs and boundaries; each section opens a reader constrained to that Para's ayah range. Translation display is available through reader settings or the overflow menu. Arabic-only reading is the default for a new installation; saved preferences remain respected.

## Audio retained

The existing `QuranAudioHandler`, `SurahPlaybackBloc`, `AyahAudioBloc`, downloader, and background-audio service remain in use. Full-surah controls were extracted into reusable widgets. Individual ayah details retain playback, repeat, and bookmarking. The new compact bar also displays audio progress.

Quran.com remains only for:

- Reciter resources: `/api/v4/resources/recitations`
- Ayah/chapter audio: `/api/v4/recitations/...`
- Tafsir: `/api/v4/tafsirs/...`
- Audio files hosted by `verses.quran.com`

No equivalent internal audio or tafsir API was supplied. Quran.com content, translation, and Juz endpoints and the old `quranapi.pages.dev` client have been replaced.

Playback now resumes a paused clip without reloading it. Loading an audio file no longer waits until playback ends before clearing buffering. Para playback stops at the selected section's end.

## Verification

Commands:

```sh
flutter test test/quran_content_test.dart test/quran_playback_test.dart test/quran_widgets_test.dart
flutter analyze --no-pub lib/features/quran tool/quran_preview.dart
flutter build apk --debug --no-pub
```

The 19 focused tests cover internal envelopes, resource IDs, pagination, overlapping pages, request deduplication, retries, Para bounds, stale requests, individual ayahs, playback/download gating, and pause/resume. Widget checks cover 320px navigation with enlarged text, long Bangla translations, maximum Arabic zoom, saved-ayah navigation, and translation changes preserving the range.

The native Quran preview was built and run on an Android emulator using real APIs. Landing, reader, and settings screenshots were inspected against the references. `tool/quran_preview.dart` is a standalone native entry point for repeating this visual check without Firebase/Home bootstrapping:

```sh
flutter run -d emulator-5554 -t tool/quran_preview.dart
```

The full project test run reported 249 passes and 14 failures outside Quran (Hadith Hive setup and Home/prayer widget expectations/providers). Full-project analysis also reports the existing unresolved `animations` import in the unused Home `vertical_card_switcher.dart`, plus existing lints. The Android debug build succeeds because that file is not in the application's build graph.

Physical-device lock-screen behavior and iOS playback were not independently revalidated; their existing native/audio-service configuration is unchanged.

Reader controls (filters, timer, and playback bar) fade and collapse after five seconds without pointer activity. Touching, scrolling, or swiping reveals them and restarts the idle interval after release. The page expands into their space; the playback widgets remain mounted. Surah-opening pages omit the upper frame ornament. Ayah markers have explicit spacing, and Arabic lines and translated ayah blocks have increased separation.
