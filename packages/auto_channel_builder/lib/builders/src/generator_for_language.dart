import 'package:build/build.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'ast.dart';

/// Interface defining a generator for a specific language.
abstract class GeneratorForLanguage {
  /// Generates a MethodChannel Caller for [buildStep].
  ///
  /// [options] is the unparsed language specific options annotation.
  Future<void> generateCaller(
      {ParsedMethodChannelApi api, BuildStep buildStep, DartObject options});

  /// Generates a MethodChannel Handler for [buildStep].
  ///
  /// [options] is the unparsed language specific options annotation.
  Future<void> generateHandler(
      {ParsedMethodChannelApi api, BuildStep buildStep, DartObject options});

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
