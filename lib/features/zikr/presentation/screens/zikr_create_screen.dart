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
/// on [ZikrDashboardScreen].
///
/// UI only — "Create" just returns to the dashboard; "Lets Get Start" opens the
/// counter with the chosen zikr and reading value.
class ZikrCreateScreen extends StatefulWidget {
  const ZikrCreateScreen({super.key});

  @override
  State<ZikrCreateScreen> createState() => _ZikrCreateScreenState();
}

class _ZikrCreateScreenState extends State<ZikrCreateScreen> {
  final _valueController = TextEditingController();
  ZikrItem? _selected;

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  int get _readingValue {
    final parsed = int.tryParse(_valueController.text.trim());
    if (parsed != null && parsed > 0) return parsed;
    return _selected?.target ?? 33;
  }

  Future<void> _pickZikr() async {
    final appText = AppText.of(context);
    final picked = await showModalBottomSheet<ZikrItem>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFDCE3C4),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 6.h),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 4.h),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  appText.zikrSelectZikr,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final item in ZikrCatalog.all)
                    ListTile(
                      title: Text(
                        item.transliteration,
                        style: TextStyle(fontSize: 13.sp),
                      ),
                      subtitle: Text(
                        item.arabic,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      trailing: Text(
                        '${item.target}x',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4C5A34),
                        ),
                      ),
                      onTap: () => Navigator.pop(sheetContext, item),
                    ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );

    if (picked != null) {
      setState(() {
        _selected = picked;
        if (_valueController.text.trim().isEmpty) {
          _valueController.text = picked.target.toString();
        }
      });
    }
  }

  void _create() {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppText.of(context).zikrCreated),
        duration: const Duration(milliseconds: 1200),
      ),
    );
    Navigator.of(context).maybePop();
  }

  void _start() {
    final item = _selected;
    Navigator.of(context).pushNamed(
      RouteNames.zikrCounter,
      arguments: ZikrCounterArgs(
        title: item?.name ?? AppText.of(context).zikrTitle,
        arabic: item?.arabic ?? '',
        target: _readingValue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);

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
                  text: _selected?.transliteration,
                  hint: appText.zikrSelectZikr,
                  onTap: _pickZikr,
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
  const _SelectField({required this.hint, required this.onTap, this.text});

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
              Icons.chevron_right_rounded,
              size: 20.sp,
              color: const Color(0xFF9BA85B),
            ),
          ],
        ),
      ),
    );
  }
}
