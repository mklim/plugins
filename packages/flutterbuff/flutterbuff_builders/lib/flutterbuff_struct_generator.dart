import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:flutterbuff_annotation/flutterbuff_struct.dart';
import 'package:build/build.dart';
import 'package:flutterbuff_builders/src/ast/struct.dart';
import 'package:flutterbuff_builders/src/language_generators/dart/struct_generator.dart';
import 'package:source_gen/source_gen.dart';

class FlutterbuffStructGenerator extends GeneratorForAnnotation<FlutterbuffStruct> {
  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    final ParsedFlutterbuffStruct struct = ParsedFlutterbuffStruct.generate(element, annotation);

    await DartStructGenerator().generate(struct: struct, buildStep: buildStep);

    return null;
  }
}
Builder flutterbuffStructGenerator(BuilderOptions options) {
  return LibraryBuilder(FlutterbuffStructGenerator(),
      generatedExtension: '.flutterbuff.dart',
      additionalOutputExtensions: []);
}
