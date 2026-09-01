import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/zikr/data/zikr_catalog.dart';

/// "Create plan" screen (designs `devImg/img_23.png` and `devImg/img_24.png`),
/// reached from the "Create Plan" button on [ZikrPlannerScreen].
///
/// UI only. Fill the plan name + completion days, add one or more zikr with a
/// reading value, then "Create" (which just returns to the planner).
class ZikrPlanCreateScreen extends StatefulWidget {
  const ZikrPlanCreateScreen({super.key});

  @override
  State<ZikrPlanCreateScreen> createState() => _ZikrPlanCreateScreenState();
}

class _ZikrPlanCreateScreenState extends State<ZikrPlanCreateScreen> {
  static const _customValue = '__custom__';

  final _fieldKey = GlobalKey();
  final _nameController = TextEditingController();
  final _daysController = TextEditingController();
  final _valueController = TextEditingController();

  final List<ZikrPlanEntry> _entries = [];
  String? _zikrName;
  bool _adding = true;

  late AppText _appText;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appText = AppText.of(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _daysController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  String get _planName => _nameController.text.trim().isEmpty
      ? 'Plan 1'
      : _nameController.text.trim();
  int get _planDays => int.tryParse(_daysController.text.trim()) ?? 30;

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  Future<void> _openDropdown() async {
    FocusScope.of(context).unfocus();
    final fieldBox = _fieldKey.currentContext!.findRenderObject() as RenderBox;
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        fieldBox.localToGlobal(Offset.zero, ancestor: overlayBox),
        fieldBox.localToGlobal(
          fieldBox.size.bottomRight(Offset.zero),
          ancestor: overlayBox,
        ),
      ),
      Offset.zero & overlayBox.size,
    );

    final result = await showMenu<String>(
      context: context,
      position: position,
      color: Colors.white,
      constraints: BoxConstraints(
        minWidth: fieldBox.size.width,
        maxWidth: fieldBox.size.width,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      items: [
        for (var i = 0; i < ZikrCatalog.dropdownItems.length; i++) ...[
          if (i > 0) const PopupMenuDivider(height: 1),
          PopupMenuItem<String>(
            value: ZikrCatalog.dropdownItems[i].name,
            child: Text(
              ZikrCatalog.dropdownItems[i].name,
              style: TextStyle(fontSize: 13.sp, color: const Color(0xFF2C3320)),
            ),
          ),
        ],
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: _customValue,
          child: Text(
            _appText.zikrCustom,
            style: TextStyle(fontSize: 13.sp, color: const Color(0xFF2C3320)),
          ),
        ),
      ],
    );

    if (result == null || !mounted) return;
    if (result == _customValue) {
      final name = await _askCustomName();
      if (name != null && name.isNotEmpty) setState(() => _zikrName = name);
      return;
    }
    setState(() => _zikrName = result);
  }

  Future<String?> _askCustomName() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          _appText.zikrCustom,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: _appText.zikrWriteZikrNameHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_appText.zikrCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: AppColor.primary),
            child: Text(_appText.zikrCreateAdd),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  void _add() {
    final name = _zikrName;
    if (name == null || name.isEmpty) {
      _toast(_appText.zikrSelectZikr);
      return;
    }
    final value = int.tryParse(_valueController.text.trim());
    HapticFeedback.selectionClick();
    setState(() {
      _entries.add(
        ZikrPlanEntry(
          name: name,
          value: (value == null || value < 1) ? 33 : value,
        ),
      );
      _zikrName = null;
      _valueController.clear();
      _adding = false;
    });
  }

  void _addMore() {
    setState(() => _adding = true);
  }

  void _create() {
    if (_entries.isEmpty) {
      _toast(_appText.zikrSelectZikr);
      return;
    }
    HapticFeedback.selectionClick();
    _toast(_appText.zikrCreated);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final appText = _appText;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 6.h),
            SizedBox(
              height: 44.h,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 12.w),
                      child: IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFCBD16B),
                          foregroundColor: const Color(0xFF303629),
                          minimumSize: Size(38.r, 38.r),
                        ),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    appText.zikrPlanCreateTitle,
                    style: TextStyle(
                      color: AppColor.authLogo,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _adding ? _buildForm(appText) : _buildSummary(appText),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 14.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 54.h,
                  child: FilledButton(
                    onPressed: _create,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28.r),
                      ),
                    ),
                    child: Text(
                      appText.zikrCreate,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(AppText appText) {
    return ListView(
      padding: EdgeInsets.fromLTRB(22.w, 18.h, 22.w, 20.h),
      children: [
        _Label(appText.zikrPlanName),
        SizedBox(height: 8.h),
        _RoundedField(
          controller: _nameController,
          hint: appText.zikrPlanWriteHere,
          textCapitalization: TextCapitalization.words,
        ),
        SizedBox(height: 16.h),
        _Label(appText.zikrPlanCompletionDays),
        SizedBox(height: 8.h),
        _RoundedField(
          controller: _daysController,
          hint: appText.zikrPlanWriteHere,
          keyboardType: TextInputType.number,
          digitsOnly: true,
        ),
        SizedBox(height: 20.h),
        Container(
          padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 18.h),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFCBB94F)),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Label(appText.zikrSelectZikr, big: true),
              SizedBox(height: 10.h),
              InkWell(
                key: _fieldKey,
                onTap: _openDropdown,
                borderRadius: BorderRadius.circular(26.r),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 18.w,
                    vertical: 15.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26.r),
                    border: Border.all(color: const Color(0xFFDDE3C6)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _zikrName ?? appText.zikrSelectZikr,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontStyle: _zikrName == null
                                ? FontStyle.italic
                                : FontStyle.normal,
                            color: _zikrName == null
                                ? const Color(0xFFA9B08D)
                                : const Color(0xFF2C3320),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20.sp,
                        color: const Color(0xFF9BA85B),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              _Label(appText.zikrSetReadingValue, big: true),
              SizedBox(height: 10.h),
              _RoundedField(
                controller: _valueController,
                hint: appText.zikrReadingValueHint,
                keyboardType: TextInputType.number,
                digitsOnly: true,
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton(
            onPressed: _add,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8C7A1F),
              side: const BorderSide(color: Color(0xFFCBB94F)),
              padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22.r),
              ),
            ),
            child: Text(
              appText.zikrCreateAdd,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(AppText appText) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
      children: [
        Text(
          '$_planName  ( $_planDays ${appText.zikrPlanDays} )',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2C3320),
          ),
        ),
        SizedBox(height: 14.h),
        for (final entry in _entries) ...[
          _PlanEntryRow(entry: entry),
          SizedBox(height: 12.h),
        ],
        SizedBox(height: 2.h),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton(
            onPressed: _addMore,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8C7A1F),
              side: const BorderSide(color: Color(0xFFCBB94F)),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22.r),
              ),
            ),
            child: Text(
              appText.zikrAddMore,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.big = false});

  final String text;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: big ? 15.sp : 13.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF2C3320),
      ),
    );
  }
}

class _RoundedField extends StatelessWidget {
  const _RoundedField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.digitsOnly = false,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool digitsOnly;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: digitsOnly
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      style: TextStyle(fontSize: 13.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontStyle: FontStyle.italic,
          color: const Color(0xFFA9B08D),
          fontSize: 12.sp,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 15.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26.r),
          borderSide: const BorderSide(color: Color(0xFFDDE3C6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26.r),
          borderSide: const BorderSide(color: AppColor.primary),
        ),
      ),
    );
  }
}

class _PlanEntryRow extends StatelessWidget {
  const _PlanEntryRow({required this.entry});

  final ZikrPlanEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDDE3C6)),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        children: [
          Container(
            width: 34.r,
            height: 34.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFCBD9AF)),
            ),
            child: Icon(
              Icons.self_improvement_rounded,
              size: 18.sp,
              color: const Color(0xFF6E8B3D),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3D3170),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${entry.value}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF9AA579),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
