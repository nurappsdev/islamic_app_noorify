import 'package:tuhfatul_muslim/features/dua/data/dua_catalog.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';

/// Arguments for [RouteNames.duaReader] — which dua to show.
///
/// [featuredModel] carries a real `/duas/featured` item (one ready-to-read
/// dua); [featured]/[detail] are the legacy mock pair still used by
/// [DuaGroupScreen] / [DuaAllDuaScreen]'s demo "All dua" lists. Exactly one
/// of the two pairs is set.
class DuaReaderArgs {
  const DuaReaderArgs.mock({required this.featured, required this.detail})
    : featuredModel = null;

  const DuaReaderArgs.real(this.featuredModel) : featured = null, detail = null;

  final DuaFeatured? featured;
  final DuaDetail? detail;
  final DuaFeaturedModel? featuredModel;

  static DuaReaderArgs get fallback => DuaReaderArgs.mock(
    featured: DuaCatalog.featured.first,
    detail: DuaCatalog.groupDuas.first,
  );
}

/// Arguments for the real API-backed list opened from a Dua category tile.
class DuaCategoryDuasArgs {
  const DuaCategoryDuasArgs(this.category);

  final DuaCategoryModel category;
}
