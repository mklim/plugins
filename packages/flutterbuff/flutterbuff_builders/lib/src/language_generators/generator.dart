import 'package:build/build.dart';

/// Interface defining a generator for a specific language.
abstract class LangaugeGenerator {
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
