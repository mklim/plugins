import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbuff_builder/flutterbuff_builder.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutterbuff_builder');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await AutoChannelBuilder.platformVersion, '42');
  });
}
