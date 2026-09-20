import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/alarm/data/datasources/alarm_local_data_source.dart';
import 'package:islami_app_noorify/features/alarm/data/datasources/alarm_remote_data_source.dart';
import 'package:islami_app_noorify/features/alarm/data/repositories/alarm_repository_impl.dart';
import 'package:islami_app_noorify/features/alarm/data/services/alarm_scheduler.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/alarm_entry.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/prayer_alarm_batch.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/ringtone.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/get_alarm_dashboard.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/set_all_prayer_alarms.dart';
import 'package:islami_app_noorify/features/home/domain/current_prayer.dart';
import 'package:islami_app_noorify/features/home/domain/daily_prayer_times.dart';
import 'package:islami_app_noorify/features/alarm/presentation/screens/set_alarm_screen.dart';
import 'package:islami_app_noorify/features/alarm/presentation/bloc/alarm_bloc.dart';
import 'package:islami_app_noorify/features/alarm/presentation/widgets/alarm_settings_widgets.dart';

/// The 3 fixed presets shown in the "Set Alarm Before Prayer" dropdown
/// (a 4th, always-last "Custom" entry opens [_CustomOffsetDialog] instead).
const _offsetPresets = [40, 30, 20];

/// Prayer keys as `POST /alarms/prayers/batch` spells them, in the order the
/// rows are shown.
const _tahajjudKey = 'tahajjud';
final _prayerKeys = [...PrayerPeriod.values.map((p) => p.name), _tahajjudKey];

/// `null` stands for Tahajjud, which has no [PrayerPeriod].
String _keyOf(PrayerPeriod? period) => period?.name ?? _tahajjudKey;

/// Sentinel returned by the dropdown when "Custom" is tapped.
const _customOffsetSentinel = -1;

String _offsetLabel(int minutes, AppText appText) => switch (minutes) {
  40 => appText.offsetBefore40Min,
  30 => appText.offsetBefore30Min,
  20 => appText.offsetBefore20Min,
  _ => '${appText.offsetCustom} ($minutes ${appText.offsetMinutesUnit})',
};

class SetAllAlarmScreen extends StatelessWidget {
  const SetAllAlarmScreen({super.key, this.times});

  final DailyPrayerTimes? times;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AlarmBloc(),
      child: _SetAllAlarmView(times: times),
    );
  }
}

class _SetAllAlarmView extends StatefulWidget {
  const _SetAllAlarmView({this.times});

  final DailyPrayerTimes? times;

  @override
  State<_SetAllAlarmView> createState() => _SetAllAlarmViewState();
}

class _SetAllAlarmViewState extends State<_SetAllAlarmView> {
  final _offsetFieldKey = GlobalKey();
  final _repository = AlarmRepositoryImpl(
    AlarmRemoteDataSourceImpl(),
    AlarmLocalDataSourceImpl(),
  );
  late final _setAllPrayerAlarms = SetAllPrayerAlarms(_repository);

  /// Server-formatted waqt windows keyed by prayer type (`dhuhr` ->
  /// `12:04 PM - 03:30 PM`) from `GET /alarms`; includes Tahajjud, which the
  /// local [DailyPrayerTimes] don't have.
  Map<String, String> _timeWindows = const {};

  @override
  void initState() {
    super.initState();
    _loadTimeWindows();
  }

  Future<void> _loadTimeWindows() async {
    final result = await GetAlarmDashboard(_repository)();
    if (!mounted) return;
    result.fold((_) {}, (dashboard) {
      setState(() {
        _timeWindows = {
          for (final alarm in dashboard.prayerAlarms)
            if (alarm.timeWindow.isNotEmpty) alarm.prayerType: alarm.timeWindow,
        };
      });
    });
  }

  /// API keys of the prayers the batch applies to; all start selected.
  final _selectedPrayers = <String>{..._prayerKeys};
  Ringtone? _selectedRingtone;
  bool _saving = false;

  /// `null` while no Vibrate / Ring toggle is on — there is nothing to send.
  String? _soundMode(AlarmState state) {
    if (state.vibrateAndRing || (state.vibrate && state.ring)) {
      return 'vibrate_and_ring';
    }
    if (state.vibrate) return 'vibrate';
    if (state.ring) return 'ring';
    return null;
  }

  Future<void> _submit(AlarmState state) async {
    final soundMode = _soundMode(state);
    if (soundMode == null || _selectedPrayers.isEmpty || _saving) return;
    final appText = AppText.readOf(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    final selectedPrayers = [
      // Keep the API's canonical prayer order regardless of tap order.
      for (final key in _prayerKeys)
        if (_selectedPrayers.contains(key)) key,
    ];
    final result = await _setAllPrayerAlarms(
      PrayerAlarmBatch(
        offsetMinutesBefore: state.offsetMinutes,
        soundMode: soundMode,
        ringtoneId: _selectedRingtone?.id ?? AlarmEntry.defaultRingtoneId,
        selectedPrayers: selectedPrayers,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      (failure) =>
          messenger.showSnackBar(SnackBar(content: Text(failure.message))),
      (_) async {
        // Only these prayers may ring on this device (see
        // `AlarmScheduler.reschedulePrayerAlarms`).
        await AlarmScheduler.saveUserPrayerAlarmTypes(selectedPrayers);
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(content: Text(appText.allAlarmsSaved)));
        // `true` tells the caller the saved prayer alarms changed.
        Navigator.of(context).pop(true);
      },
    );
  }

  /// Opens a compact dropdown anchored under the "Set Alarm Before Prayer"
  /// field (img_23): the 3 presets plus "Custom", which instead opens
  /// [_CustomOffsetDialog] for picking any 1-59 value.
  Future<void> _pickOffset(BuildContext context) async {
    final appText = AppText.readOf(context);
    final renderBox =
        _offsetFieldKey.currentContext!.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final topLeft = renderBox.localToGlobal(
      Offset(0, renderBox.size.height + 6.h),
      ancestor: overlay,
    );
    final position = RelativeRect.fromRect(
      topLeft & Size(renderBox.size.width, 0),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<int>(
      context: context,
      position: position,
      color: const Color(0xFFFCFDF8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.r),
        side: BorderSide(color: context.lineColor(Color(0xFFDCE9B8))),
      ),
      constraints: BoxConstraints(minWidth: renderBox.size.width),
      items: [
        for (final minutes in _offsetPresets) ...[
          PopupMenuItem<int>(
            value: minutes,
            child: Text(
              _offsetLabel(minutes, appText),
              style: alarmItalicStyle(14.sp, context: context),
            ),
          ),
          const PopupMenuDivider(height: 1),
        ],
        PopupMenuItem<int>(
          value: _customOffsetSentinel,
          child: Text(
            appText.offsetCustom,
            style: alarmItalicStyle(14.sp, context: context),
          ),
        ),
      ],
    );
    if (selected == null || !context.mounted) return;
    if (selected == _customOffsetSentinel) {
      final currentMinutes = context.read<AlarmBloc>().state.offsetMinutes;
      final custom = await showDialog<int>(
        context: context,
        builder: (_) => _CustomOffsetDialog(initialMinutes: currentMinutes),
      );
      if (custom != null && context.mounted) {
        context.read<AlarmBloc>().add(SelectOffset(custom));
      }
    } else {
      context.read<AlarmBloc>().add(SelectOffset(selected));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AlarmBloc>().state;
    final bloc = context.read<AlarmBloc>();
    final appText = AppText.of(context);
    return Scaffold(
      backgroundColor: context.pageColor(Color(0xFFFCFDF8)),
      body: SafeArea(
        child: Column(
          children: [
            AlarmBackHeader(title: appText.setAllAlarm),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 24.h),
                children: [
                  // `null` period = Tahajjud, which isn't a PrayerPeriod.
                  for (final period in <PrayerPeriod?>[
                    ...PrayerPeriod.values,
                    null,
                  ]) ...[
                    _AllAlarmRow(
                      period: period,
                      times: widget.times,
                      timeWindow: _timeWindows[_keyOf(period)],
                      selected: _selectedPrayers.contains(_keyOf(period)),
                      onToggle: () => setState(() {
                        final key = _keyOf(period);
                        if (!_selectedPrayers.add(key)) {
                          _selectedPrayers.remove(key);
                        }
                      }),
                    ),
                    SizedBox(height: 14.h),
                  ],
                  SizedBox(height: 12.h),
                  Text(
                    appText.setAlarmBeforePrayer,
                    style: alarmItalicStyle(14.sp, context: context),
                  ),
                  SizedBox(height: 10.h),
                  InkWell(
                    onTap: () => _pickOffset(context),
                    borderRadius: BorderRadius.circular(22.r),
                    child: Container(
                      key: _offsetFieldKey,
                      height: 46.h,
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22.r),
                        border: Border.all(
                          color: context.lineColor(Color(0xFFDCE9B8)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _offsetLabel(state.offsetMinutes, appText),
                            style: alarmItalicStyle(14.sp, context: context),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF9AA687),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 22.h),
                  AlarmToggleRow(
                    label: appText.vibrate,
                    value: state.vibrate,
                    onChanged: (value) => bloc.add(SetVibrate(value)),
                  ),
                  SizedBox(height: 18.h),
                  AlarmToggleRow(
                    label: appText.ring,
                    value: state.ring,
                    onChanged: (value) => bloc.add(SetRing(value)),
                  ),
                  SizedBox(height: 22.h),
                  Text(
                    appText.setRingtone,
                    style: alarmItalicStyle(14.sp, context: context),
                  ),
                  SizedBox(height: 10.h),
                  RingtoneSearchField(
                    onSelected: (ringtone) =>
                        setState(() => _selectedRingtone = ringtone),
                  ),
                  SizedBox(height: 22.h),
                  AlarmToggleRow(
                    label: appText.vibrateAndRing,
                    value: state.vibrateAndRing,
                    onChanged: (value) => bloc.add(SetVibrateAndRing(value)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 20.h),
              child: SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed:
                      _soundMode(state) == null ||
                          _selectedPrayers.isEmpty ||
                          _saving
                      ? null
                      : () => _submit(state),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8D9B70),
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: _saving
                      ? SizedBox.square(
                          dimension: 20.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          appText.setAllAlarm,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllAlarmRow extends StatelessWidget {
  const _AllAlarmRow({
    required this.period,
    required this.times,
    required this.timeWindow,
    required this.selected,
    required this.onToggle,
  });

  /// `null` = Tahajjud: no time range and no per-prayer alarm button.
  final PrayerPeriod? period;
  final DailyPrayerTimes? times;

  /// Server-formatted waqt window; preferred over [times] when present.
  final String? timeWindow;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final period = this.period;
    final name = period?.displayName(appText) ?? appText.naflTahajjud;
    final range =
        timeWindow ??
        (period == null
            ? null
            : times == null
            ? '--:-- – --:--'
            : '${formatPrayerTime(prayerStart(period, times!))} – '
                  '${formatPrayerTime(prayerEnd(period, times!))}');
    return Row(
      children: [
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 20.r,
            height: 20.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? const Color(0xFF7F8E60) : null,
              border: Border.all(color: const Color(0xFF7F8E60), width: 1.6),
            ),
            child: selected
                ? Icon(Icons.check, size: 13.sp, color: Colors.white)
                : null,
          ),
        ),
        SizedBox(width: 13.w),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
            decoration: BoxDecoration(
              color: context.surfaceColor(Colors.white),
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(color: const Color(0xFF7F8E60), width: 1.4),
            ),
            child: Row(
              children: [
                Container(
                  width: 38.r,
                  height: 38.r,
                  decoration: BoxDecoration(
                    color: context.surfaceColor(Color(0xFFFFF8D7)),
                    borderRadius: BorderRadius.circular(9.r),
                  ),
                  child: Icon(
                    _icon(period),
                    color: context.inkColor(_iconColor(period)),
                    size: 23.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (range != null) ...[
                        SizedBox(height: 3.h),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            range,
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: context.inkColor(Colors.black54),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (period != null)
                  Tooltip(
                    message: '${appText.setAlarmFor} $name',
                    child: IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SetAlarmScreen(
                            period: period,
                            initialTime: times == null
                                ? null
                                : prayerStart(period, times!),
                          ),
                        ),
                      ),
                      icon: Icon(Icons.access_alarm, size: 20.sp),
                      color: context.inkColor(Color(0xFF7E8C61)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static IconData _icon(PrayerPeriod? period) => switch (period) {
    null => Icons.bedtime,
    PrayerPeriod.fajr => Icons.wb_twilight,
    PrayerPeriod.dhuhr => Icons.wb_sunny,
    PrayerPeriod.asr => Icons.sunny,
    PrayerPeriod.maghrib => Icons.wb_twilight_outlined,
    PrayerPeriod.isha => Icons.nights_stay,
  };

  static Color _iconColor(PrayerPeriod? period) => switch (period) {
    null => const Color(0xFF7E8C61),
    PrayerPeriod.fajr => const Color(0xFFFFC83D),
    PrayerPeriod.dhuhr => const Color(0xFFFFC83D),
    PrayerPeriod.asr => const Color(0xFFFFAA2C),
    PrayerPeriod.maghrib => const Color(0xFFFF8E4A),
    PrayerPeriod.isha => const Color(0xFFEACB2B),
  };
}

/// The "Custom" minutes picker (img_24) — free-form 1-59 entry, opened when
/// "Custom" is picked from the offset dropdown.
class _CustomOffsetDialog extends StatefulWidget {
  const _CustomOffsetDialog({required this.initialMinutes});

  final int initialMinutes;

  @override
  State<_CustomOffsetDialog> createState() => _CustomOffsetDialogState();
}

class _CustomOffsetDialogState extends State<_CustomOffsetDialog> {
  late final _controller = TextEditingController(
    text: widget.initialMinutes.toString(),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = int.tryParse(_controller.text) ?? widget.initialMinutes;
    Navigator.of(context).pop(parsed.clamp(1, 59));
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Dialog(
      backgroundColor: context.surfaceColor(Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              appText.setAlarmBeforePrayer,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFFF15A24),
                fontSize: 19.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 22.h),
            Container(
              height: 50.h,
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25.r),
                border: Border.all(color: context.lineColor(Color(0xFFDCE9B8))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      onSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: context.inkColor(Colors.black87),
                      ),
                    ),
                  ),
                  Text(
                    appText.offsetMinutesUnit,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: context.inkColor(Color(0xFF7E8C61)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 22.h),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46.h,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.surfaceColor(
                          Color(0xFFFBDCDC),
                        ),
                        foregroundColor: const Color(0xFFD84A4A),
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        appText.alarmCancel,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: SizedBox(
                    height: 46.h,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8D9B70),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        appText.alarmSet,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
