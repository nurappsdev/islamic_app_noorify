import 'package:islami_app_noorify/features/dua/data/dua_catalog.dart';

/// Arguments for [RouteNames.duaReader] — which dua to show, and which
/// featured group it belongs to (for the header's "Daily Life"-style
/// breadcrumb label).
class DuaReaderArgs {
  const DuaReaderArgs({required this.featured, required this.detail});

  final DuaFeatured featured;
  final DuaDetail detail;

  static DuaReaderArgs get fallback => DuaReaderArgs(
    featured: DuaCatalog.featured.first,
    detail: DuaCatalog.groupDuas.first,
  );
}
