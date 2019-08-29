import 'package:build/build.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'api.dart';

abstract class LanguageGenerator {
  Future<void> generateCaller({ParsedMethodChannelApi api, BuildStep buildStep, DartObject options});
  Future<void> generateHandler({ParsedMethodChannelApi api, BuildStep buildStep, DartObject options});
  String get supportedLanguageName;
  List<String> get extensions;
}