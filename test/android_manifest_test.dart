import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release Android app can access the prayer times API', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(
      manifest,
      contains(
        '<uses-permission android:name="android.permission.INTERNET"/>',
      ),
    );
  });
}
