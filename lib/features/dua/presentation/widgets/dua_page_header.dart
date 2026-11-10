import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Back button + centered title row shared by the Dua dashboard, All
/// Category, and Featured Dua screens (design `img_1.png` / `img_2.png` /
/// `img_3.png`).
class DuaPageHeader extends StatelessWidget {
  const DuaPageHeader({
    super.key,
    required this.title,
    this.action,
    this.onBack,
    this.titleBesideBack = false,
    this.maxTitleChars,
  });

  final String title;
  final Widget? action;

  /// Called instead of the default `Navigator.maybePop` — e.g. the Dua
  /// dashboard sends the user to the app's main Home screen instead of
  /// popping within the Dua feature's own stack.
  final VoidCallback? onBack;

  /// Puts the title right next to the back button instead of centering it
  /// in the row — for a screen whose action icons leave no room in the
  /// middle (the Dua reader).
  final bool titleBesideBack;

  /// Caps the title at this many characters; the rest becomes an ellipsis.
  /// Counted in grapheme clusters, so a Bangla conjunct is one character
  /// and is never cut in half.
  final int? maxTitleChars;

  /// [title], cut to [maxTitleChars] when it is longer than that.
  String get _displayTitle {
    final limit = maxTitleChars;
    if (limit == null) return title;
    final letters = title.characters;
    if (letters.length <= limit) return title;
    return '${letters.take(limit).toString().trimRight()}…';
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontSize: 19.sp,
      fontWeight: FontWeight.w600,
      fontStyle: FontStyle.italic,
    );
    final backButton = IconButton(
      onPressed: onBack ?? () => Navigator.maybePop(context),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFFDFDE68),
        foregroundColor: const Color(0xFF303629),
        minimumSize: Size(38.r, 38.r),
      ),
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
    );

    return SizedBox(
      height: 44.h,
      child: titleBesideBack
          ? Row(
              children: [
                backButton,
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    _displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                ),
                ?action,
              ],
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                Align(alignment: Alignment.centerLeft, child: backButton),
                Text(_displayTitle, style: titleStyle),
                if (action != null)
                  Align(alignment: Alignment.centerRight, child: action!),
              ],
            ),
    );
  }
}
