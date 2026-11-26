import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/localization/localization_context.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/learning/presentation/widgets/learning_widgets.dart';
import 'package:tuhfatul_muslim/features/settings/data/datasources/settings_support_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/settings/data/repositories/settings_support_repository_impl.dart';
import 'package:tuhfatul_muslim/features/settings/domain/usecases/get_new_updates.dart';
import 'package:tuhfatul_muslim/features/settings/presentation/cubit/new_updates_cubit.dart';
import 'package:tuhfatul_muslim/features/settings/presentation/widgets/settings_page_scaffold.dart';

/// Settings -> New Updates: the current release notes
/// (`GET /settings/new-updates`), whose `content` is Markdown.
class NewUpdatesScreen extends StatelessWidget {
  const NewUpdatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return BlocProvider(
      create: (_) => NewUpdatesCubit(
        GetNewUpdates(
          SettingsSupportRepositoryImpl(SettingsSupportRemoteDataSourceImpl()),
        ),
      )..load(),
      child: BlocBuilder<NewUpdatesCubit, NewUpdatesState>(
        builder: (context, state) {
          final note = state.note;
          final title = (note?.title.isNotEmpty ?? false)
              ? note!.title
              : appText.newUpdatesTitle;
          return SettingsPageScaffold(
            title: title,
            child: switch (state.status) {
              NewUpdatesStatus.loading => const SettingsStateView(
                isLoading: true,
              ),
              NewUpdatesStatus.failure => SettingsStateView(
                message: state.errorMessage,
                onRetry: () => context.read<NewUpdatesCubit>().load(),
              ),
              NewUpdatesStatus.success when (note?.content.isEmpty ?? true) =>
                SettingsStateView(message: appText.newUpdatesEmpty),
              NewUpdatesStatus.success => ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                children: [
                  _VersionRow(
                    version: note!.version,
                    releaseDate: note.releaseDate,
                  ),
                  SizedBox(height: 14.h),
                  SettingsCard(child: ArticleMarkdown(markdown: note.content)),
                ],
              ),
            },
          );
        },
      ),
    );
  }
}

/// The version pill and the release date, each shown only when the API sent
/// it. Digits follow the selected language.
class _VersionRow extends StatelessWidget {
  const _VersionRow({required this.version, required this.releaseDate});

  final String? version;
  final String? releaseDate;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final version = this.version;
    final rawDate = releaseDate;
    final parsedDate = rawDate == null ? null : DateTime.tryParse(rawDate);
    final dateText = rawDate == null
        ? null
        : (parsedDate == null
              ? context.localizedDigits(rawDate)
              : context.localizedDates.gregorian(parsedDate));

    if (version == null && dateText == null) return const SizedBox.shrink();
    return Wrap(
      spacing: 10.w,
      runSpacing: 8.h,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (version != null)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: const Color(0xFFA7B462),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Text(
              context.localizedDigits('${appText.versionLabel} $version'),
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (dateText != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_outlined, size: 15.sp, color: AppColor.primary),
              SizedBox(width: 6.w),
              Text(
                '${appText.releaseDateLabel}: $dateText',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: context.inkColor(const Color(0xFF6B7551)),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
