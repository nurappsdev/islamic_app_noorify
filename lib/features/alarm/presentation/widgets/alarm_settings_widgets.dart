import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/alarm/data/datasources/alarm_local_data_source.dart';
import 'package:islami_app_noorify/features/alarm/data/datasources/alarm_remote_data_source.dart';
import 'package:islami_app_noorify/features/alarm/data/repositories/alarm_repository_impl.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/ringtone.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/delete_ringtone.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/get_ringtones.dart';

TextStyle alarmItalicStyle(
  double size, {
  Color color = Colors.black,
  BuildContext? context,
}) => TextStyle(
  color: context?.inkColor(color) ?? color,
  fontSize: size,
  fontFamily: 'Times New Roman',
  fontStyle: FontStyle.italic,
);

class AlarmBackHeader extends StatelessWidget {
  const AlarmBackHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 9.h, 14.w, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: AppText.of(context).back,
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: context.surfaceColor(Color(0xFFF7F5CE)),
                foregroundColor: context.inkColor(Color(0xFF526044)),
              ),
              icon: const Icon(Icons.chevron_left),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w500),
              ),
              if (subtitle != null) ...[
                SizedBox(height: 3.h),
                Text(
                  subtitle!,
                  style: alarmItalicStyle(
                    11.sp,
                    color: const Color(0xFF9AA687),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class AlarmToggleRow extends StatelessWidget {
  const AlarmToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: alarmItalicStyle(14.sp)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF8D9B70),
          activeTrackColor: const Color(0xFFDCE9B8),
          inactiveThumbColor: const Color(0xFFBDBDBD),
          inactiveTrackColor: context.surfaceColor(Color(0xFFE0E0E0)),
        ),
      ],
    );
  }
}

/// A search box over the `GET /alarms/ringtones` catalog. Typing filters the
/// list shown below the box; tapping an entry fills the field with its name
/// and reports the pick via [onSelected].
class RingtoneSearchField extends StatefulWidget {
  const RingtoneSearchField({super.key, this.onSelected});

  final ValueChanged<Ringtone>? onSelected;

  @override
  State<RingtoneSearchField> createState() => _RingtoneSearchFieldState();
}

class _RingtoneSearchFieldState extends State<RingtoneSearchField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _repository = AlarmRepositoryImpl(
    AlarmRemoteDataSourceImpl(),
    AlarmLocalDataSourceImpl(),
  );
  late final _getRingtones = GetRingtones(_repository);
  late final _deleteRingtone = DeleteRingtone(_repository);
  List<Ringtone> _ringtones = const [];
  bool _loading = true;
  String? _deletingId;

  final _player = AudioPlayer();
  String? _playingId;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
    _controller.addListener(() => setState(() {}));
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed && mounted) {
        setState(() => _playingId = null);
      }
    });
    _load();
  }

  Future<void> _load() async {
    final result = await _getRingtones();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _ringtones = result.fold((_) => const [], (list) => list);
    });
  }

  Future<void> _togglePlay(Ringtone ringtone) async {
    if (_playingId == ringtone.id) {
      await _player.stop();
      if (mounted) setState(() => _playingId = null);
      return;
    }
    setState(() => _playingId = ringtone.id);
    try {
      await _player.setUrl(ringtone.audioUrl);
      await _player.play();
    } catch (_) {
      if (mounted) setState(() => _playingId = null);
    }
  }

  Future<void> _confirmDelete(BuildContext context, Ringtone ringtone) async {
    final appText = AppText.readOf(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(appText.deleteRingtoneTitle),
        content: Text(appText.deleteRingtoneMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(appText.alarmCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: context.surfaceColor(Colors.redAccent),
            ),
            child: Text(appText.deleteRingtoneConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    if (_playingId == ringtone.id) {
      await _player.stop();
      if (mounted) setState(() => _playingId = null);
    }
    setState(() => _deletingId = ringtone.id);
    final result = await _deleteRingtone(ringtone.id);
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() => _deletingId = null);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      },
      (_) => setState(() {
        _deletingId = null;
        _ringtones = _ringtones.where((r) => r.id != ringtone.id).toList();
      }),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _player.dispose();
    super.dispose();
  }

  List<Ringtone> get _filtered {
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) return _ringtones;
    return _ringtones
        .where((r) => r.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final showList = _focusNode.hasFocus && (_loading || _filtered.isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 44.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: context.lineColor(Color(0xFFDCE9B8))),
          ),
          child: Center(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: AppText.of(context).searchHere,
                hintStyle: alarmItalicStyle(
                  13.sp,
                  color: const Color(0xFF9AA687),
                ),
              ),
              style: alarmItalicStyle(13.sp),
            ),
          ),
        ),
        if (showList)
          Container(
            margin: EdgeInsets.only(top: 6.h),
            constraints: BoxConstraints(maxHeight: 160.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: context.lineColor(Color(0xFFDCE9B8))),
            ),
            child: _loading
                ? Padding(
                    padding: EdgeInsets.all(14.r),
                    child: Center(
                      child: SizedBox(
                        width: 16.r,
                        height: 16.r,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    shrinkWrap: true,
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: context.lineColor(Color(0xFFF0F2E6)),
                    ),
                    itemBuilder: (context, index) {
                      final ringtone = _filtered[index];
                      final isPlaying = _playingId == ringtone.id;
                      final isDeleting = _deletingId == ringtone.id;
                      return ListTile(
                        dense: true,
                        title: Text(
                          ringtone.name,
                          style: alarmItalicStyle(13.sp),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ringtone.duration,
                              style: alarmItalicStyle(
                                11.sp,
                                color: const Color(0xFF9AA687),
                              ),
                            ),
                            SizedBox(width: 4.w),
                            IconButton(
                              iconSize: 20.sp,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                              color: context.inkColor(Color(0xFF7E8C61)),
                              icon: Icon(
                                isPlaying
                                    ? Icons.stop_circle_outlined
                                    : Icons.play_circle_outline,
                              ),
                              onPressed: isDeleting
                                  ? null
                                  : () => _togglePlay(ringtone),
                            ),
                            SizedBox(width: 4.w),
                            isDeleting
                                ? SizedBox(
                                    width: 20.sp,
                                    height: 20.sp,
                                    child: const Padding(
                                      padding: EdgeInsets.all(2),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    iconSize: 20.sp,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    visualDensity: VisualDensity.compact,
                                    color: context.inkColor(Colors.redAccent),
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () =>
                                        _confirmDelete(context, ringtone),
                                  ),
                          ],
                        ),
                        onTap: () {
                          _controller.text = ringtone.name;
                          widget.onSelected?.call(ringtone);
                          _focusNode.unfocus();
                        },
                      );
                    },
                  ),
          ),
      ],
    );
  }
}
