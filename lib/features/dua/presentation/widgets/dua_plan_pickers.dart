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

/// Bottom sheet listing one category's duas (`GET /duas?categoryId=...`), via
/// [DuaCategoryDuasCubit] — multi-select (design change: a plan can hold
/// several duas from the same category at once). Closes with every
/// [DuaFeaturedModel] checked, once "Done" is tapped.
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
    child: _DuaMultiSelectBody(
      category: category,
      initialSelectedIds: initialSelectedIds,
    ),
  );
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
