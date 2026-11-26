import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The Dua feature's Web/desktop layout rules, in one place.
///
/// The Dua reading dashboard was the first Dua route to lay itself out
/// against the browser's own width instead of being letterboxed into a
/// phone-shaped column by `WebMobileCanvas`. These are that screen's
/// measurements, lifted here so every Dua route shares one set rather than
/// each inventing its own.
///
/// Everything here is in raw logical pixels, never ScreenUtil design units
/// (`.w` / `.h`): the browser window is what gets wide, and ScreenUtil's
/// design-size scaling does not follow it. Spacing inside a page still uses
/// ScreenUtil, exactly as on the phone; the type is written in ScreenUtil
/// units too and grown with the window by [DuaWebTypography], so a phone's
/// caption is not read at phone size on a monitor.
abstract final class DuaLayout {
  /// Below this a page stays the single phone-like column it already was;
  /// at or above it a page may spread into the room a browser gives it.
  static const wide = 720.0;

  /// A second step, for a desktop window: grids gain one more column here.
  static const extraWide = 1040.0;

  /// A third step, for a browser opened full screen on a desktop monitor.
  /// A page that stopped widening at [extraWide] left most of such a window
  /// empty, so grids gain one more column again and the content column
  /// itself runs on to [maxContent].
  static const ultraWide = 1440.0;

  /// Past this the content stops widening and the window grows around it.
  /// A line of text stretched across 2000px is unreadable.
  ///
  /// This is the width a full-screen browser fills: a 1440p window is used
  /// edge to edge (less its gutters), and only a wider monitor than that
  /// adds margins either side.
  static const maxContent = 1440.0;

  /// A reading column is capped tighter than [maxContent]. Dua Arabic,
  /// transliteration and translation are read line by line, and the eye
  /// loses its place on a line much wider than this.
  ///
  /// It is wider than a phone-derived measure would be because the type on
  /// the browser is larger too ([textScale]): the line holds about the same
  /// number of words as it did, in bigger letters.
  static const maxReading = 1000.0;

  /// The floating olive nav pill lines up with the page content above it,
  /// rather than sitting as a small pill in the middle of a wide window.
  ///
  /// `AppBottomNavBar` carries its own 16px margin either side, which is
  /// inside this box, so that margin is added back here: the pill itself
  /// then measures exactly [maxContent] and its edges meet the content
  /// column's. On a phone the window is far narrower than this, so the cap
  /// never bites and the bar is unchanged.
  static const maxNav = maxContent + 32;

  /// A form or sheet column - plan create, folder naming - that looks
  /// stretched and empty at full content width.
  static const maxForm = 760.0;

  /// `true` when [width] has room for a wide layout.
  static bool isWide(double width) => width >= wide;

  /// `true` when [width] has room for the widest layout.
  static bool isExtraWide(double width) => width >= extraWide;

  /// `true` when [width] is a full-screen desktop window.
  static bool isUltraWide(double width) => width >= ultraWide;

  /// Tiles across a card grid at [width]: the phone's two, three on a
  /// tablet or small browser window, four on a desktop one, five when the
  /// browser is full screen.
  static int columns(double width) {
    if (width >= ultraWide) return 5;
    if (width >= extraWide) return 4;
    if (width >= wide) return 3;
    return 2;
  }

  /// Columns for a list of wide cards (featured duas, saved folders, plans),
  /// which need far more room each than a category tile.
  static int listColumns(double width) {
    if (width >= ultraWide) return 3;
    if (width >= wide) return 2;
    return 1;
  }

  /// How much a Dua page's type grows on the browser at [width].
  ///
  /// `.sp` is a raw design number there - ScreenUtil's text scaling is off
  /// on Web (`enableScaleText: () => !kIsWeb` in `main_app.dart`) - so a
  /// 13px caption written for a phone held at reading distance stayed 13px
  /// on a monitor an arm's length away. These steps put the type back in
  /// proportion to the window, and are applied by [DuaWebTypography] on top
  /// of the reader's own font-size preference rather than in place of it.
  ///
  /// A phone-width browser window is left exactly as it was.
  static double textScale(double width) {
    if (width >= ultraWide) return 1.3;
    if (width >= extraWide) return 1.22;
    if (width >= wide) return 1.12;
    return 1.0;
  }
}

/// Centres a Dua page's content and caps how wide it may grow.
///
/// On a phone, and on Web below [DuaLayout.wide], this changes nothing: the
/// child already fits and the constraint never bites.
class DuaContentWidth extends StatelessWidget {
  const DuaContentWidth({super.key, required this.child, this.maxWidth});

  final Widget child;

  /// Defaults to [DuaLayout.maxContent]; pass [DuaLayout.maxReading] for a
  /// page of running text, or [DuaLayout.maxForm] for a form.
  final double? maxWidth;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? DuaLayout.maxContent),
      child: child,
    ),
  );
}

/// Caps a bottom-anchored bar's width without claiming any height.
///
/// [DuaContentWidth] is the wrong tool for an overlay: its `Center` has no
/// height factor, so when the parent offers it the whole page - as
/// `Align(alignment: Alignment.bottomCenter)` and a `Positioned` with no
/// `top` both do - it expands to fill that height and then centres the bar
/// inside it, leaving the bar floating in the middle of the page instead of
/// at its foot.
///
/// `heightFactor: 1` keeps this box exactly as tall as the bar, so the
/// parent's bottom alignment still decides where it sits.
class DuaBarWidth extends StatelessWidget {
  const DuaBarWidth({super.key, required this.child, this.maxWidth});

  final Widget child;

  /// Defaults to [DuaLayout.maxNav].
  final double? maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomCenter,
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? DuaLayout.maxNav),
      child: child,
    ),
  );
}

/// A Dua page's body: the column of sections it already had, centred and
/// width-capped so it reads the same on a phone and in a browser.
///
/// Used as the single child of a page's `ListView`, which is how the reading
/// dashboard does it - the sections keep their order and spacing, and only
/// the column's width changes.
class DuaContentColumn extends StatelessWidget {
  const DuaContentColumn({super.key, required this.children, this.maxWidth});

  final List<Widget> children;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) => DuaContentWidth(
    maxWidth: maxWidth,
    child: Column(
      // Sections span the column, as they did at phone width.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

/// Builds against the page's own width, so a screen can ask for a wide
/// layout without repeating a `LayoutBuilder` and the breakpoint each time.
///
/// The width handed to [builder] is the page's, before any content cap.
class DuaWidthBuilder extends StatelessWidget {
  const DuaWidthBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, double width, bool wide) builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      return builder(context, width, DuaLayout.isWide(width));
    },
  );
}

/// A grid of equal tiles that gains columns as the window widens, keeping
/// each tile's shape rather than stretching it.
///
/// [tileExtent] is the tile's height at phone width, in ScreenUtil units
/// (`150.h`); it is scaled by how much wider the columns became, so a tile
/// does not turn into a letterbox on a desktop grid.
class DuaTileGrid extends StatelessWidget {
  const DuaTileGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.tileExtent,
    this.spacing,
    this.runSpacing,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double tileExtent;
  final double? spacing;
  final double? runSpacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = DuaLayout.columns(constraints.maxWidth);
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          // The tile is a fixed height holding text that grew on the
          // browser, so the height grows by the same factor; otherwise the
          // bigger title overflowed the box it was written for.
          mainAxisExtent: duaScaledExtent(context, tileExtent),
          crossAxisSpacing: spacing ?? 12,
          mainAxisSpacing: runSpacing ?? 12,
        ),
        itemBuilder: itemBuilder,
      );
    },
  );
}

/// Page padding that keeps a scroll view's content to [maxWidth] by growing
/// the side gutters instead of the content.
///
/// For a long `ListView` whose `children` cannot practically be wrapped in a
/// [DuaContentColumn] - a tab body built in pieces, say - this gives the same
/// centred, capped column with a one-line change at the padding. The content
/// keeps the gutters it had on a phone, and only a window wider than
/// [maxWidth] adds to them.
EdgeInsets duaPagePadding(
  BuildContext context, {
  double left = 0,
  double top = 0,
  double right = 0,
  double bottom = 0,
  double? maxWidth,
}) {
  final width = MediaQuery.of(context).size.width;
  final cap = maxWidth ?? DuaLayout.maxContent;
  final gutter = width > cap ? (width - cap) / 2 : 0.0;
  return EdgeInsets.fromLTRB(left + gutter, top, right + gutter, bottom);
}

/// Grows a Dua page's type on the browser, and with it the fixed boxes that
/// hold that type.
///
/// ScreenUtil does not scale anything on Web (`enableScaleWH` /
/// `enableScaleText` in `main_app.dart`), by design: a Dua route reflows its
/// widgets against the real window width instead of magnifying a phone
/// canvas. The side effect was that type written as `13.sp` stayed 13 raw
/// pixels however large the window got. This puts the proportion back:
/// [DuaLayout.textScale] for the window's width, applied through the
/// [MediaQuery] text scaler so every `.sp` size in the subtree follows at
/// once, and nothing in a page has to be rewritten.
///
/// The reader's own font-size preference (`appFontScale`, set above the
/// route in `main_app.dart`) is multiplied, never replaced, so the setting
/// still does what it did.
///
/// Wrapped around a route's child for every Dua route, and around the Dua
/// sheets and dialogs as well: a modal is its own route, mounted above the
/// page's wrapper, so it would otherwise keep phone-sized type beside a
/// page that had grown.
///
/// On Android and iOS this is inert - [enabled] defaults to [kIsWeb] - and
/// below [DuaLayout.wide] it leaves the window alone even on the browser.
class DuaWebTypography extends StatelessWidget {
  const DuaWebTypography({super.key, required this.child, this.enabled});

  final Widget child;

  /// Defaults to [kIsWeb]. Only a test passes this, to lay a screen out as
  /// the browser would.
  final bool? enabled;

  @override
  Widget build(BuildContext context) {
    if (!(enabled ?? kIsWeb)) return child;

    final media = MediaQuery.of(context);
    final scale = DuaLayout.textScale(media.size.width);
    if (scale == 1) return child;

    // The scaler already in force is linear (`TextScaler.linear` on the
    // reader's font-size preference), so scaling our factor through it
    // gives the combined factor: preference x window step.
    final combined = media.textScaler.scale(scale);
    return DuaTypeScale(
      scale: scale,
      child: MediaQuery(
        data: media.copyWith(textScaler: TextScaler.linear(combined)),
        child: child,
      ),
    );
  }
}

/// The factor [DuaWebTypography] grew this subtree's type by.
///
/// A box with a fixed height - a grid tile, a chart - reads this to grow
/// with the text inside it. The repository's existing answer to the same
/// problem is to write such a height in `.w` rather than `.h`, because
/// ScreenUtil scales width and text together but not height; on the browser
/// no ScreenUtil unit scales at all, so the factor has to be asked for.
class DuaTypeScale extends InheritedWidget {
  const DuaTypeScale({super.key, required this.scale, required super.child});

  final double scale;

  /// 1.0 when there is no [DuaWebTypography] above [context] - a phone, or
  /// a browser window still at phone width.
  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DuaTypeScale>()?.scale ?? 1.0;

  @override
  bool updateShouldNotify(DuaTypeScale oldWidget) => oldWidget.scale != scale;
}

/// [extent] grown by the factor this subtree's type was grown by.
///
/// For a height or width that was measured around text and cannot flex: a
/// grid's `mainAxisExtent`, a chart's box, a card in a horizontal row. On a
/// phone, and on a phone-width browser window, it returns [extent] itself.
double duaScaledExtent(BuildContext context, double extent) =>
    extent * DuaTypeScale.of(context);
