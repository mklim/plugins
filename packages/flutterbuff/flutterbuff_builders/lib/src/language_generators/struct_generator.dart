import 'package:build/build.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:flutterbuff_builders/src/ast/struct.dart';
import 'package:flutterbuff_builders/src/language_generators/generator.dart';

/// Interface defining a Flutterbuff struct generator for a specific language.
abstract class StructGenerator extends LangaugeGenerator {
  /// Generates a Flutterbuff struct for [buildStep].
  ///
  /// [options] is the unparsed language specific options annotation.
  Future<void> generate(
      {ParsedFlutterbuffStruct struct, BuildStep buildStep, DartObject options});
}
