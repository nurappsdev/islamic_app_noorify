import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/home/data/services/prayer_location_service.dart';
import 'package:tuhfatul_muslim/features/home/domain/prayer_location.dart';
import 'package:tuhfatul_muslim/features/home/presentation/bloc/prayer_location/prayer_location_cubit.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// Provides one location BLoC for a route and refreshes it when the app comes
/// back to the foreground. A single shared service deduplicates simultaneous
/// route requests, while each route remains independently lifecycle-aware.
class PrayerLocationScope extends StatefulWidget {
  const PrayerLocationScope({super.key, required this.child});

  final Widget child;

  @override
  State<PrayerLocationScope> createState() => _PrayerLocationScopeState();
}

class _PrayerLocationScopeState extends State<PrayerLocationScope>
    with WidgetsBindingObserver {
  late final PrayerLocationCubit _cubit;
  LanguageBloc? _languageBloc;
  StreamSubscription<LanguageState>? _languageSubscription;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit = PrayerLocationCubit(PrayerLocationService.instance);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final languageBloc = BlocProvider.of<LanguageBloc>(context);
      if (identical(languageBloc, _languageBloc)) return;
      _languageSubscription?.cancel();
      _languageBloc = languageBloc;
      _languageSubscription = languageBloc.stream.listen(
        (state) => unawaited(_setLanguage(state.language)),
      );
      unawaited(_setLanguage(languageBloc.state.language));
    } on FlutterError {
      _startLocation();
    }
  }

  Future<void> _setLanguage(AppLanguage language) async {
    await _cubit.setLocaleIdentifier(
      language == AppLanguage.bangla ? 'bn_BD' : 'en_US',
    );
    if (!mounted) return;
    _startLocation();
  }

  void _startLocation() {
    if (_started) return;
    _started = true;
    unawaited(_cubit.refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _cubit.refresh(force: true);
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _cubit.pauseUpdates();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _languageSubscription?.cancel();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocProvider.value(value: _cubit, child: widget.child);
}

/// Rebuilds from the route's location BLoC. The no-provider branch keeps the
/// reusable prayer widgets safe in isolation tests and never supplies a place
/// name that could be mistaken for the user's location.
class PrayerLocationBuilder extends StatelessWidget {
  const PrayerLocationBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, PrayerLocationState state)
  builder;

  @override
  Widget build(BuildContext context) {
    PrayerLocationCubit? cubit;
    try {
      cubit = BlocProvider.of<PrayerLocationCubit>(context);
    } on FlutterError {
      // This widget is also used in isolated previews/tests where the route
      // scope is intentionally absent.
      cubit = null;
    }
    if (cubit == null) {
      return builder(
        context,
        const PrayerLocationState(status: PrayerLocationStatus.unavailable),
      );
    }
    return BlocBuilder<PrayerLocationCubit, PrayerLocationState>(
      bloc: cubit,
      builder: builder,
    );
  }
}

class PrayerLocationText extends StatelessWidget {
  const PrayerLocationText({
    super.key,
    required this.style,
    this.textAlign = TextAlign.center,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  final TextStyle style;
  final TextAlign textAlign;
  final int maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) => PrayerLocationBuilder(
    builder: (context, state) => Text(
      _label(context, state),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: style,
    ),
  );

  static String _label(BuildContext context, PrayerLocationState state) {
    final location = state.location?.districtCountryDisplayName ?? '';
    if (location.isNotEmpty) return location;

    final text = AppText.of(context);
    return switch (state.status) {
      PrayerLocationStatus.idle ||
      PrayerLocationStatus.locating => text.locationFinding,
      PrayerLocationStatus.serviceDisabled => text.locationServiceDisabled,
      PrayerLocationStatus.permissionDenied ||
      PrayerLocationStatus.permissionDeniedForever =>
        text.locationPermissionDenied,
      PrayerLocationStatus.unavailable => text.locationUnavailable,
      PrayerLocationStatus.ready => text.locationUnavailable,
    };
  }
}
