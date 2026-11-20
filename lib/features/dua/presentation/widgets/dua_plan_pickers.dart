import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/dua_dependencies.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/bloc/dua_category_duas_cubit.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/bloc/dua_home_cubit.dart';

/// Bottom sheet listing the Dua categories (`GET /duas/categories`), reused
/// from [DuaHomeCubit] the same way [DuaAllCategoryScreen] does. Closes with
/// the [DuaCategoryModel] the user taps.
class DuaCategoryPickerSheet extends StatelessWidget {
  const DuaCategoryPickerSheet({super.key, this.selectedId});

  final String? selectedId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => DuaHomeCubit(duaRepository)..load(),
    child: _PickerFrame(
      title: AppText.of(context).selectCategory,
      child: _CategoryList(selectedId: selectedId),
    ),
  );
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.selectedId});
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final state = context.watch<DuaHomeCubit>().state;

    if (state.status == DuaLoadStatus.loading ||
        state.status == DuaLoadStatus.initial) {
      return const _PickerLoading();
    }
    if (state.status == DuaLoadStatus.failure) {
      return _PickerMessage(
        message: state.error ?? '',
        actionLabel: appText.tryAgain,
        onAction: () => context.read<DuaHomeCubit>().load(),
      );
    }
    if (state.categories.isEmpty) {
      return _PickerMessage(message: appText.noResultsFound);
    }
    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
      itemCount: state.categories.length,
      separatorBuilder: (_, _) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        final category = state.categories[index];
        return _PickerTile(
          title: context.localized(category.name),
          subtitle: appText.duaSavedCount.replaceAll(
            '{n}',
            context.localizedDigits('${category.totalDuasCount}'),
          ),
          selected: category.id == selectedId,
          onTap: () => Navigator.of(context).pop(category),
        );
      },
    );
  }
}

/// Compact Select Dua picker (`devImg/img_27.png`) for one category's duas.
/// Its expand action opens [DuaPlanDuaPickerScreen] (`devImg/img_28.png`).
/// Both return the selected duas for Create Plan.
class DuaItemPickerSheet extends StatelessWidget {
  const DuaItemPickerSheet({
    super.key,
    required this.category,
    this.initialSelectedIds = const {},
  });

  final DuaCategoryModel category;
  final Set<String> initialSelectedIds;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => DuaCategoryDuasCubit(duaRepository)..load(category),
    child: _DuaCompactPicker(
      category: category,
      initialSelectedIds: initialSelectedIds,
    ),
  );
}

/// Full-screen Dua picker used by the expand action in [DuaItemPickerSheet].
/// It follows the Select Dua design (`devImg/img_28.png`) and returns the
/// selected duas, keeping the Create Plan result contract.
class DuaPlanDuaPickerScreen extends StatelessWidget {
  const DuaPlanDuaPickerScreen({
    super.key,
    required this.category,
    this.initialSelectedIds = const {},
  });

  final DuaCategoryModel category;
  final Set<String> initialSelectedIds;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => DuaCategoryDuasCubit(duaRepository)..load(category),
    child: Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: _DuaPickerBody(
          category: category,
          initialSelectedIds: initialSelectedIds,
          fullScreen: true,
        ),
      ),
    ),
  );
}

/// Inline Select Dua dropdown for the Create Plan form. Unlike
/// [DuaItemPickerSheet], it does not create a dialog or modal route.
class DuaPlanDuaDropdown extends StatelessWidget {
  const DuaPlanDuaDropdown({
    super.key,
    required this.category,
    required this.selectedIds,
    required this.onSelected,
  });

  final DuaCategoryModel category;
  final Set<String> selectedIds;
  final ValueChanged<DuaFeaturedModel> onSelected;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => DuaCategoryDuasCubit(duaRepository)..load(category),
    child: _DuaPickerBody(
      category: category,
      initialSelectedIds: selectedIds,
      fullScreen: false,
      showTitle: false,
      showSearch: false,
      showExpandAction: false,
      onSelected: onSelected,
    ),
  );
}

class _DuaCompactPicker extends StatelessWidget {
  const _DuaCompactPicker({
    required this.category,
    required this.initialSelectedIds,
  });

  final DuaCategoryModel category;
  final Set<String> initialSelectedIds;

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * .58,
    ),
    decoration: BoxDecoration(
      color: context.pageColor(Colors.white),
      borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
    ),
    child: SafeArea(
      top: false,
      child: _DuaPickerBody(
        category: category,
        initialSelectedIds: initialSelectedIds,
        fullScreen: false,
      ),
    ),
  );
}

class _DuaPickerBody extends StatefulWidget {
  const _DuaPickerBody({
    required this.category,
    required this.initialSelectedIds,
    required this.fullScreen,
    this.showTitle = true,
    this.showSearch = true,
    this.showExpandAction = true,
    this.onSelected,
  });

  final DuaCategoryModel category;
  final Set<String> initialSelectedIds;
  final bool fullScreen;
  final bool showTitle;
  final bool showSearch;
  final bool showExpandAction;
  final ValueChanged<DuaFeaturedModel>? onSelected;

  @override
  State<_DuaPickerBody> createState() => _DuaPickerBodyState();
}

class _DuaPickerBodyState extends State<_DuaPickerBody> {
  String _query = '';
  late final Set<String> _selectedIds = Set.of(widget.initialSelectedIds);

  Future<void> _openFullScreen() async {
    final result = await Navigator.of(context).push<List<DuaFeaturedModel>>(
      MaterialPageRoute(
        builder: (_) => DuaPlanDuaPickerScreen(
          category: widget.category,
          initialSelectedIds: widget.initialSelectedIds,
        ),
      ),
    );
    if (result != null && mounted) Navigator.of(context).pop(result);
  }

  void _select(DuaFeaturedModel dua) {
    final onSelected = widget.onSelected;
    if (onSelected != null) {
      onSelected(dua);
    } else if (widget.fullScreen) {
      setState(() {
        if (!_selectedIds.remove(dua.id)) _selectedIds.add(dua.id);
      });
    } else {
      Navigator.of(context).pop([dua]);
    }
  }

  void _done(List<DuaFeaturedModel> availableDuas) =>
      Navigator.of(context).pop([
        for (final dua in availableDuas)
          if (_selectedIds.contains(dua.id)) dua,
      ]);

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final state = context.watch<DuaCategoryDuasCubit>().state;
    final title = widget.fullScreen
        ? context.localized(
            const LocalizedText(en: 'Select Dua', bn: 'দোয়া বাছাই করুন'),
          )
        : appText.selectDua;

    if (state.status == DuaCategoryDuasStatus.initial ||
        state.status == DuaCategoryDuasStatus.loading) {
      return const _PickerLoading();
    }
    if (state.status == DuaCategoryDuasStatus.failure) {
      return _PickerMessage(
        message: state.error ?? '',
        actionLabel: appText.tryAgain,
        onAction: () =>
            context.read<DuaCategoryDuasCubit>().load(widget.category),
      );
    }

    final query = _query.toLowerCase();
    final duas = [
      for (final dua in state.duas)
        if (query.isEmpty ||
            context.localized(dua.title).toLowerCase().contains(query) ||
            context.localized(dua.translation).toLowerCase().contains(query))
          dua,
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16.w,
        widget.fullScreen ? 8.h : 16.h,
        16.w,
        16.h,
      ),
      child: Column(
        children: [
          if (widget.fullScreen)
            _FullPickerHeader(title: title)
          else if (widget.showTitle)
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: context.textInkColor(const Color(0xFF222222)),
                    ),
                  ),
                ),
                if (widget.showExpandAction)
                  IconButton(
                    onPressed: _openFullScreen,
                    style: IconButton.styleFrom(
                      backgroundColor: context.surfaceColor(
                        const Color(0xFFF3F7E7),
                      ),
                    ),
                    icon: Icon(
                      Icons.open_in_new_rounded,
                      color: context.inkColor(const Color(0xFFA7B45B)),
                      size: 18.sp,
                    ),
                  ),
              ],
            ),
          if (widget.fullScreen)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(top: 14.h, bottom: 12.h),
                child: Text(
                  context.localizedDigits('Total Dua ( ${state.duas.length} )'),
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: context.textInkColor(const Color(0xFF222222)),
                  ),
                ),
              ),
            )
          else if (widget.showTitle)
            SizedBox(height: 8.h),
          if (widget.showSearch) ...[
            TextField(
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                hintText: widget.fullScreen ? 'Search Dua' : 'Search here',
                hintStyle: TextStyle(
                  fontSize: 12.sp,
                  fontStyle: FontStyle.italic,
                  color: context.textInkColor(const Color(0xFF9B9B9B)),
                ),
                suffixIcon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: context.inkColor(const Color(0xFFA7B45B)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 14.w),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26.r),
                  borderSide: BorderSide(
                    color: context.lineColor(const Color(0xFFD7E7A4)),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26.r),
                  borderSide: BorderSide(
                    color: context.lineColor(const Color(0xFFA7B45B)),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
          ],
          Expanded(
            child: duas.isEmpty
                ? Center(child: Text(appText.noResultsFound))
                : ListView.separated(
                    itemCount: duas.length,
                    separatorBuilder: (_, _) => SizedBox(height: 8.h),
                    itemBuilder: (context, index) => _PlanDuaTile(
                      dua: duas[index],
                      index: index,
                      selected: widget.fullScreen
                          ? _selectedIds.contains(duas[index].id)
                          : widget.initialSelectedIds.contains(duas[index].id),
                      onTap: () => _select(duas[index]),
                    ),
                  ),
          ),
          if (widget.fullScreen) ...[
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: FilledButton(
                onPressed: () => _done(state.duas),
                style: FilledButton.styleFrom(
                  backgroundColor: context.surfaceColor(
                    const Color(0xFFA7B45B),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                ),
                child: Text(
                  '${appText.commonDone} (${context.localizedDigits('${_selectedIds.length}')})',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FullPickerHeader extends StatelessWidget {
  const _FullPickerHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48.h,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: IconButton.styleFrom(
              backgroundColor: context.surfaceColor(const Color(0xFFDFDE68)),
              foregroundColor: context.inkColor(const Color(0xFF303629)),
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 24.sp,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w700,
            color: context.textInkColor(const Color(0xFFA7B45B)),
          ),
        ),
      ],
    ),
  );
}

class _PlanDuaTile extends StatelessWidget {
  const _PlanDuaTile({
    required this.dua,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final DuaFeaturedModel dua;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  static const _colors = [
    Color(0xFFFAD8E7),
    Color(0xFFFFE9AA),
    Color(0xFFD2F5B8),
    Color(0xFFC8E9F9),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[index % _colors.length];
    final subtitle = context.localized(dua.translation);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21.r),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: context.surfaceColor(color),
            borderRadius: BorderRadius.circular(21.r),
            border: selected
                ? Border.all(
                    color: context.lineColor(const Color(0xFFA7B45B)),
                    width: 1.5,
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 43.r,
                height: 43.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.surfaceColor(Colors.white),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  context.localizedDigits('${index + 1}'),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: context.textInkColor(const Color(0xFF9AA957)),
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.localized(dua.title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 16.sp,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w700,
                        color: context.textInkColor(const Color(0xFF293021)),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle.isEmpty ? '—' : subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: context.textInkColor(const Color(0xFF777777)),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 30.r,
                height: 30.r,
                decoration: BoxDecoration(
                  color: context.surfaceColor(
                    Colors.white.withValues(alpha: .45),
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.lineColor(const Color(0xFF9AA957)),
                  ),
                ),
                child: Icon(
                  selected ? Icons.check_rounded : Icons.chevron_right_rounded,
                  size: 19.sp,
                  color: context.inkColor(const Color(0xFF758437)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DuaMultiSelectBody extends StatefulWidget {
  const _DuaMultiSelectBody({
    required this.category,
    required this.initialSelectedIds,
  });

  final DuaCategoryModel category;
  final Set<String> initialSelectedIds;

  @override
  State<_DuaMultiSelectBody> createState() => _DuaMultiSelectBodyState();
}

class _DuaMultiSelectBodyState extends State<_DuaMultiSelectBody> {
  late final Set<String> _selected = Set.of(widget.initialSelectedIds);

  void _toggle(String id) => setState(() {
    if (!_selected.remove(id)) _selected.add(id);
  });

  void _done() {
    final duas = context
        .read<DuaCategoryDuasCubit>()
        .state
        .duas
        .where((dua) => _selected.contains(dua.id))
        .toList(growable: false);
    Navigator.of(context).pop(duas);
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return _PickerFrame(
      title: appText.selectDua,
      footer: SizedBox(
        width: double.infinity,
        height: 46.h,
        child: FilledButton(
          onPressed: _selected.isEmpty ? null : _done,
          style: FilledButton.styleFrom(
            backgroundColor: AppColor.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: context.surfaceColor(
              const Color(0xFFE3E7D3),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22.r),
            ),
          ),
          child: Text(
            _selected.isEmpty
                ? appText.commonDone
                : '${appText.commonDone} (${context.localizedDigits('${_selected.length}')})',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      child: _DuaList(
        category: widget.category,
        selectedIds: _selected,
        onToggle: _toggle,
      ),
    );
  }
}

class _DuaList extends StatelessWidget {
  const _DuaList({
    required this.category,
    required this.selectedIds,
    required this.onToggle,
  });

  final DuaCategoryModel category;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final state = context.watch<DuaCategoryDuasCubit>().state;

    if (state.status == DuaCategoryDuasStatus.initial ||
        state.status == DuaCategoryDuasStatus.loading) {
      return const _PickerLoading();
    }
    if (state.status == DuaCategoryDuasStatus.failure) {
      return _PickerMessage(
        message: state.error ?? '',
        actionLabel: appText.tryAgain,
        onAction: () => context.read<DuaCategoryDuasCubit>().load(category),
      );
    }
    if (state.duas.isEmpty) {
      return _PickerMessage(message: appText.noResultsFound);
    }
    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
      itemCount: state.duas.length,
      separatorBuilder: (_, _) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        final dua = state.duas[index];
        return _PickerTile(
          title: context.localized(dua.title),
          selected: selectedIds.contains(dua.id),
          onTap: () => onToggle(dua.id),
        );
      },
    );
  }
}

/// The rounded sheet around a picker: a grab handle, a title, the list and
/// an optional sticky [footer] (e.g. a multi-select "Done" button).
class _PickerFrame extends StatelessWidget {
  const _PickerFrame({required this.title, required this.child, this.footer});

  final String title;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => Container(
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
          if (footer != null)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
              child: footer,
            ),
        ],
      ),
    ),
  );
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: context.surfaceColor(
          selected ? const Color(0xFFEEF2DC) : Colors.white,
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: context.lineColor(
            selected ? AppColor.primary : const Color(0xFFD5E59B),
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
                if (subtitle != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFFA5B657),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            selected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 20.sp,
            color: selected ? AppColor.primary : const Color(0xFFD5E59B),
          ),
        ],
      ),
    ),
  );
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
  Widget build(BuildContext context) => Padding(
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
