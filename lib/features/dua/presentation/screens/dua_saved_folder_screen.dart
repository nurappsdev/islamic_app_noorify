import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/dua/data/dua_bookmark_store.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/dua_route_args.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_item_tile.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_page_header.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';

/// The duas saved under one folder, reached by tapping a folder card on
/// [DuaSavedScreen]. Live view of [DuaBookmarkStore] — a dua removed or
/// reassigned to another folder elsewhere disappears from this list too.
class DuaSavedFolderScreen extends StatelessWidget {
  const DuaSavedFolderScreen({super.key, required this.folder});

  final String folder;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final store = DuaBookmarkStore.instance;
    final title = folder == DuaBookmarkStore.defaultFolder
        ? appText.favoriteFolder
        : folder;

    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final items = store.itemsIn(folder);
            return ListView(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
              children: [
                SizedBox(height: 6.h),
                DuaPageHeader(title: title),
                SizedBox(height: 16.h),
                if (items.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 40.h),
                    child: Text(
                      appText.noResultsFound,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: context.inkColor(Color(0xFF5D6B44)),
                      ),
                    ),
                  )
                else
                  for (var i = 0; i < items.length; i++) ...[
                    DuaItemTile(
                      index: i,
                      name: context.localized(
                        LocalizedText(
                          bn: items[i].titleBn,
                          en: items[i].titleEn,
                        ),
                      ),
                      onTap: () => Navigator.of(context).pushNamed(
                        RouteNames.duaReader,
                        arguments: DuaReaderArgs.real(
                          items[i].toFeaturedModel(),
                        ),
                      ),
                    ),
                    if (i != items.length - 1) SizedBox(height: 10.h),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}
