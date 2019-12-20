import 'package:analyzer/dart/constant/value.dart';
import 'package:build/build.dart';
import 'package:flutterbuff_builders/src/ast/struct.dart';
import 'package:flutterbuff_builders/src/language_generators/struct_generator.dart';
import 'package:flutterbuff_annotation/flutterbuff_api.dart';
import 'package:path/path.dart' as p;

import '../../ast/struct.dart';

const String _structTemplate = """
part of '%BASE_FILE%';

%NAME% _\$%NAME%FromFlutterbuff(Map<String, dynamic> fb) {
  %NAME% output = %NAME%();
%DESERIALIZE_LINES%
  return output;
  }

Map<String, dynamic> _\$%NAME%ToJson(%NAME% input) {
  return <String, dynamic>{%SERIALIZED_KEYS%};
}
""";

const String _deserializeLineTemplate = """
  output.%NAME% = fb["%NAME%"];
""";

const String _serializeKeyTemplate = """"%NAME%": input.%NAME%""";

class DartStructGenerator extends StructGenerator {
  @override
  Future<void> generate(
      {ParsedFlutterbuffStruct struct,
      BuildStep buildStep,
      DartObject options}) async {
    final String outputString = _structTemplate
      .replaceAll('%BASE_FILE%', p.basename(buildStep.inputId.path))
      .replaceAll('%NAME%', struct.name)
      .replaceAll('%DESERIALIZE_LINES%', _useFieldNamesInTemplate(_deserializeLineTemplate, struct, join: ''))
      .replaceAll('%SERIALIZED_KEYS%', _useFieldNamesInTemplate(_serializeKeyTemplate, struct, join: ', '));

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

  static String _useFieldNamesInTemplate(String template, ParsedFlutterbuffStruct struct, {String join}) {
    return struct.fields.map((ParsedField field) => template.replaceAll('%NAME%', field.name)).join(join);
  }
}
