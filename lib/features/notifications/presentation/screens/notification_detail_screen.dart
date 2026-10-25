import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/notifications/domain/entities/notification_entity.dart';

/// Placeholder detail screen. [NotificationListScreen] opens this once
/// [notification] is known to be read: directly for an already-read item, or
/// for a previously-unread one only after `MarkNotificationAsRead` succeeds
/// (marking it read in place first). [notification] therefore always arrives
/// with `isRead == true`.
///
/// The server sends `body` as HTML (`<div>`, `<br />`, entities), so it's
/// rendered with [HtmlWidget] rather than a plain [Text].
class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({
    super.key,
    required this.notificationId,
    required this.notification,
  });

  final String notificationId;
  final NotificationEntity notification;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      appBar: AppBar(
        backgroundColor: context.surfaceColor(Colors.white),
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 69.h,
        leadingWidth: 58.w,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () => Navigator.maybePop(context),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFDFDE68),
              foregroundColor: const Color(0xFF303629),
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
        ),
        title: Text(
          appText.notifications,
          style: TextStyle(
            color: context.inkColor(const Color(0xFF84945F)),
            fontSize: 20.sp,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 12.h),
            HtmlWidget(
              notification.body,
              textStyle: TextStyle(
                fontSize: 13.sp,
                height: 1.6,
                color: context.inkColor(const Color(0xFF3B4430)),
              ),
              onTapUrl: (url) {
                final uri = Uri.tryParse(url);
                if (uri == null ||
                    !(uri.scheme == 'http' || uri.scheme == 'https')) {
                  return true;
                }
                launchUrl(uri, mode: LaunchMode.externalApplication);
                return true;
              },
            ),
          ],
        ),
      ),
    );
  }
}
