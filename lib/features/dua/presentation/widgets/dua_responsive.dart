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
/// design-size scaling does not follow it. Spacing and type inside a page
/// still use ScreenUtil, exactly as on the phone.
abstract final class DuaLayout {
  /// Below this a page stays the single phone-like column it already was;
  /// at or above it a page may spread into the room a browser gives it.
  static const wide = 720.0;

  /// A second step, for a maximised desktop window: grids gain one more
  /// column here.
  static const extraWide = 1040.0;

  /// Past this the content stops widening and the window grows around it.
  /// A line of text stretched across 2000px is unreadable.
  static const maxContent = 1100.0;

  /// A reading column is capped tighter than [maxContent]. Dua Arabic,
  /// transliteration and translation are read line by line, and the eye
  /// loses its place on a line much wider than this.
  static const maxReading = 820.0;

  /// The floating olive nav pill is sized for a phone. Left to itself it
  /// would stretch the full width of a desktop window, so it keeps to this.
  static const maxNav = 560.0;

  /// A form or sheet column - plan create, folder naming - that looks
  /// stretched and empty at full content width.
  static const maxForm = 680.0;

  /// `true` when [width] has room for a wide layout.
  static bool isWide(double width) => width >= wide;

  /// `true` when [width] has room for the widest layout.
  static bool isExtraWide(double width) => width >= extraWide;

  /// Tiles across a card grid at [width]: the phone's two, three on a
  /// tablet or small browser window, four on a desktop one.
  static int columns(double width) {
    if (width >= extraWide) return 4;
    if (width >= wide) return 3;
    return 2;
  }

  /// Columns for a list of wide cards (featured duas, saved folders, plans),
  /// which need far more room each than a category tile.
  static int listColumns(double width) => width >= wide ? 2 : 1;
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
          mainAxisExtent: tileExtent,
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
