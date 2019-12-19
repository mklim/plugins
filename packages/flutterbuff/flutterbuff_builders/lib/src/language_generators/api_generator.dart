import 'package:build/build.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:flutterbuff_builders/src/language_generators/generator.dart';
import '../ast/api.dart';

/// Interface defining a Flutterbuff API generator for a specific language.
abstract class ApiGenerator extends LangaugeGenerator {
  /// Generates Flutterbuff API client for [buildStep].
  ///
  /// [options] is the unparsed language specific options annotation.
  Future<void> generateClient(
      {ParsedFlutterbuffApi api, BuildStep buildStep, DartObject options});

  /// Generates a Flutterbuff API server for [buildStep].
  ///
  /// [options] is the unparsed language specific options annotation.
  Future<void> generateServer(
      {ParsedFlutterbuffApi api, BuildStep buildStep, DartObject options});
}
