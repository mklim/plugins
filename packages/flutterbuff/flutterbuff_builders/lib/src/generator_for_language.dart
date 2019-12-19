import 'package:build/build.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'ast.dart';

/// Interface defining a generator for a specific language.
abstract class LangaugeApiGenerator {
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

  /// Removes initial build artifacts from the given [buildStep] after the build
  /// has completed.
  ///
  /// This may be a no-op if the generator doesn't have any files to clean up.
  Future<void> onPostProcess(PostProcessBuildStep buildStep);

  /// The string constant representing this language.
  String get languageName;

  /// All output extensions of this builder.
  List<String> get extensions;
}
