import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/zikr/presentation/bloc/zikr_analytics_cubit.dart';
import 'package:tuhfatul_muslim/features/zikr/presentation/zikr_login_dialog.dart';
import 'package:tuhfatul_muslim/features/zikr/zikr_dependencies.dart';

class ZikrHistoryScreen extends StatefulWidget {
  const ZikrHistoryScreen({super.key});

  @override
  State<ZikrHistoryScreen> createState() => _ZikrHistoryScreenState();
}

class _ZikrHistoryScreenState extends State<ZikrHistoryScreen> {
  late final ZikrAnalyticsCubit _cubit = ZikrAnalyticsCubit(zikrRepository)
    ..loadHistory();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 180) {
        _cubit.loadHistory(nextPage: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _cubit,
    child: BlocListener<ZikrAnalyticsCubit, ZikrAnalyticsState>(
      listenWhen: (previous, current) =>
          previous.error != current.error &&
          current.error?.contains('AuthenticationRequiredException') == true,
      listener: (context, _) => showZikrLoginRequiredDialog(context),
      child: Scaffold(
        backgroundColor: context.pageColor(Colors.white),
        appBar: AppBar(title: Text(AppText.of(context).zikrHistory)),
        body: BlocBuilder<ZikrAnalyticsCubit, ZikrAnalyticsState>(
          builder: (context, state) {
            if (state.history.isEmpty && state.error == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.history.isEmpty) return Center(child: Text(state.error!));
            return ListView.separated(
              controller: _scrollController,
              padding: EdgeInsets.all(16.w),
              itemCount:
                  state.history.length + (state.page < state.totalPage ? 1 : 0),
              separatorBuilder: (_, _) =>
                  Divider(color: context.lineColor(const Color(0xFFEDEFE0))),
              itemBuilder: (context, index) {
                if (index == state.history.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final item = state.history[index];
                return ListTile(
                  leading: const Icon(Icons.self_improvement_rounded),
                  title: Text(item.zikrName),
                  subtitle: Text(item.sessionDate),
                  trailing: Text(context.localizedDigits('${item.countAdded}')),
                );
              },
            );
          },
        ),
      ),
    ),
  );
}
