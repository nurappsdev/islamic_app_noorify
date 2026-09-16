import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';

import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/alarm/data/datasources/alarm_local_data_source.dart';
import 'package:islami_app_noorify/features/alarm/data/datasources/alarm_remote_data_source.dart';
import 'package:islami_app_noorify/features/alarm/data/repositories/alarm_repository_impl.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/alarm_entry.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/prayer_alarm.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/add_alarm.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/delete_alarm.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/get_alarm_dashboard.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/get_alarms.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/set_alarm_enabled.dart';
import 'package:islami_app_noorify/features/alarm/presentation/bloc/alarm_list/alarm_list_bloc.dart';
import 'package:islami_app_noorify/features/alarm/presentation/screens/set_alarm_screen.dart';
import 'package:islami_app_noorify/features/alarm/presentation/screens/set_all_alarm_screen.dart';
import 'package:islami_app_noorify/features/alarm/presentation/widgets/alarm_settings_widgets.dart';
import 'package:islami_app_noorify/features/home/domain/current_prayer.dart';
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
        getAlarmDashboard: GetAlarmDashboard(repository),
        addAlarm: AddAlarm(repository),
        setAlarmEnabled: SetAlarmEnabled(repository),
        deleteAlarm: DeleteAlarm(repository),
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
      floatingActionButton: _tab != _AlarmTab.all
          ? null
          : FloatingActionButton(
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
              subtitle:
                  state.serverCountdown ??
                  _countdownLabel(state.alarms, appText),
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
                  : _PrayerAlarmTab(state: state),
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

class _AllAlarmList extends StatefulWidget {
  const _AllAlarmList({required this.state});

  final AlarmListState state;

  @override
  State<_AllAlarmList> createState() => _AllAlarmListState();
}

class _AllAlarmListState extends State<_AllAlarmList> {
  final _player = AudioPlayer();
  String? _playingId;

  @override
  void initState() {
    super.initState();
    _player.processingStateStream.listen((processingState) {
      if (processingState == ProcessingState.completed && mounted) {
        setState(() => _playingId = null);
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  /// Previews [alarm]'s ringtone; tapping the same row again stops it.
  Future<void> _togglePlay(AlarmEntry alarm) async {
    if (_playingId == alarm.id) {
      await _player.stop();
      if (mounted) setState(() => _playingId = null);
      return;
    }
    if (alarm.ringtoneUrl.isEmpty) return;
    setState(() => _playingId = alarm.id);
    try {
      await _player.setUrl(alarm.ringtoneUrl);
      await _player.play();
    } catch (_) {
      if (mounted) setState(() => _playingId = null);
    }
  }

  Future<void> _confirmDelete(BuildContext context, AlarmEntry alarm) async {
    final appText = AppText.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(appText.deleteAlarmTitle),
        content: Text(appText.deleteAlarmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(appText.alarmCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(appText.deleteAlarmConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final bloc = context.read<AlarmListBloc>();
    if (_playingId == alarm.id) {
      await _player.stop();
      if (mounted) setState(() => _playingId = null);
    }
    bloc.add(RemoveAlarm(alarm.id));
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
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
      itemBuilder: (context, index) {
        final alarm = state.alarms[index];
        return _AlarmListItem(
          alarm: alarm,
          isPlaying: _playingId == alarm.id,
          onPlayToggle: () => _togglePlay(alarm),
          onDelete: () => _confirmDelete(context, alarm),
        );
      },
    );
  }
}

class _AlarmListItem extends StatelessWidget {
  const _AlarmListItem({
    required this.alarm,
    required this.isPlaying,
    required this.onPlayToggle,
    required this.onDelete,
  });

  final AlarmEntry alarm;
  final bool isPlaying;
  final VoidCallback onPlayToggle;
  final VoidCallback onDelete;

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
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
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
          IconButton(
            onPressed: alarm.ringtoneUrl.isEmpty ? null : onPlayToggle,
            icon: Icon(
              isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
              size: 22.sp,
            ),
            color: alarm.ringtoneUrl.isEmpty ? _mutedGrey : _olive,
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline_rounded, size: 21.sp),
            color: Colors.redAccent,
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

class _PrayerAlarmTab extends StatelessWidget {
  const _PrayerAlarmTab({required this.state});

  final AlarmListState state;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final prayerAlarms = state.prayerAlarms;
    final soonestType = _soonestEnabledPrayerType(prayerAlarms);
    return Column(
      children: [
        Expanded(
          child: state.isLoading && prayerAlarms.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : prayerAlarms.isEmpty
              ? Center(
                  child: Text(
                    appText.noAlarmSet,
                    style: alarmItalicStyle(13.sp, color: _mutedGreen),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 15.w),
                  itemCount: prayerAlarms.length,
                  separatorBuilder: (_, _) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) => _PrayerAlarmRow(
                    prayerAlarm: prayerAlarms[index],
                    highlighted: prayerAlarms[index].prayerType == soonestType,
                  ),
                ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(15.w, 12.h, 15.w, 4.h),
          child: SizedBox(
            width: double.infinity,
            height: 46.h,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SetAllAlarmScreen(),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _cardBorder),
                shape: const StadiumBorder(),
              ),
              child: Text(
                appText.setAllAlarm,
                style: alarmItalicStyle(14.sp, color: _olive),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// The `prayerType` of the earliest still-upcoming enabled prayer alarm,
  /// mirroring the header countdown — `null` when none are enabled.
  String? _soonestEnabledPrayerType(List<PrayerAlarm> prayerAlarms) {
    final now = DateTime.now();
    String? soonestType;
    Duration? soonest;
    for (final alarm in prayerAlarms.where((a) => a.isEnabled)) {
      final parsed = _parseClockTime(alarm.alarmTime);
      if (parsed == null) continue;
      var target = DateTime(now.year, now.month, now.day, parsed.$1, parsed.$2);
      if (!target.isAfter(now)) target = target.add(const Duration(days: 1));
      final diff = target.difference(now);
      if (soonest == null || diff < soonest) {
        soonest = diff;
        soonestType = alarm.prayerType;
      }
    }
    return soonestType;
  }
}

/// Parses a 12-hour clock string like `04:10 AM` into (hour24, minute).
(int, int)? _parseClockTime(String time) {
  final match = RegExp(
    r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
    caseSensitive: false,
  ).firstMatch(time.trim());
  if (match == null) return null;
  final hour12 = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  final isPm = match.group(3)!.toUpperCase() == 'PM';
  final hour24 = hour12 % 12 + (isPm ? 12 : 0);
  return (hour24, minute);
}

/// Maps a server `prayerType` string to the app's [PrayerPeriod] enum, where
/// one exists — `tahajjud` has no matching prayer-times entry, so it maps to
/// `null` (the per-alarm screen then just shows no subtitle for it).
PrayerPeriod? _periodFor(String prayerType) => switch (prayerType) {
  'fajr' => PrayerPeriod.fajr,
  'dhuhr' => PrayerPeriod.dhuhr,
  'asr' => PrayerPeriod.asr,
  'maghrib' => PrayerPeriod.maghrib,
  'isha' => PrayerPeriod.isha,
  _ => null,
};

class _PrayerAlarmRow extends StatelessWidget {
  const _PrayerAlarmRow({required this.prayerAlarm, required this.highlighted});

  final PrayerAlarm prayerAlarm;
  final bool highlighted;

  IconData get _icon => switch (prayerAlarm.prayerType) {
    'fajr' => Icons.wb_twilight,
    'dhuhr' => Icons.wb_sunny,
    'asr' => Icons.sunny,
    'maghrib' => Icons.wb_twilight_outlined,
    'isha' => Icons.nights_stay,
    'tahajjud' => Icons.dark_mode,
    _ => Icons.access_time,
  };

  Color get _iconColor => switch (prayerAlarm.prayerType) {
    'fajr' => const Color(0xFFFFC83D),
    'dhuhr' => const Color(0xFFFFC83D),
    'asr' => const Color(0xFFFFAA2C),
    'maghrib' => const Color(0xFFFF8E4A),
    'isha' => const Color(0xFFEACB2B),
    'tahajjud' => const Color(0xFF7E93C4),
    _ => _mutedGreen,
  };

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final period = _periodFor(prayerAlarm.prayerType);
    final parsed = _parseClockTime(prayerAlarm.alarmTime);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38.r,
            height: 38.r,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8D7),
              borderRadius: BorderRadius.circular(9.r),
            ),
            child: Icon(_icon, color: _iconColor, size: 23.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  prayerAlarm.title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    prayerAlarm.timeWindow,
                    style: TextStyle(fontSize: 9.sp, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
          if (highlighted)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: _olive),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, size: 15.sp, color: _olive),
                  SizedBox(width: 5.w),
                  Text(
                    prayerAlarm.alarmTime,
                    style: TextStyle(fontSize: 11.sp, color: _olive),
                  ),
                ],
              ),
            )
          else
            IconButton(
              tooltip: '${appText.setAlarmFor} ${prayerAlarm.title}',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SetAlarmScreen(
                    period: period,
                    initialTime: parsed == null
                        ? null
                        : PrayerClockTime(hour: parsed.$1, minute: parsed.$2),
                  ),
                ),
              ),
              icon: Icon(Icons.access_alarm, size: 20.sp),
              color: const Color(0xFF7E8C61),
            ),
        ],
      ),
    );
  }
}
