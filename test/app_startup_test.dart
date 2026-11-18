import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/core/services/app_startup.dart';

void main() {
  test('exposes deferred initialization for the Flutter splash', () async {
    final initialization = Completer<void>();

    AppStartup.begin(initialization.future);

    var isReady = false;
    unawaited(AppStartup.ready.then((_) => isReady = true));
    await Future<void>.delayed(Duration.zero);
    expect(isReady, isFalse);

    initialization.complete();
    await AppStartup.ready;
    expect(isReady, isTrue);
  });
}
