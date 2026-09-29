import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:tuhfatul_muslim/features/notifications/presentation/screens/notification_detail_screen.dart';
import 'package:tuhfatul_muslim/features/notifications/presentation/widgets/notification_card.dart';
import 'package:tuhfatul_muslim/features/notifications/presentation/widgets/notification_shimmer.dart';

/// Lists the signed-in user's notifications (`GET /notifications`), loading
/// more as the list is scrolled. Expects a [NotificationBloc] above it,
/// already dispatched with [FetchNotifications].
class NotificationListScreen extends StatelessWidget {
  const NotificationListScreen({super.key});

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
      body: BlocConsumer<NotificationBloc, NotificationState>(
        listenWhen: (previous, current) =>
            previous.markReadFailureTick != current.markReadFailureTick,
        listener: (context, state) {
          final failure = state.markReadFailure;
          if (failure == null) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(failure.message)));
        },
        builder: (context, state) {
          switch (state.status) {
            case NotificationStatus.initial:
            case NotificationStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case NotificationStatus.failure:
              return _NotificationErrorView(
                message: state.failure?.message ?? appText.notifications,
                retryLabel: appText.tryAgain,
                onRetry: () =>
                    context.read<NotificationBloc>().add(
                      const FetchNotifications(),
                    ),
              );
            case NotificationStatus.success:
              return _NotificationList(state: state);
          }
        },
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({required this.state});

  final NotificationState state;

  Future<void> _onRefresh(BuildContext context) {
    final bloc = context.read<NotificationBloc>();
    final startTick = bloc.state.refreshTick;
    // Subscribe before dispatching so the tick bump can't be missed.
    final done = bloc.stream.firstWhere((s) => s.refreshTick != startTick);
    bloc.add(const RefreshNotifications());
    return done;
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    if (state.notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _onRefresh(context),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(12.w, 80.h, 12.w, 24.h),
          children: [
            Center(
              child: Text(
                appText.noNotificationsAvailable,
                style: TextStyle(fontSize: 13.sp),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _onRefresh(context),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 200) {
            context.read<NotificationBloc>().add(const LoadMoreNotifications());
          }
          return false;
        },
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 24.h),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: state.notifications.length + (state.isLoadingMore ? 1 : 0),
          separatorBuilder: (_, _) => SizedBox(height: 10.h),
          itemBuilder: (context, index) {
            if (index >= state.notifications.length) {
              return const NotificationCardShimmer();
            }
            final item = state.notifications[index];
            return NotificationCard(
              notification: item,
              isMarkingRead: state.markingReadId == item.id,
              onTap: () {
                if (item.isRead) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => NotificationDetailScreen(
                        notificationId: item.id,
                        notification: item,
                      ),
                    ),
                  );
                  return;
                }
                context.read<NotificationBloc>().add(
                  MarkNotificationAsRead(item.id),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationErrorView extends StatelessWidget {
  const _NotificationErrorView({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp),
            ),
            SizedBox(height: 12.h),
            TextButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}
