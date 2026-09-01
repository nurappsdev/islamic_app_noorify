import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/zikr/data/zikr_catalog.dart';
import 'package:islami_app_noorify/features/zikr/presentation/widgets/zikr_gradient_header.dart';
import 'package:islami_app_noorify/features/zikr/presentation/zikr_route_args.dart';

/// "New Zikr" screen (design `devImg/img_13.png`), reached from the `+` button
/// on [ZikrDashboardScreen] and from "Add More" on [ZikrSetScreen].
///
/// UI only. "Create" adds the chosen zikr to the set and moves to
/// [ZikrSetScreen]; "Lets Get Start" opens the counter with the set (plus the
/// current selection). Any zikr already in the set arrive as route arguments
/// (`List<ZikrItem>`).
class ZikrCreateScreen extends StatefulWidget {
  const ZikrCreateScreen({super.key});

  @override
  State<ZikrCreateScreen> createState() => _ZikrCreateScreenState();
}

class _ZikrCreateScreenState extends State<ZikrCreateScreen> {
  static const _customValue = '__custom__';
  static const List<ZikrItem> _dropdownItems = [
    ZikrCatalog.subhanAllah,
    ZikrCatalog.alhamdulillah,
    ZikrCatalog.allahuAkbar,
  ];

  final _fieldKey = GlobalKey();
  final _valueController = TextEditingController();

  String? _zikrName;
  String _zikrArabic = '';
  List<ZikrItem> _items = [];
  bool _argsRead = false;
  late AppText _appText;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appText = AppText.of(context);
    if (!_argsRead) {
      _argsRead = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is List<ZikrItem>) _items = List.of(args);
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  int get _readingValue {
    final parsed = int.tryParse(_valueController.text.trim());
    return (parsed != null && parsed > 0) ? parsed : 33;
  }

  /// The zikr currently chosen in the form, or null if nothing is selected.
  ZikrItem? get _currentItem {
    final name = _zikrName;
    if (name == null || name.isEmpty) return null;
    return ZikrItem(
      name: name,
      arabic: _zikrArabic,
      transliteration: name,
      target: _readingValue,
    );
  }

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
    final fieldBox =
        _fieldKey.currentContext!.findRenderObject() as RenderBox;
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final topLeft = fieldBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final bottomRight = fieldBox.localToGlobal(
      fieldBox.size.bottomRight(Offset.zero),
      ancestor: overlayBox,
    );
    final position = RelativeRect.fromRect(
      Rect.fromPoints(topLeft, bottomRight),
      Offset.zero & overlayBox.size,
    );

    final appText = _appText;
    final result = await showMenu<String>(
      context: context,
      position: position,
      color: Colors.white,
      elevation: 4,
      constraints: BoxConstraints(
        minWidth: fieldBox.size.width,
        maxWidth: fieldBox.size.width,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      items: [
        for (var i = 0; i < _dropdownItems.length; i++) ...[
          if (i > 0) const PopupMenuDivider(height: 1),
          PopupMenuItem<String>(
            value: _dropdownItems[i].name,
            child: Text(
              _dropdownItems[i].name,
              style: TextStyle(fontSize: 13.sp, color: const Color(0xFF2C3320)),
            ),
          ),
        ],
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: _customValue,
          child: Text(
            appText.zikrCustom,
            style: TextStyle(fontSize: 13.sp, color: const Color(0xFF2C3320)),
          ),
        ),
      ],
    );

    if (result == null || !mounted) return;
    if (result == _customValue) {
      await _openCustomSheet();
      return;
    }
    final item = _dropdownItems.firstWhere((z) => z.name == result);
    setState(() {
      _zikrName = item.name;
      _zikrArabic = item.arabic;
      _valueController.text = item.target.toString();
    });
  }

  Future<void> _openCustomSheet() async {
    final created = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFDCE8C4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
      ),
      builder: (_) => _CustomZikrSheet(appText: _appText),
    );

    if (created == null || !mounted) return;
    final name = created.$1.isEmpty ? _appText.zikrCustom : created.$1;
    final value = int.tryParse(created.$2);
    setState(() {
      _zikrName = name;
      _zikrArabic = '';
      _valueController.text = (value != null && value > 0)
          ? value.toString()
          : '';
    });
  }

  void _create() {
    final item = _currentItem;
    if (item == null) {
      _toast(_appText.zikrSelectZikr);
      return;
    }
    HapticFeedback.selectionClick();
    Navigator.of(context).pushReplacementNamed(
      RouteNames.zikrSet,
      arguments: [..._items, item],
    );
  }

  void _start() {
    final item = _currentItem;
    final sequence = [..._items, ?item];
    if (sequence.isEmpty) {
      _toast(_appText.zikrSelectZikr);
      return;
    }
    Navigator.of(context).pushNamed(
      RouteNames.zikrCounter,
      arguments: ZikrCounterArgs(
        title: sequence.length == 1 ? sequence.first.name : _appText.zikrTitle,
        items: sequence,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appText = _appText;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          ZikrGradientHeader(title: appText.zikrNewTitle),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(22.w, 26.h, 22.w, 20.h),
              children: [
                _FieldLabel(appText.zikrSelectZikr),
                SizedBox(height: 10.h),
                _SelectField(
                  key: _fieldKey,
                  text: _zikrName,
                  hint: appText.zikrSelectZikr,
                  onTap: _openDropdown,
                ),
                SizedBox(height: 24.h),
                _FieldLabel(appText.zikrSetReadingValue),
                SizedBox(height: 10.h),
                TextField(
                  controller: _valueController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: appText.zikrReadingValueHint,
                    hintStyle: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFFA9B08D),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 16.h,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28.r),
                      borderSide: const BorderSide(color: Color(0xFFCBD9AF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28.r),
                      borderSide: const BorderSide(color: AppColor.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52.h,
                      child: OutlinedButton(
                        onPressed: _create,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColor.authLogo,
                          side: const BorderSide(color: Color(0xFFC7D6A6)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28.r),
                          ),
                        ),
                        child: Text(
                          appText.zikrCreate,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: SizedBox(
                      height: 52.h,
                      child: FilledButton(
                        onPressed: _start,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28.r),
                          ),
                        ),
                        child: Text(
                          appText.zikrIntroStartButton,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF2C3320),
      ),
    );
  }
}

class _SelectField extends StatelessWidget {
  const _SelectField({
    super.key,
    required this.hint,
    required this.onTap,
    this.text,
  });

  final String hint;
  final String? text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = text != null && text!.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(color: const Color(0xFFCBD9AF)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue ? text! : hint,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
                  color: hasValue
                      ? const Color(0xFF2C3320)
                      : const Color(0xFFA9B08D),
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 22.sp,
              color: const Color(0xFF9BA85B),
            ),
          ],
        ),
      ),
    );
  }
}

/// Body of the "Custom" bottom sheet (design `devImg/img_15.png`). Owns its own
/// controllers so they are disposed only after the sheet has fully closed.
class _CustomZikrSheet extends StatefulWidget {
  const _CustomZikrSheet({required this.appText});

  final AppText appText;

  @override
  State<_CustomZikrSheet> createState() => _CustomZikrSheetState();
}

class _CustomZikrSheetState extends State<_CustomZikrSheet> {
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appText = widget.appText;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22.w,
        18.h,
        22.w,
        18.h + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              appText.zikrCreateTitle,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3C4A28),
              ),
            ),
          ),
          SizedBox(height: 18.h),
          _SheetLabel(appText.zikrWriteZikrName),
          SizedBox(height: 8.h),
          _SheetField(
            controller: _nameController,
            hint: appText.zikrWriteZikrNameHint,
            textCapitalization: TextCapitalization.words,
          ),
          SizedBox(height: 16.h),
          _SheetLabel(appText.zikrSetReadingValue),
          SizedBox(height: 8.h),
          _SheetField(
            controller: _valueController,
            hint: appText.zikrReadingValueHint,
            keyboardType: TextInputType.number,
            digitsOnly: true,
          ),
          SizedBox(height: 22.h),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50.h,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC0392B),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFC0392B)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26.r),
                      ),
                    ),
                    child: Text(
                      appText.zikrCancel,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: SizedBox(
                  height: 50.h,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, (
                      _nameController.text.trim(),
                      _valueController.text.trim(),
                    )),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26.r),
                      ),
                    ),
                    child: Text(
                      appText.zikrCreate,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
        ],
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF5E7038),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
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
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontStyle: FontStyle.italic,
          color: const Color(0xFF9AA579),
        ),
        filled: true,
        fillColor: const Color(0xFFEAF1D9),
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26.r),
          borderSide: const BorderSide(color: Color(0xFFBFD09B)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26.r),
          borderSide: const BorderSide(color: AppColor.primary),
        ),
      ),
    );
  }
}
