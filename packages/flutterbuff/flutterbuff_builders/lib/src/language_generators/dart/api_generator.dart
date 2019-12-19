import 'package:analyzer/dart/constant/value.dart';
import 'package:flutterbuff_annotation/flutterbuff_api.dart';
import 'package:build/build.dart';
import 'package:tuple/tuple.dart';

import '../../ast/api.dart';
import '../../ast/types.dart';
import 'common.dart';
import '../api_generator.dart';

const String _clientClassTemplate = """
  import '%BASE_URI%';
  import 'package:flutter/services.dart';

  class %BASE_NAME%Client implements %BASE_NAME% {
    MethodChannel _methodChannel = MethodChannel('%CHANNEL_NAME%');

%METHODS%
  }
""";

const String _clientMethodTemplate = """
    @override
    Future<%RETURN_TYPE%> %NAME%(%ARG_LIST%) async {
      final Map<String, dynamic> args = {%ARG_MAP_KEYS%};
      return _methodChannel.%INVOKE_METHOD%<%METHOD_TYPE_ARGS%>('%NAME%', args);
    }""";

class DartApiGenerator extends ApiGenerator {
  @override
  Future<void> generateClient(
      {ParsedFlutterbuffApi api,
      BuildStep buildStep,
      DartObject options}) async {
    final String methods = api.methods.map(_methodString).toList().join('\n\n');
    final String callerString = _clientClassTemplate
        .replaceAll('%BASE_URI%', buildStep.inputId.uri.toString())
        .replaceAll('%BASE_NAME%', api.name)
        .replaceAll('%CHANNEL_NAME%', api.methodChannelName)
        .replaceAll('%METHODS%', methods);

    final AssetId output =
        buildStep.inputId.changeExtension('.flutterbuff_api.dart');
    buildStep.writeAsString(output, callerString);
  }

  @override
  Future<void> generateServer(
          {ParsedFlutterbuffApi api,
          BuildStep buildStep,
          DartObject options}) =>
      throw UnimplementedError("Can't build Dart servers yet.");

  String _methodString(ParsedMethod method) {
    final List<String> argList = <String>[];
    final List<String> argMapKeys = <String>[];
    for (Tuple2<FullType, String> arg in method.args) {
      argList.add('${fullTypeString(arg.item1)} ${arg.item2}');
      argMapKeys.add("'${arg.item2}': ${arg.item2}");
    }
    String invokeMethod;
    String methodTypeArgs;
    if (method.returnType.type != SimpleType.LIST &&
        method.returnType.type != SimpleType.MAP) {
      invokeMethod = 'invokeMethod';
      methodTypeArgs = fullTypeString(method.returnType);
    } else {
      methodTypeArgs =
          method.returnType.typeArguments.map(fullTypeString).join(', ');
      if (method.returnType.type == SimpleType.LIST) {
        invokeMethod = 'invokeListMethod';
      } else if (method.returnType.type == SimpleType.MAP) {
        invokeMethod = 'invokeMapMethod';
      }
    }
    return _clientMethodTemplate
        .replaceAll('%RETURN_TYPE%', fullTypeString(method.returnType))
        .replaceAll('%METHOD_TYPE_ARGS%', methodTypeArgs)
        .replaceAll('%INVOKE_METHOD%', invokeMethod)
        .replaceAll('%NAME%', method.name)
        .replaceAll('%ARG_LIST%', argList.join(', '))
        .replaceAll('%ARG_MAP_KEYS%', argMapKeys.join(', '));
  }

  @override
  Future<void> onPostProcess(PostProcessBuildStep buildStep) =>
      null; // Nothing to clean.

  @override
  String get languageName => dartName;

  @override
  List<String> get extensions => <String>[];
}
