import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tuhfatul_muslim/features/home/data/services/prayer_location_service.dart';
import 'package:tuhfatul_muslim/features/home/domain/prayer_location.dart';

/// Presentation boundary for the device location. The data service owns the
/// platform permission/GPS/reverse-geocoding work; widgets only consume the
/// resulting immutable [PrayerLocationState].
class PrayerLocationCubit extends Cubit<PrayerLocationState> {
  PrayerLocationCubit(this._service) : super(_service.state) {
    _service.addListener(_onLocationChanged);
  }

  final PrayerLocationService _service;

  Future<void> refresh({bool force = false}) => _service.start(force: force);

  Future<void> pauseUpdates() => _service.stopMonitoring();

  void _onLocationChanged() {
    if (!isClosed) emit(_service.state);
  }

  @override
  Future<void> close() {
    _service.removeListener(_onLocationChanged);
    return super.close();
  }
}
