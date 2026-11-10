import 'package:flutter/material.dart';

import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';

bool _dialogVisible = false;
bool _openingSignIn = false;

/// Shown when a Dua planner action needs the signed-in user's access token
/// but none is stored — same dialog/guard pattern as
/// `showZikrLoginRequiredDialog`, scoped to this feature so a stale auth
/// error here can't fight one from another feature's own guard.
Future<void> showDuaLoginRequiredDialog(BuildContext context) async {
  if (!context.mounted || _dialogVisible || _openingSignIn) return;
  final appText = AppText.of(context);
  _dialogVisible = true;
  try {
    final openSignIn = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: context.surfaceColor(const Color(0xFFE4EDCF)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_person_rounded,
                  color: context.inkColor(AppColor.primary),
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                appText.login,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.inkColor(const Color(0xFF2C3320)),
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                appText.loginRequiredMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.inkColor(const Color(0xFF68705D)),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.inkColor(
                          const Color(0xFF52613B),
                        ),
                        side: BorderSide(
                          color: context.lineColor(const Color(0xFFC9D6AB)),
                        ),
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(appText.duaCancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        _openingSignIn = true;
                        Navigator.of(dialogContext).pop(true);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(appText.login),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (openSignIn != true || !context.mounted) return;
    await Navigator.of(context).pushNamed(RouteNames.signIn);
  } finally {
    _dialogVisible = false;
    _openingSignIn = false;
  }
}
