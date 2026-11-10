export 'main_app.dart';

import 'bootstrap/app_bootstrap.dart'
    if (dart.library.html) 'bootstrap/app_bootstrap_web.dart'
    as bootstrap;

Future<void> main() => bootstrap.bootstrap();
