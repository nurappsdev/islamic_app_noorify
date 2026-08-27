abstract class OfflineQuranEvent {
  const OfflineQuranEvent();
}

/// Check whether the offline database has already been built on this device.
class CheckOfflineQuran extends OfflineQuranEvent {
  const CheckOfflineQuran();
}

/// User confirmed — build the offline database from the bundled Quran file.
class PrepareOfflineQuran extends OfflineQuranEvent {
  const PrepareOfflineQuran();
}
