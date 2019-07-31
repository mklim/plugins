import 'dart:async';
import 'dart:io';
import 'package:flutter_driver/flutter_driver.dart';

const String platformRequest = 'Platform.operatingSystem';
const String testCompleteRequest = 'onTestComplete';

/// Only works on Android devices since permissions are granted via ADB
Future<void> main() async {
  final bool hasPermissions = await grantPermissions();
  if (!hasPermissions) {
    throw StateError('Could not establish runtime permissions');
  }
  final FlutterDriver driver = await FlutterDriver.connect();
  await driver.requestData(null, timeout: const Duration(minutes: 1));
  driver.close();
}

Future<bool> grantPermissions() async {
  const String packageName = 'io.flutter.plugins.cameraexample';
  final ProcessResult cameraResult = await Process.run('adb' , <String>['shell' ,'pm', 'grant', packageName, 'android.permission.CAMERA']);
  final ProcessResult audioResult = await Process.run('adb' , <String>['shell' ,'pm', 'grant', packageName, 'android.permission.RECORD_AUDIO']);
  if (cameraResult.stderr.toString().isNotEmpty || audioResult.stderr.toString().isNotEmpty) {
    print('Failed to set permissions. ${cameraResult.stderr} ${audioResult.stderr}');
    return false;
  } else {
    return true;
  }
}
