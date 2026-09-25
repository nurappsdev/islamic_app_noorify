import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/auth/presentation/widgets/auth_button.dart';
import 'package:islami_app_noorify/features/profile/data/datasources/change_password_remote_data_source.dart';
import 'package:islami_app_noorify/features/profile/data/repositories/change_password_repository_impl.dart';
import 'package:islami_app_noorify/features/profile/domain/usecases/change_password.dart';

/// Old password + new password + confirmation, sent to
/// `POST /settings/change-password`.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  static const _minLength = 8;
  static const _maxLength = 64;

  final _formKey = GlobalKey<FormState>();
  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  final _changePassword = ChangePassword(
    ChangePasswordRepositoryImpl(ChangePasswordRemoteDataSourceImpl()),
  );

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // --- Validation -------------------------------------------------------------

  String? _validateOld(String? value) {
    if (value == null || value.isEmpty) return 'Enter your current password.';
    return null;
  }

  String? _validateNew(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter a new password.';
    if (v.contains(RegExp(r'\s'))) return 'Password cannot contain spaces.';
    if (v.length < _minLength) {
      return 'Use at least $_minLength characters.';
    }
    if (v.length > _maxLength) {
      return 'Use at most $_maxLength characters.';
    }
    if (!v.contains(RegExp(r'[A-Z]'))) {
      return 'Add at least one uppercase letter.';
    }
    if (!v.contains(RegExp(r'[a-z]'))) {
      return 'Add at least one lowercase letter.';
    }
    if (!v.contains(RegExp(r'[0-9]'))) return 'Add at least one number.';
    if (!v.contains(RegExp(r'[^A-Za-z0-9]'))) {
      return 'Add at least one special character.';
    }
    if (v == _oldController.text) {
      return 'New password must be different from the current one.';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) return 'Confirm your new password.';
    if (value != _newController.text) return 'Passwords do not match.';
    return null;
  }

  // --- Submit -----------------------------------------------------------------

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final result = await _changePassword(
      oldPassword: _oldController.text,
      newPassword: _newController.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold((failure) => _toast(failure.message), (message) {
      _toast(message);
      Navigator.of(context).maybePop();
    });
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // --- UI ---------------------------------------------------------------------

  InputDecoration _decoration({
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    final radius = BorderRadius.circular(24.r);
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColor.authHint, fontSize: 14.sp),
      errorMaxLines: 2,
      prefixIcon: Icon(
        Icons.key_outlined,
        color: AppColor.authIcon,
        size: 18.sp,
      ),
      suffixIcon: IconButton(
        tooltip: AppText.of(context).togglePassword,
        onPressed: onToggle,
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColor.authIcon,
          size: 18.sp,
        ),
      ),
      filled: true,
      fillColor: context.surfaceColor(Colors.white),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      border: border(context.lineColor(AppColor.authFieldBorder)),
      enabledBorder: border(context.lineColor(AppColor.authFieldBorder)),
      focusedBorder: border(AppColor.primary, 1.2),
      errorBorder: border(AppColor.forgotPassword),
      focusedErrorBorder: border(AppColor.forgotPassword, 1.2),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
    required TextInputAction action,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textInputAction: action,
      validator: validator,
      enabled: !_loading,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onFieldSubmitted: onSubmitted,
      decoration: _decoration(hint: hint, obscure: obscure, onToggle: onToggle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            _Header(title: appText.changePassword),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 24.h),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _field(
                        controller: _oldController,
                        hint: 'Current Password',
                        obscure: _obscureOld,
                        onToggle: () =>
                            setState(() => _obscureOld = !_obscureOld),
                        validator: _validateOld,
                        action: TextInputAction.next,
                      ),
                      SizedBox(height: 14.h),
                      _field(
                        controller: _newController,
                        hint: appText.newPassword,
                        obscure: _obscureNew,
                        onToggle: () =>
                            setState(() => _obscureNew = !_obscureNew),
                        validator: _validateNew,
                        action: TextInputAction.next,
                      ),
                      SizedBox(height: 14.h),
                      _field(
                        controller: _confirmController,
                        hint: appText.confirmPassword,
                        obscure: _obscureConfirm,
                        onToggle: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        validator: _validateConfirm,
                        action: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        'Use $_minLength+ characters with uppercase, lowercase, '
                        'a number and a special character.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.inkColor(const Color(0xFF6B7551)),
                        ),
                      ),
                      SizedBox(height: 32.h),
                      AuthButton(
                        label: appText.confirm,
                        height: 50.h,
                        isLoading: _loading,
                        onPressed: _loading ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 4.w),
              child: IconButton(
                tooltip: AppText.of(context).back,
                onPressed: () => Navigator.maybePop(context),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFDFDE68),
                  foregroundColor: const Color(0xFF303629),
                ),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: AppColor.primary,
              fontSize: 19.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
