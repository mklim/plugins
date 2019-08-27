import 'dart:async';

import 'package:flutter/services.dart';

class AutoChannelBuilder {
  static const MethodChannel _channel =
      const MethodChannel('auto_channel_builder');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
