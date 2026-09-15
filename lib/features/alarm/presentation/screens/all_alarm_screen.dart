import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/alarm/data/datasources/alarm_local_data_source.dart';
import 'package:islami_app_noorify/features/alarm/data/datasources/alarm_remote_data_source.dart';
import 'package:islami_app_noorify/features/alarm/data/repositories/alarm_repository_impl.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/alarm_entry.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/add_alarm.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/get_alarms.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/set_alarm_enabled.dart';
import 'package:islami_app_noorify/features/alarm/presentation/bloc/alarm_list/alarm_list_bloc.dart';
import 'package:islami_app_noorify/features/alarm/presentation/screens/set_alarm_screen.dart';
import 'package:islami_app_noorify/features/alarm/presentation/widgets/alarm_settings_widgets.dart';
import 'package:islami_app_noorify/features/home/domain/daily_prayer_times.dart';
import 'package:islami_app_noorify/features/home/domain/prayer_theme_schedule.dart';

enum _AlarmTab { all, prayers }

const _olive = Color(0xFF8D9B70);
const _mutedGreen = Color(0xFF9AA687);
const _mutedGrey = Color(0xFFBDBDBD);
const _cardBorder = Color(0xFFDCE9B8);
const _fabGreen = Color(0xFFCBD79A);

class AllAlarmScreen extends StatelessWidget {
  const AllAlarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = AlarmRepositoryImpl(
      AlarmRemoteDataSourceImpl(),
      AlarmLocalDataSourceImpl(),
    );
    return BlocProvider(
      create: (_) => AlarmListBloc(
        getAlarms: GetAlarms(repository),
        addAlarm: AddAlarm(repository),
        setAlarmEnabled: SetAlarmEnabled(repository),
      )..add(const LoadAlarms()),
      child: const _AllAlarmView(),
    );
  }
}

class _AllAlarmView extends StatefulWidget {
  const _AllAlarmView();

  @override
  State<_AllAlarmView> createState() => _AllAlarmViewState();
}

class _AllAlarmViewState extends State<_AllAlarmView> {
  _AlarmTab _tab = _AlarmTab.all;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return BlocConsumer<AlarmListBloc, AlarmListState>(
      listenWhen: (previous, current) =>
          current.failure != null && current.failure != previous.failure,
      listener: (context, state) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.failure!.message)));
      },
      builder: (context, state) => _buildScaffold(context, appText, state),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    AppText appText,
    AlarmListState state,
  ) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _fabGreen,
        elevation: 0,
        onPressed: () {
          final bloc = context.read<AlarmListBloc>();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SetAlarmScreen(
                onSetAlarm: (entry) => bloc.add(SaveAlarm(entry)),
              ),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.black87),
      ),
      body: SafeArea(
        child: Column(
          children: [
            AlarmBackHeader(
              title: appText.alarm,
              subtitle: _countdownLabel(state.alarms, appText),
            ),
            SizedBox(height: 16.h),
            _AlarmTabs(
              tab: _tab,
              appText: appText,
              onChanged: (tab) => setState(() => _tab = tab),
            ),
            SizedBox(height: 14.h),
            Expanded(
              child: _tab == _AlarmTab.all
                  ? _AllAlarmList(state: state)
                  : Center(
                      child: Text(
                        appText.comingSoon,
                        style: alarmItalicStyle(13.sp, color: _mutedGreen),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _countdownLabel(List<AlarmEntry> alarms, AppText appText) {
    final now = DateTime.now();
    Duration? soonest;
    for (final alarm in alarms.where((a) => a.enabled)) {
      var target = DateTime(
        now.year,
        now.month,
        now.day,
        alarm.hour,
        alarm.minute,
      );
      if (!target.isAfter(now)) target = target.add(const Duration(days: 1));
      final diff = target.difference(now);
      if (soonest == null || diff < soonest) soonest = diff;
    }
    if (soonest == null) return appText.noAlarmSet;
    final hours = soonest.inHours;
    final minutes = soonest.inMinutes % 60;
    return '${appText.alarmWillRingIn} $hours ${appText.hrLabel} $minutes ${appText.minLabel}';
  }
}

class _AlarmTabs extends StatelessWidget {
  const _AlarmTabs({
    required this.tab,
    required this.appText,
    required this.onChanged,
  });

  final _AlarmTab tab;
  final AppText appText;
  final ValueChanged<_AlarmTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          _AlarmTabLabel(
            label: appText.allAlarm,
            selected: tab == _AlarmTab.all,
            onTap: () => onChanged(_AlarmTab.all),
          ),
          SizedBox(width: 22.w),
          _AlarmTabLabel(
            label: appText.prayersAlarm,
            selected: tab == _AlarmTab.prayers,
            onTap: () => onChanged(_AlarmTab.prayers),
          ),
        ],
      ),
    );
  }
}

class _AlarmTabLabel extends StatelessWidget {
  const _AlarmTabLabel({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected ? _olive : _mutedGreen,
            ),
          ),
          SizedBox(height: 4.h),
          if (selected)
            Container(width: 20.w, height: 2.h, color: _olive)
          else
            SizedBox(height: 2.h),
        ],
      ),
    );
  }
}

class _AllAlarmList extends StatelessWidget {
  const _AllAlarmList({required this.state});

  final AlarmListState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.alarms.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.alarms.isEmpty) {
      return Center(
        child: Text(
          AppText.of(context).noAlarmSet,
          style: alarmItalicStyle(13.sp, color: _mutedGreen),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      itemCount: state.alarms.length,
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
      itemBuilder: (context, index) =>
          _AlarmListItem(alarm: state.alarms[index]),
    );
  }
}

class _AlarmListItem extends StatelessWidget {
  const _AlarmListItem({required this.alarm});

  final AlarmEntry alarm;

  String _subtitle(AppText appText) {
    if (alarm.vibrateAndRing || (alarm.vibrate && alarm.ring)) {
      return appText.vibrateAndRing;
    }
    if (alarm.vibrate) return appText.vibrate;
    if (alarm.ring) return appText.ring;
    return appText.vibrateAndRing;
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final color = alarm.enabled ? _olive : _mutedGrey;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        border: Border.all(color: _cardBorder),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatPrayerTime(
                    PrayerClockTime(hour: alarm.hour, minute: alarm.minute),
                  ),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  _subtitle(appText),
                  style: alarmItalicStyle(
                    12.sp,
                    color: alarm.enabled ? _mutedGreen : _mutedGrey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: alarm.enabled,
            onChanged: (value) => context.read<AlarmListBloc>().add(
              ToggleAlarmEnabled(alarm.id, value),
            ),
            activeThumbColor: _olive,
            activeTrackColor: _cardBorder,
            inactiveThumbColor: _mutedGrey,
            inactiveTrackColor: const Color(0xFFE0E0E0),
          ),
        ],
      ),
    );
  }
}
