import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_category.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_library_book.dart';
import 'package:islami_app_noorify/features/hadith/domain/repositories/hadith_library_repository.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_categories.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_library_books.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_category/hadith_category_bloc.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_library/hadith_library_bloc.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_list_scaffold.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

/// A hadith book's title in the app language, falling back to the other one.
String hadithBookTitle(HadithLibraryBook book, {required bool bangla}) {
  final preferred = bangla ? book.titleBn : book.titleEn;
  return preferred.isNotEmpty
      ? preferred
      : (bangla ? book.titleEn : book.titleBn);
}

/// A category's name in the app language, falling back to the other one.
String hadithCategoryTitle(HadithCategory category, {required bool bangla}) {
  final preferred = bangla ? category.nameBangla : category.name;
  if (preferred.isNotEmpty) return preferred;
  return bangla ? category.name : category.nameBangla;
}

bool _isBangla(BuildContext context) =>
    context.watch<LanguageBloc>().state.language == AppLanguage.bangla;

/// Bottom sheet listing the hadith books (`GET /hadiths/books/lists`). Closes
/// with the [HadithLibraryBook] the user taps.
class HadithBookPickerSheet extends StatelessWidget {
  const HadithBookPickerSheet({
    super.key,
    required this.repository,
    this.selectedId,
  });

  final HadithLibraryRepository repository;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return BlocProvider(
      create: (_) =>
          HadithLibraryBloc(GetHadithLibraryBooks(repository))
            ..add(const LoadHadithLibrary()),
      child: _PickerFrame(
        title: appText.selectHadithBook,
        child: _BookList(selectedId: selectedId),
      ),
    );
  }
}

class _BookList extends StatelessWidget {
  const _BookList({required this.selectedId});

  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bangla = _isBangla(context);
    final state = context.watch<HadithLibraryBloc>().state;

    if (state.isLoading) return const _PickerLoading();
    if (state.status == HadithLibraryStatus.failure) {
      return _PickerMessage(
        message: state.failure?.message ?? '',
        actionLabel: appText.tryAgain,
        onAction: () =>
            context.read<HadithLibraryBloc>().add(const LoadHadithLibrary()),
      );
    }
    if (state.books.isEmpty) {
      return _PickerMessage(message: appText.hadithBookComingSoon);
    }
    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
      itemCount: state.books.length,
      separatorBuilder: (_, _) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        final book = state.books[index];
        return _PickerTile(
          title: hadithBookTitle(book, bangla: bangla),
          subtitle:
              '${formatHadithCount(book.totalHadiths)} ${appText.categoryHadith}',
          selected: book.id == selectedId,
          onTap: () => Navigator.of(context).pop(book),
        );
      },
    );
  }
}

/// Bottom sheet listing the categories of one book
/// (`GET /hadiths/categories?bookId=...`), 10 at a time as it is scrolled.
/// Closes with the [HadithCategory] the user taps.
class HadithCategoryPickerSheet extends StatelessWidget {
  const HadithCategoryPickerSheet({
    super.key,
    required this.repository,
    required this.bookId,
    this.selectedId,
  });

  final HadithLibraryRepository repository;
  final String bookId;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return BlocProvider(
      create: (_) =>
          HadithCategoryBloc(GetHadithCategories(repository))
            ..add(LoadHadithCategories(bookId)),
      child: _PickerFrame(
        title: appText.selectCategory,
        child: _CategoryList(bookId: bookId, selectedId: selectedId),
      ),
    );
  }
}

class _CategoryList extends StatefulWidget {
  const _CategoryList({required this.bookId, required this.selectedId});

  final String bookId;
  final String? selectedId;

  @override
  State<_CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<_CategoryList> {
  static const _loadMoreThreshold = 200.0;

  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _controller.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      // The bloc ignores this while a page is loading or after the last one.
      context.read<HadithCategoryBloc>().add(const LoadMoreHadithCategories());
    }
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bangla = _isBangla(context);
    final state = context.watch<HadithCategoryBloc>().state;

    if (state.isLoading) return const _PickerLoading();
    if (state.status == HadithCategoryStatus.failure) {
      return _PickerMessage(
        message: state.failure?.message ?? '',
        actionLabel: appText.tryAgain,
        onAction: () => context.read<HadithCategoryBloc>().add(
          LoadHadithCategories(widget.bookId),
        ),
      );
    }
    if (state.categories.isEmpty) {
      return _PickerMessage(message: appText.noResultsFound);
    }

    // A first page too short to scroll would never fire the scroll listener,
    // so keep pulling pages until the list overflows (or runs out).
    if (state.hasMore &&
        !state.isLoadingMore &&
        state.loadMoreFailure == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients) return;
        if (_controller.position.maxScrollExtent <= 0) {
          context.read<HadithCategoryBloc>().add(
            const LoadMoreHadithCategories(),
          );
        }
      });
    }

    final showFooter = state.isLoadingMore || state.loadMoreFailure != null;
    return ListView.separated(
      controller: _controller,
      shrinkWrap: true,
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
      itemCount: state.categories.length + (showFooter ? 1 : 0),
      separatorBuilder: (_, _) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        if (index >= state.categories.length) {
          return state.isLoadingMore
              ? const _PickerLoading()
              : _PickerMessage(
                  message: state.loadMoreFailure!.message,
                  actionLabel: appText.tryAgain,
                  onAction: () => context.read<HadithCategoryBloc>().add(
                    const LoadMoreHadithCategories(),
                  ),
                );
        }
        final category = state.categories[index];
        return _PickerTile(
          title: hadithCategoryTitle(category, bangla: bangla),
          subtitle:
              '${formatHadithCount(category.totalHadiths)} ${appText.categoryHadith}',
          selected: category.id == widget.selectedId,
          onTap: () => Navigator.of(context).pop(category),
        );
      },
    );
  }
}

/// The rounded sheet around a picker: a grab handle, a title and the list.
class _PickerFrame extends StatelessWidget {
  const _PickerFrame({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * .7,
      ),
      decoration: BoxDecoration(
        color: context.pageColor(Colors.white),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.surfaceColor(const Color(0xFFDCE3C4)),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              title,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12.h),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: context.surfaceColor(
            selected ? const Color(0xFFEDF3D6) : Colors.white,
          ),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: context.lineColor(
              selected ? const Color(0xFFA1AD59) : const Color(0xFFE3E7D3),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: context.inkColor(const Color(0xFF2C3320)),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF9BA85B),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                size: 20.sp,
                color: const Color(0xFFA1AD59),
              ),
          ],
        ),
      ),
    );
  }
}

class _PickerLoading extends StatelessWidget {
  const _PickerLoading();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 28.h),
    child: const Center(child: CircularProgressIndicator()),
  );
}

class _PickerMessage extends StatelessWidget {
  const _PickerMessage({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: context.inkColor(const Color(0xFF5D6B44)),
            ),
          ),
          if (onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel ?? '')),
        ],
      ),
    );
  }
}
