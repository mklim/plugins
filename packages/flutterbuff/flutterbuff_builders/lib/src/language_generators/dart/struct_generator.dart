import 'package:analyzer/dart/constant/value.dart';
import 'package:build/build.dart';
import 'package:flutterbuff_builders/src/ast/struct.dart';
import 'package:flutterbuff_builders/src/language_generators/struct_generator.dart';
import 'package:flutterbuff_annotation/flutterbuff_api.dart';
import 'package:path/path.dart' as p;

import '../../ast/struct.dart';
import 'common.dart';

const String _structTemplate = """
part of '%BASE_FILE%';

class %NAME% implements _%NAME% {
  %NAME%({%CONSTRUCTOR_ARGS%});

  static %NAME% fromFlutterbuff(Map<String, dynamic> flutterbuff) {
    return %NAME%(%DESERIALIZE_ARGS%);
  }

  Map<String, dynamic> toFlutterbuff() {
    return <String, dynamic>{%SERIALIZED_KEYS%};
  }

%FIELDS%
}
""";

const String _constructorArgsTemplate = """this.%NAME%""";

const String _deserializeArgTemplate = """%NAME%: flutterbuff["%NAME%"]""";

const String _serializeKeyTemplate = """"%NAME%": %NAME%""";

class DartStructGenerator extends StructGenerator {
  @override
  Future<void> generate(
      {ParsedFlutterbuffStruct struct,
      BuildStep buildStep,
      DartObject options}) async {
    final String outputString = _structTemplate
      .replaceAll('%BASE_FILE%', p.basename(buildStep.inputId.path))
      .replaceAll('%NAME%', struct.name)
      .replaceAll('%CONSTRUCTOR_ARGS%', _useFieldNamesInTemplate(_constructorArgsTemplate, struct))
      .replaceAll('%DESERIALIZE_ARGS%', _useFieldNamesInTemplate(_deserializeArgTemplate, struct))
      .replaceAll('%SERIALIZED_KEYS%', _useFieldNamesInTemplate(_serializeKeyTemplate, struct))
      .replaceAll('%FIELDS%', struct.fields.map(_fieldString).join('\n'));

    final AssetId outputAsset =
        buildStep.inputId.changeExtension('.flutterbuff.dart');
    return buildStep.writeAsString(outputAsset, outputString);
  }

  @override
  // Nothing to clean.
  Future<void> onPostProcess(PostProcessBuildStep buildStep) => null;

  @override
  String get languageName => dartName;

  @override
  List<String> get extensions => <String>[];

  static String _useFieldNamesInTemplate(String template, ParsedFlutterbuffStruct struct) {
    return struct.fields.map((ParsedField field) => template.replaceAll('%NAME%', field.name)).join(', ');
  }

  String _fieldString(ParsedField field) => "  ${fullTypeString(field.type)} ${field.name};";
}
