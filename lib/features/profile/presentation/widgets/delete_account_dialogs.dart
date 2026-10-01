import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/auth/data/services/auth_service.dart';
import 'package:tuhfatul_muslim/features/profile/data/services/delete_account_service.dart';
import 'package:tuhfatul_muslim/features/profile/data/services/profile_service.dart';
import 'package:tuhfatul_muslim/shared/services/app_globals.dart';

/// Entry point for the Settings screen's "Delete Account" row: password
/// confirmation, then a final destructive-action confirmation, then the
/// actual deletion. Navigates to sign-in only once every step has succeeded.
Future<void> showDeleteAccountFlow(BuildContext context) async {
  final verified = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _PasswordConfirmDialog(),
  );
  if (verified != true || !context.mounted) return;

  final deleted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _FinalConfirmDialog(),
  );
  if (deleted != true || !context.mounted) return;

  // Same session teardown as the Sign Out button.
  skipAuthGateNotifier.value = false;
  unawaited(ProfileService.instance.clear());
  Navigator.of(
    context,
  ).pushNamedAndRemoveUntil(RouteNames.signIn, (route) => false);
}

/// Maps whatever [DeleteAccountService] returned on the `Left` side to a
/// localized, user-facing message.
String _messageFor(Object error, AppText appText) {
  if (error is IncorrectPasswordException) {
    return appText.deleteAccountIncorrectPassword;
  }
  if (error is FirebaseAuthException) {
    return AuthService.instance.messageForException(error, appText);
  }
  if (error is Failure) return error.message;
  return appText.deleteAccountFailureMessage;
}

OutlineInputBorder _dialogFieldBorder(Color color, [double width = 1]) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: BorderSide(color: color, width: width),
    );

class _PasswordConfirmDialog extends StatefulWidget {
  const _PasswordConfirmDialog();

  @override
  State<_PasswordConfirmDialog> createState() =>
      _PasswordConfirmDialogState();
}

class _PasswordConfirmDialogState extends State<_PasswordConfirmDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continue(AppText appText) async {
    final password = _controller.text;
    if (password.isEmpty) {
      setState(() => _error = appText.deleteAccountEmptyPassword);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await DeleteAccountService.instance.verifyPassword(
      password,
    );
    if (!mounted) return;
    result.fold(
      (error) => setState(() {
        _loading = false;
        _error = _messageFor(error, appText);
      }),
      (_) => Navigator.of(context).pop(true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Row(
        children: [
          Container(
            width: 34.r,
            height: 34.r,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF3F5E4),
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              size: 18.sp,
              color: AppColor.primary,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              appText.deleteAccountConfirmPasswordTitle,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appText.deleteAccountConfirmPasswordMessage,
            style: TextStyle(fontSize: 13.sp, color: AppColor.primary),
          ),
          SizedBox(height: 16.h),
          TextField(
            controller: _controller,
            obscureText: _obscure,
            enabled: !_loading,
            autofocus: true,
            onSubmitted: (_) => _loading ? null : _continue(appText),
            decoration: InputDecoration(
              hintText: appText.deleteAccountPasswordHint,
              errorText: _error,
              errorMaxLines: 3,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18.sp,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 12.h,
              ),
              border: _dialogFieldBorder(AppColor.authFieldBorder),
              enabledBorder: _dialogFieldBorder(AppColor.authFieldBorder),
              focusedBorder: _dialogFieldBorder(AppColor.primary, 1.2),
              errorBorder: _dialogFieldBorder(AppColor.forgotPassword),
              focusedErrorBorder: _dialogFieldBorder(
                AppColor.forgotPassword,
                1.2,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading
              ? null
              : () => Navigator.of(context).pop(false),
          child: Text(appText.commonCancel),
        ),
        FilledButton(
          onPressed: _loading ? null : () => _continue(appText),
          child: _loading
              ? SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(appText.continueLabel),
        ),
      ],
    );
  }
}

class _FinalConfirmDialog extends StatefulWidget {
  const _FinalConfirmDialog();

  @override
  State<_FinalConfirmDialog> createState() => _FinalConfirmDialogState();
}

class _FinalConfirmDialogState extends State<_FinalConfirmDialog> {
  bool _loading = false;
  String? _error;

  Future<void> _delete(AppText appText) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await DeleteAccountService.instance.deleteAccount();
    if (!mounted) return;
    result.fold(
      (error) => setState(() {
        _loading = false;
        _error = _messageFor(error, appText);
      }),
      (_) => Navigator.of(context).pop(true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Row(
        children: [
          Container(
            width: 34.r,
            height: 34.r,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFBEAEA),
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              size: 18.sp,
              color: AppColor.forgotPassword,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              appText.deleteAccountFinalTitle,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appText.deleteAccountFinalMessage,
            style: TextStyle(fontSize: 13.sp, color: AppColor.primary),
          ),
          if (_error != null) ...[
            SizedBox(height: 10.h),
            Text(
              _error!,
              style: TextStyle(fontSize: 12.sp, color: AppColor.forgotPassword),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading
              ? null
              : () => Navigator.of(context).pop(false),
          child: Text(appText.commonCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColor.forgotPassword,
          ),
          onPressed: _loading ? null : () => _delete(appText),
          child: _loading
              ? SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(appText.deleteAccount),
        ),
      ],
    );
  }
}
