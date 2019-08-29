import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:auto_channel_builder/language_generator.dart';
import 'package:auto_channel_builder/method_channel_api.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'api.dart';
import 'dart/generator.dart';
import 'java/generator.dart';

List<LanguageGenerator> _generators = <LanguageGenerator>[
  DartAutoChannelGenerator(),
  JavaAutoChannelGenerator(),
];

class AutoChannelGenerator extends GeneratorForAnnotation<MethodChannelApi> {
  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    final ParsedMethodChannelApi api =
        ParsedMethodChannelApi.generate(element, annotation);

    final List<DartObject> invokers = annotation.read('invokers').listValue;
    for (DartObject invoker in invokers) {
      final DartObject options = invoker.getField('options');
      await _getGenerator(invoker)
          .generateCaller(api: api, buildStep: buildStep, options: options);
    }
    final List<DartObject> handlers = annotation.read('listeners').listValue;
    for (DartObject handler in handlers) {
      final DartObject options = handler.getField('options');
      await _getGenerator(handler)
          .generateHandler(api: api, buildStep: buildStep, options: options);
    }

    return null;
  }

  static LanguageGenerator _getGenerator(DartObject language) {
    final String name = language.getField('name').toStringValue();
    for (LanguageGenerator generator in _generators) {
      if (generator.supportedLanguageName == name) {
        return generator;
      }
    }
    throw InvalidGenerationSourceError(
        'No supported generator for langauge $name');
  }
}

Builder autoChannel(BuilderOptions options) {
  return LibraryBuilder(AutoChannelGenerator(),
      generatedExtension: '.auto_channel.dart',
      additionalOutputExtensions: _generators
          .map((LanguageGenerator g) => g.extensions)
          .expand((List<String> l) => l)
          .toList());
}
