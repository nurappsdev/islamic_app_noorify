import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tuhfatul_muslim/core/auth/auth_feature.dart';
import 'package:tuhfatul_muslim/core/localization/localized_form_scope.dart';
import 'package:tuhfatul_muslim/core/localization/localized_validator.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/core/widgets/login_required_dialog.dart';
import 'package:tuhfatul_muslim/features/settings/data/datasources/settings_support_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/settings/data/repositories/settings_support_repository_impl.dart';
import 'package:tuhfatul_muslim/features/settings/domain/entities/support_overview.dart';
import 'package:tuhfatul_muslim/features/settings/domain/usecases/get_support_overview.dart';
import 'package:tuhfatul_muslim/features/settings/domain/usecases/submit_support_ticket.dart';
import 'package:tuhfatul_muslim/features/settings/presentation/cubit/admin_support_cubit.dart';
import 'package:tuhfatul_muslim/features/settings/presentation/widgets/settings_form_field.dart';
import 'package:tuhfatul_muslim/features/settings/presentation/widgets/settings_page_scaffold.dart';

/// Settings -> Admin Support: the hotline and support e-mail
/// (`GET /settings/overview`), plus the form that opens a ticket
/// (`POST /support/tickets`).
class AdminSupportScreen extends StatelessWidget {
  const AdminSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = SettingsSupportRepositoryImpl(
      SettingsSupportRemoteDataSourceImpl(),
    );
    return BlocProvider(
      create: (_) => AdminSupportCubit(
        GetSupportOverview(repository),
        SubmitSupportTicket(repository),
      )..loadOverview(),
      child: const _AdminSupportView(),
    );
  }
}

class _AdminSupportView extends StatefulWidget {
  const _AdminSupportView();

  @override
  State<_AdminSupportView> createState() => _AdminSupportViewState();
}

class _AdminSupportViewState extends State<_AdminSupportView> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // The ticket is filed against the user's account, so a guest signs in
    // first rather than losing what they typed to a 401.
    if (!await requireLogin(context, feature: AuthFeatures.support)) return;
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    await context.read<AdminSupportCubit>().submitTicket(
      reason: _reasonController.text.trim(),
      description: _descriptionController.text.trim(),
    );
  }

  void _onSubmitState(BuildContext context, AdminSupportState state) {
    final appText = AppText.readOf(context);
    final message = (state.submitMessage ?? '').trim();
    switch (state.submitStatus) {
      case TicketSubmitStatus.sent:
        _reasonController.clear();
        _descriptionController.clear();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                message.isEmpty ? appText.supportTicketSent : message,
              ),
            ),
          );
      case TicketSubmitStatus.failure:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message.isEmpty ? appText.failureUnknown : message),
            ),
          );
      case TicketSubmitStatus.idle:
      case TicketSubmitStatus.sending:
        return;
    }
    context.read<AdminSupportCubit>().acknowledgeSubmit();
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return BlocConsumer<AdminSupportCubit, AdminSupportState>(
      listenWhen: (previous, current) =>
          previous.submitStatus != current.submitStatus,
      listener: _onSubmitState,
      builder: (context, state) {
        return SettingsPageScaffold(
          title: appText.adminSupport,
          child: LocalizedFormScope(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                children: [
                  Text(
                    appText.adminSupportSubtitle,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: context.inkColor(const Color(0xFF6B7551)),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  _ContactDetails(state: state),
                  SizedBox(height: 20.h),
                  Text(
                    appText.supportSendMessageTitle,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: context.inkColor(AppColor.authLogo),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  SettingsFormField(
                    label: appText.supportReasonLabel,
                    hint: appText.supportReasonHint,
                    prefixIcon: Icons.subject_rounded,
                    controller: _reasonController,
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        LocalizedValidator.readOf(context).required(value),
                  ),
                  SizedBox(height: 16.h),
                  SettingsFormField(
                    label: appText.supportDescriptionLabel,
                    hint: appText.supportDescriptionHint,
                    prefixIcon: Icons.chat_bubble_outline_rounded,
                    controller: _descriptionController,
                    maxLines: 5,
                    validator: (value) =>
                        LocalizedValidator.readOf(context).required(value),
                  ),
                  SizedBox(height: 24.h),
                  SettingsSubmitButton(
                    label: appText.supportSendMessageTitle,
                    isBusy: state.isSending,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The hotline, support e-mail and published app version. Shows a retry when
/// the overview request failed, and skips a detail the API left out.
class _ContactDetails extends StatelessWidget {
  const _ContactDetails({required this.state});

  final AdminSupportState state;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    switch (state.overviewStatus) {
      case SupportOverviewStatus.loading:
        return SettingsCard(
          padding: EdgeInsets.symmetric(vertical: 28.h),
          child: const Center(
            child: CircularProgressIndicator(color: AppColor.primary),
          ),
        );
      case SupportOverviewStatus.failure:
        return SettingsCard(
          child: SettingsStateView(
            message: state.overviewError,
            onRetry: () => context.read<AdminSupportCubit>().loadOverview(),
          ),
        );
      case SupportOverviewStatus.success:
        final overview = state.overview ?? const SupportOverview();
        final hotline = overview.hotline?.trim();
        final email = overview.contactEmail;
        final version = overview.appVersion?.trim();
        if (overview.isEmpty && (version == null || version.isEmpty)) {
          return SettingsCard(
            child: SettingsStateView(message: appText.noDataHere),
          );
        }
        return SettingsCard(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          child: Column(
            children: [
              if (hotline != null && hotline.isNotEmpty)
                _ContactRow(
                  icon: Icons.phone_in_talk_outlined,
                  label: appText.supportHotlineLabel,
                  value: context.localizedDigits(hotline),
                  actionLabel: appText.supportCallAction,
                  // `tel:` keeps the digits as dialled, not localized.
                  uri: Uri(scheme: 'tel', path: hotline),
                ),
              if (email != null)
                _ContactRow(
                  icon: Icons.mail_outline_rounded,
                  label: appText.supportEmailLabel,
                  value: email,
                  actionLabel: appText.supportMailAction,
                  uri: Uri(scheme: 'mailto', path: email),
                ),
              if (version != null && version.isNotEmpty)
                _ContactRow(
                  icon: Icons.info_outline_rounded,
                  label: appText.appVersionLabel,
                  value: context.localizedDigits(version),
                ),
            ],
          ),
        );
    }
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.actionLabel,
    this.uri,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? actionLabel;

  /// What tapping the row opens (`tel:` / `mailto:`); null makes it plain.
  final Uri? uri;

  Future<void> _open(BuildContext context) async {
    final target = uri;
    if (target == null) return;
    final appText = AppText.readOf(context);
    final messenger = ScaffoldMessenger.of(context);
    final opened = await launchUrl(
      target,
      mode: LaunchMode.externalApplication,
    );
    if (opened) return;
    messenger.showSnackBar(SnackBar(content: Text(appText.linkOpenFailed)));
  }

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.surfaceColor(const Color(0xFFDCE7AC)),
            ),
            child: Icon(
              icon,
              size: 18.sp,
              color: context.inkColor(const Color(0xFF7F8F52)),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: context.inkColor(const Color(0xFF6B7551)),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: context.inkColor(AppColor.authLogo),
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null)
            Text(
              actionLabel!,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColor.primary,
              ),
            ),
        ],
      ),
    );
    if (uri == null) return row;
    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(14.r),
      child: row,
    );
  }
}
