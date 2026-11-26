import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/auth/auth_feature.dart';
import 'package:tuhfatul_muslim/core/localization/localized_form_scope.dart';
import 'package:tuhfatul_muslim/core/localization/localized_validator.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/widgets/login_required_dialog.dart';
import 'package:tuhfatul_muslim/features/settings/data/datasources/settings_support_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/settings/data/repositories/settings_support_repository_impl.dart';
import 'package:tuhfatul_muslim/features/settings/domain/usecases/submit_app_feedback.dart';
import 'package:tuhfatul_muslim/features/settings/presentation/cubit/app_feedback_cubit.dart';
import 'package:tuhfatul_muslim/features/settings/presentation/widgets/settings_form_field.dart';
import 'package:tuhfatul_muslim/features/settings/presentation/widgets/settings_page_scaffold.dart';

/// Settings -> Feedback: a 1-5 star rating with a comment
/// (`POST /support/feedback`).
class AppFeedbackScreen extends StatelessWidget {
  const AppFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AppFeedbackCubit(
        SubmitAppFeedback(
          SettingsSupportRepositoryImpl(SettingsSupportRemoteDataSourceImpl()),
        ),
      ),
      child: const _AppFeedbackView(),
    );
  }
}

class _AppFeedbackView extends StatefulWidget {
  const _AppFeedbackView();

  @override
  State<_AppFeedbackView> createState() => _AppFeedbackViewState();
}

class _AppFeedbackViewState extends State<_AppFeedbackView> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cubit = context.read<AppFeedbackCubit>();
    final appText = AppText.readOf(context);
    if (cubit.state.rating < 1) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(appText.feedbackRatingRequired)));
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // Feedback is recorded against the user's account, so a guest signs in
    // first rather than losing what they typed to a 401.
    if (!await requireLogin(context, feature: AuthFeatures.support)) return;
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    await cubit.submit(_feedbackController.text.trim());
  }

  void _onSubmitState(BuildContext context, AppFeedbackState state) {
    final appText = AppText.readOf(context);
    final message = (state.message ?? '').trim();
    switch (state.status) {
      case FeedbackSubmitStatus.sent:
        _feedbackController.clear();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message.isEmpty ? appText.feedbackSent : message),
            ),
          );
        context.read<AppFeedbackCubit>().acknowledge();
        Navigator.of(context).maybePop();
        return;
      case FeedbackSubmitStatus.failure:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message.isEmpty ? appText.failureUnknown : message),
            ),
          );
      case FeedbackSubmitStatus.idle:
      case FeedbackSubmitStatus.sending:
        return;
    }
    context.read<AppFeedbackCubit>().acknowledge();
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return BlocConsumer<AppFeedbackCubit, AppFeedbackState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _onSubmitState,
      builder: (context, state) {
        return SettingsPageScaffold(
          title: appText.feedbackTitle,
          child: LocalizedFormScope(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                children: [
                  SettingsCard(
                    child: Column(
                      children: [
                        Text(
                          appText.feedbackRatingQuestion,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: context.inkColor(AppColor.authLogo),
                          ),
                        ),
                        SizedBox(height: 14.h),
                        _StarRow(
                          rating: state.rating,
                          onRate: context.read<AppFeedbackCubit>().setRating,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  SettingsFormField(
                    label: appText.feedbackMessageLabel,
                    hint: appText.feedbackMessageHint,
                    prefixIcon: Icons.rate_review_outlined,
                    controller: _feedbackController,
                    maxLines: 5,
                    validator: (value) =>
                        LocalizedValidator.readOf(context).required(value),
                  ),
                  SizedBox(height: 24.h),
                  SettingsSubmitButton(
                    label: appText.submit,
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

/// The five stars; tapping one sets the rating to its position.
class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating, required this.onRate});

  final int rating;
  final ValueChanged<int> onRate;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var star = 1; star <= 5; star++)
          IconButton(
            onPressed: () => onRate(star),
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            constraints: const BoxConstraints(),
            icon: Icon(
              star <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 34.sp,
              color: star <= rating
                  ? const Color(0xFFFFC83D)
                  : context.lineColor(const Color(0xFFBFC9A0)),
            ),
          ),
      ],
    );
  }
}
