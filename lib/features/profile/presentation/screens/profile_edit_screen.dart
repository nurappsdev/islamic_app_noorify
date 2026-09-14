import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/profile/data/services/profile_service.dart';
import 'package:islami_app_noorify/features/profile/domain/entities/profile_entity.dart';
import 'package:islami_app_noorify/shared/widgets/profile_avatar_circle.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _imagePicker = ImagePicker();

  ProfileEntity? _profile;
  String? _selectedGender;
  File? _selectedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _applyProfile(ProfileService.instance.cachedProfile);
    unawaited(_loadProfile());
  }

  Future<void> _loadProfile() async {
    final profile = await ProfileService.instance.fetchProfile();
    if (!mounted) return;
    _applyProfile(profile);
  }

  void _applyProfile(ProfileEntity? profile) {
    if (profile == null) return;
    setState(() {
      _profile = profile;
      _nameController.text = profile.name;
      _emailController.text = profile.email;
      _phoneController.text = profile.phone ?? '';
      _selectedGender = profile.gender;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _openGalleryPicker() async {
    final appText = AppText.readOf(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          appText.editProfileSelectPhotoTitle,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(appText.editProfileCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColor.primary),
            child: Text(appText.editProfileChooseGallery),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _pickImageFromGallery();
  }

  Future<void> _pickImageFromGallery() async {
    final appText = AppText.readOf(context);
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      setState(() => _selectedImage = File(picked.path));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appText.editProfileImagePickError)),
      );
    }
  }

  Future<void> _save() async {
    final appText = AppText.readOf(context);
    if (_profile == null || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);
    final phone = _phoneController.text.trim();
    final result = await ProfileService.instance.updateProfile(
      name: _nameController.text.trim(),
      phone: phone.isEmpty ? null : phone,
      gender: _selectedGender,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      },
      (updated) {
        _applyProfile(updated);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(appText.saveAction)));
        Navigator.of(context).maybePop();
      },
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData prefixIcon,
    bool enabled = true,
  }) {
    final radius = BorderRadius.circular(24.r);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColor.authHint, fontSize: 13.sp),
      prefixIcon: Icon(prefixIcon, color: AppColor.authIcon, size: 18.sp),
      filled: true,
      fillColor: enabled ? Colors.white : const Color(0xFFF3F5E4),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColor.authFieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColor.authFieldBorder),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColor.authFieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColor.primary, width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _EditProfileHeader(
              title: appText.editProfileTitle,
              onBack: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 24.h),
                  children: [
                    Center(
                      child: _ProfileAvatar(
                        imageFile: _selectedImage,
                        onTapGallery: _openGalleryPicker,
                      ),
                    ),
                    SizedBox(height: 28.h),
                    Text(
                      appText.enterYourName,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColor.authLogo,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      style: TextStyle(fontSize: 13.sp),
                      decoration: _fieldDecoration(
                        hint: appText.enterYourName,
                        prefixIcon: Icons.person_outline,
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? appText.enterYourName
                          : null,
                    ),
                    SizedBox(height: 18.h),
                    Text(
                      appText.emailAddress,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColor.authLogo,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _emailController,
                      enabled: false,
                      style: TextStyle(fontSize: 13.sp, color: AppColor.authHint),
                      decoration: _fieldDecoration(
                        hint: appText.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        enabled: false,
                      ),
                    ),
                    SizedBox(height: 18.h),
                    Text(
                      appText.gender,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColor.authLogo,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(16.r),
                      dropdownColor: Colors.white,
                      style: TextStyle(color: AppColor.authLogo, fontSize: 13.sp),
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColor.authIcon,
                        size: 20.sp,
                      ),
                      decoration: _fieldDecoration(
                        hint: appText.gender,
                        prefixIcon: Icons.wc_outlined,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'male',
                          child: Text(appText.male),
                        ),
                        DropdownMenuItem(
                          value: 'female',
                          child: Text(appText.female),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedGender = value),
                    ),
                    SizedBox(height: 18.h),
                    Text(
                      appText.phoneNo,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColor.authLogo,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      style: TextStyle(fontSize: 13.sp),
                      decoration: _fieldDecoration(
                        hint: appText.phoneNo,
                        prefixIcon: Icons.phone_outlined,
                      ),
                    ),
                    SizedBox(height: 32.h),
                    SizedBox(
                      height: 50.h,
                      child: FilledButton(
                        onPressed: (_profile == null || _isSaving) ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26.r),
                          ),
                        ),
                        child: _isSaving
                            ? SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                appText.saveAction,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
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
      ),
    );
  }
}

class _EditProfileHeader extends StatelessWidget {
  const _EditProfileHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: SizedBox(
        height: 44.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: appText.back,
                onPressed: onBack,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFDFDE68),
                  foregroundColor: const Color(0xFF303629),
                ),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
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
      ),
    );
  }
}

/// Circular avatar that previews [imageFile] when set, with a gallery-icon
/// badge that lets the user pick a new photo from their device. There is no
/// photo-upload endpoint yet, so the picked image is a local preview only.
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.imageFile, required this.onTapGallery});

  final File? imageFile;
  final VoidCallback onTapGallery;

  @override
  Widget build(BuildContext context) {
    final dimension = 96.r;
    return SizedBox(
      width: dimension + 8.r,
      height: dimension + 8.r,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: dimension,
            height: dimension,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFA7B462),
            ),
            child: imageFile != null
                ? ClipOval(
                    child: Image.file(
                      imageFile!,
                      fit: BoxFit.cover,
                      width: dimension - 12.r,
                      height: dimension - 12.r,
                    ),
                  )
                : ProfileAvatarCircle(
                    dimension: dimension - 12.r,
                    backgroundColor: Colors.white,
                    placeholderIconColor: const Color(0xFFB7C17E),
                  ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: onTapGallery,
              child: Container(
                width: 28.r,
                height: 28.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColor.primary,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  Icons.photo_library_rounded,
                  size: 14.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
