import 'dart:async';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:flutterbuff_builder/annotation/flutterbuff_api.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/ast.dart';
import 'src/dart/generator.dart';
import 'src/generator_for_language.dart';
import 'src/java/generator.dart';

List<LangaugeApiGenerator> _generators = <LangaugeApiGenerator>[
  DartApiGenerator(),
  JavaApiGenerator(),
];
List<String> _generatedLangaugeExtensions = _generators
    .map((LangaugeApiGenerator g) => g.extensions)
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

  static LangaugeApiGenerator _getGenerator(DartObject language) {
    final String name = language.getField('name').toStringValue();
    for (LangaugeApiGenerator generator in _generators) {
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

  static LangaugeApiGenerator _getGenerator(String path) {
    for (LangaugeApiGenerator generator in _generators) {
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
      generatedExtension: '.flutterbuff.dart',
      additionalOutputExtensions: _generatedLangaugeExtensions);
}

PostProcessBuilder cleanupGenerator(BuilderOptions options) {
  return Cleanup();
}
