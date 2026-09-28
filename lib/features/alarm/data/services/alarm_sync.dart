import 'package:islami_app_noorify/features/alarm/data/repositories/alarm_repository_impl.dart';
import 'package:islami_app_noorify/features/alarm/data/services/alarm_log.dart';
import 'package:islami_app_noorify/features/alarm/data/services/alarm_scheduler.dart';
import 'package:islami_app_noorify/features/alarm/data/services/alarm_sync_plan.dart';
import 'package:islami_app_noorify/features/alarm/domain/repositories/alarm_repository.dart';

/// Makes the OS alarm schedule match the alarms saved on this device: arms
/// every alarm that is on, disarms the ones that are off or deleted, and
/// cancels anything else the OS still holds for the app (see
/// [AlarmScheduler.sync]).
///
/// The saved alarms are the only source; nothing comes from the server. Call it
/// after every change to them and once at app start (it also recomputes the
/// prayer alarms for today's prayer times). If the saved alarms can't be read
/// it does nothing, so a storage error can never cancel everything.
Future<void> syncLocalAlarms({AlarmRepository? repository}) async {
  try {
    final repo = repository ?? AlarmRepositoryImpl();
    final alarms = await repo.getAlarms();
    final prayers = await repo.getPrayerAlarms();
    if (alarms.isLeft() || prayers.isLeft()) {
      await AlarmLog.record(
        'sync',
        status: 'skipped',
        detail: 'could not read the saved alarms',
      );
      return;
    }
    await AlarmScheduler.sync(
      AlarmSyncPlan.build(
        customAlarms: alarms.getOrElse(() => const []),
        prayers: prayers.getOrElse(() => const []),
      ),
    );
  } catch (e) {
    // Best-effort: the next change or app start syncs again.
    await AlarmLog.record('sync', status: 'failed', detail: '$e');
  }
}
