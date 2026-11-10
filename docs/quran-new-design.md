# Quran new design integration

All eight PNGs in `assets/images/quran_new_Design` were reviewed before implementation.

| Reference | Integration | Existing logic reused |
| --- | --- | --- |
| `design_1.png` | Filter sheet from landing page and reader; revelation chips, Para carousel, searchable Surah list, horizontal ayah wheel, Apply/Cancel | `QuranContentService` catalogs and cache, `SurahRouteArgs`, `QuranReadingCubit` |
| `copy_ayat_design.png` | Copy and native Share actions in the ayah drawer and reader menu | Installed `share_plus`, platform clipboard; Arabic and selected translation from `QuranAyah` |
| `translate_design_ui.png` | Rounded translation drawer with Bangla/English selection and retained audio/bookmark actions | Translation catalog, individual-ayah API/cache, per-ayah preference overrides in `QuranTranslationBloc` |
| `tafsir_design_ui.png` | Verse-associated Tafsir expands beneath the current reader and player with language selection; vertical scrolling reveals it without changing routes or the Quran scroll position | Reusable `QuranTafsirContent`, existing `TafsirBloc` and Tafsir service; legacy Tafsir screen reuses the same content |
| `tajweed_design_ui.png` | Quran artwork, olive download panel and real progress states | `OfflineQuranBloc` and resumable `QuranOfflineDownloader` |
| Surah left/right components | Reusable framed Surah image/name components for adjacent Surahs | Supplied transparent ornaments, cached live Surah catalog and existing reader routes |
| `Three dot.png` | View in ayat, Book Mark Surah, Change text, Share, Translate; download access retained | Existing reading preference events, bookmark store, settings sheet and ayah actions |

## Navigation and reading

- Same-Surah filters retain the reader route; changed Surah or Para bounds replace it.
- `paraStartAyah` separates the Para's lower bound from a selected/deep-linked ayah. Reading and audio respect the same bounds.
- Adjacent Surah cards use catalog data rather than hardcoded names. Reader replacement avoids stacking a route for each Surah.
- A persistent Quran tab shell keeps the same bottom bar mounted across Quran and all four Coming Soon tabs. Selection changes the body without pushing routes; Quran search and scroll state stay mounted. Back from a placeholder returns to Quran. Existing feature routes remain available through their other entry points.
- Actual Quran-page swipes, clipped reading frames, auto-hiding controls and bounded ayah markers remain intact.
- Copy/share preserves Arabic content verbatim, and includes the verse key and translation source. Native share destinations are supplied by the device.

## Backend limitation

The existing APIs provide standard Quran text and recitation downloads, but no Tajweed-specific document or annotated-text download contract. The download sheet states this and offers the functioning standard offline download. It never simulates a Tajweed download. A TODO records the needed versioned content/file URL, file size and checksum.

## Validation

Quran tests cover API parsing/caching/pagination, sequential reading, playback, frame clipping, idle controls, marker spacing, filter application and Para bounds, haptics, native share/clipboard dispatch, translation resource switching, existing Tafsir requests, real download progress states, and Home/Quran navigation stacks.

Optional rendered previews can be exported with `QURAN_DESIGN_PREVIEWS` and a `QURAN_PREVIEW_FONTS` path to Flutter's material fonts when running `test/quran_new_design_test.dart`. Native sharing is tested at the platform-channel boundary; destination apps depend on the device.
