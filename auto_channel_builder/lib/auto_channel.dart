import 'package:analyzer/dart/element/element.dart';
import 'package:auto_channel_builder/method_channel_api.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'api.dart';
import 'dart/invoker.dart';

class AutoChannel extends GeneratorForAnnotation<MethodChannelApi> {
  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    final ParsedMethodChannelApi api =
        ParsedMethodChannelApi.generate(element, annotation);

    // "Just" build and return a Dart Invoker for now.
    return invokerString(api, buildStep.inputId.uri.toString());
  }
}

Builder autoChannel(BuilderOptions options) {
  return LibraryBuilder(AutoChannel(),
      generatedExtension: '.auto_channel.dart',
      additionalOutputExtensions: <String>['.auto_channel.java']);
}
