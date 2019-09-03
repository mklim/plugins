import 'dart:async';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:auto_channel_builder/annotation/method_channel_api.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/ast.dart';
import 'src/dart/generator.dart';
import 'src/generator_for_language.dart';
import 'src/java/generator.dart';

List<GeneratorForLanguage> _generators = <GeneratorForLanguage>[
  DartAutoChannelGenerator(),
  JavaAutoChannelGenerator(),
];
List<String> _generatedLangaugeExtensions = _generators
    .map((GeneratorForLanguage g) => g.extensions)
    .expand((List<String> l) => l)
    .toList();

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
    final List<DartObject> handlers = annotation.read('handlers').listValue;
    for (DartObject handler in handlers) {
      final DartObject options = handler.getField('options');
      await _getGenerator(handler)
          .generateHandler(api: api, buildStep: buildStep, options: options);
    }

    return null;
  }

  static GeneratorForLanguage _getGenerator(DartObject language) {
    final String name = language.getField('name').toStringValue();
    for (GeneratorForLanguage generator in _generators) {
      if (generator.languageName == name) {
        return generator;
      }
    }
    throw InvalidGenerationSourceError(
        'No supported generator for langauge $name');
  }
}

class Cleanup extends PostProcessBuilder {
  @override
  FutureOr<void> build(PostProcessBuildStep buildStep) {
    return _getGenerator(buildStep.inputId.path)?.onPostProcess(buildStep);
  }

  @override
  Iterable<String> inputExtensions = _generatedLangaugeExtensions;

  static GeneratorForLanguage _getGenerator(String path) {
    for (GeneratorForLanguage generator in _generators) {
      if (generator.extensions
          .where((String extension) => path.endsWith(extension))
          .isNotEmpty) {
        return generator;
      }
    }

    return null;
  }
}

Builder autoChannelGenerator(BuilderOptions options) {
  return LibraryBuilder(AutoChannelGenerator(),
      generatedExtension: '.auto_channel.dart',
      additionalOutputExtensions: _generatedLangaugeExtensions);
}

PostProcessBuilder cleanupGenerator(BuilderOptions options) {
  return Cleanup();
}
