import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/localization/localized_date_formatter.dart';
import 'package:tuhfatul_muslim/core/localization/localized_time_formatter.dart';
import 'package:tuhfatul_muslim/core/theme/app_palette.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/notifications/domain/entities/notification_entity.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// One row of the notification list: title, category/type tags, a read/unread
/// badge, and the time it was sent, if known.
class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    this.isMarkingRead = false,
  });

  final NotificationEntity notification;
  final VoidCallback onTap;

  /// True while a `MarkNotificationAsRead` request for this item is out —
  /// shows a small spinner in place of the unread dot.
  final bool isMarkingRead;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final palette = context.appPalette;
    final language = context.watch<LanguageBloc>().state.language;
    final unread = !notification.isRead;
    final sentAt = notification.sentAt;

    return InkWell(
      onTap: isMarkingRead ? null : onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: context.surfaceColor(unread ? palette.tintSoft : palette.surface),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: context.lineColor(palette.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    notification.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                      color: context.inkColor(palette.textStrong),
                    ),
                  ),
                ),
                if (isMarkingRead) ...[
                  SizedBox(width: 8.w),
                  SizedBox(
                    width: 12.r,
                    height: 12.r,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                ] else if (unread) ...[
                  SizedBox(width: 8.w),
                  Container(
                    width: 8.r,
                    height: 8.r,
                    margin: EdgeInsets.only(top: 4.h),
                    decoration: const BoxDecoration(
                      color: AppColor.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            if (notification.body.isNotEmpty) ...[
              SizedBox(height: 4.h),
              Text(
                notification.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: context.inkColor(palette.textPrimary),
                ),
              ),
            ],
            SizedBox(height: 10.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (notification.category.isNotEmpty)
                  _Tag(text: notification.category, palette: palette),
                if (notification.type.isNotEmpty)
                  _Tag(text: notification.type, palette: palette),
                _StatusChip(
                  unread: unread,
                  label: unread
                      ? appText.notificationUnread
                      : appText.notificationRead,
                  palette: palette,
                ),
                if (sentAt != null)
                  Text(
                    '${LocalizedDateFormatter(language).gregorian(sentAt, shortMonth: true)} · '
                    '${LocalizedTimeFormatter(language).clockOf(sentAt)}',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: context.inkColor(palette.textPrimary),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.palette});

  final String text;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: context.surfaceColor(palette.tint),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9.sp,
          fontWeight: FontWeight.w600,
          color: context.inkColor(palette.textStrong),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.unread,
    required this.label,
    required this.palette,
  });

  final bool unread;
  final String label;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: unread
            ? AppColor.primary.withValues(alpha: 0.15)
            : context.surfaceColor(palette.border),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.sp,
          fontWeight: FontWeight.w600,
          color: unread ? AppColor.primary : context.inkColor(palette.textPrimary),
        ),
      ),
    );
  }
}
