//
// Generated file. Do not edit.
// This file is generated from template in file `flutter_tools/lib/src/flutter_plugins.dart`.
//

// @dart = 3.4

import 'dart:io'; // flutter_ignore: dart_io_import.
import 'package:battery_plus/battery_plus.dart';

@pragma('vm:entry-point')
class _PluginRegistrant {

  @pragma('vm:entry-point')
  static void register() {
    if (Platform.isAndroid) {
    } else if (Platform.isIOS) {
    } else if (Platform.isLinux) {
      try {
        BatteryPlusLinuxPlugin.registerWith();
      } catch (err) {
        print(
          '`battery_plus` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

    } else if (Platform.isMacOS) {
    } else if (Platform.isWindows) {
    }
  }
}
