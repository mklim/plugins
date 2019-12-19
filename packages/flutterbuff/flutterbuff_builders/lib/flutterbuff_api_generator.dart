import 'dart:async';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:flutterbuff_annotation/flutterbuff_api.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/ast/api.dart';
import 'src/language_generators/api_generator.dart';
import 'src/language_generators/dart/api_generator.dart';
import 'src/language_generators/java/api_generator.dart';

List<ApiGenerator> _generators = <ApiGenerator>[
  DartApiGenerator(),
  JavaApiGenerator(),
];
List<String> _generatedLangaugeExtensions = _generators
    .map((ApiGenerator g) => g.extensions)
    .expand((List<String> l) => l)
    .toList();

class FlutterbuffApiGenerator extends GeneratorForAnnotation<FlutterbuffApi> {
  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    final ParsedFlutterbuffApi api =
        ParsedFlutterbuffApi.generate(element, annotation);

    final List<DartObject> clients = annotation.read('clients').listValue;
    for (DartObject client in clients) {
      final DartObject options = client.getField('options');
      await _getGenerator(client)
          .generateClient(api: api, buildStep: buildStep, options: options);
    }
    final List<DartObject> servers = annotation.read('servers').listValue;
    for (DartObject server in servers) {
      final DartObject options = server.getField('options');
      await _getGenerator(server)
          .generateServer(api: api, buildStep: buildStep, options: options);
    }

    return null;
  }

  static ApiGenerator _getGenerator(DartObject language) {
    final String name = language.getField('name').toStringValue();
    for (ApiGenerator generator in _generators) {
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

  static ApiGenerator _getGenerator(String path) {
    for (ApiGenerator generator in _generators) {
      if (generator.extensions
          .where((String extension) => path.endsWith(extension))
          .isNotEmpty) {
        return generator;
      }
    }

    return null;
  }
}

Builder flutterbuffApiGenerator(BuilderOptions options) {
  return LibraryBuilder(FlutterbuffApiGenerator(),
      generatedExtension: '.flutterbuff_api.dart',
      additionalOutputExtensions: _generatedLangaugeExtensions);
}

PostProcessBuilder cleanupGenerator(BuilderOptions options) {
  return Cleanup();
}
