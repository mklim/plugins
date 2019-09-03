import 'package:analyzer/dart/constant/value.dart';
import 'package:build/build.dart';
import 'package:tuple/tuple.dart';

import '../api.dart';
import '../generator_for_language.dart';
import '../method_channel_api.dart';

const String _invokerClassTemplate = """
  import '%BASE_URI%';
  import 'package:flutter/services.dart';

  class %BASE_NAME%Invoker implements %BASE_NAME% {
    MethodChannel _methodChannel = MethodChannel('%CHANNEL_NAME%');

%METHODS%
  }
""";

const String _invokerMethodTemplate = """
    @override
    Future<%RETURN_TYPE%> %NAME%(%ARG_LIST%) async {
      final Map<String, dynamic> args = {%ARG_MAP_KEYS%};
      return _methodChannel.%INVOKE_METHOD%<%METHOD_TYPE_ARGS%>('%NAME%', args);
    }""";

class DartAutoChannelGenerator extends GeneratorForLanguage {
  @override
  Future<void> generateCaller(
      {ParsedMethodChannelApi api,
      BuildStep buildStep,
      DartObject options}) async {
    final String methods = api.methods.map(_methodString).toList().join('\n\n');
    final String callerString = _invokerClassTemplate
        .replaceAll('%BASE_URI%', buildStep.inputId.uri.toString())
        .replaceAll('%BASE_NAME%', api.name)
        .replaceAll('%CHANNEL_NAME%', api.methodChannelName)
        .replaceAll('%METHODS%', methods);

    final AssetId output =
        buildStep.inputId.changeExtension('.auto_channel.dart');
    buildStep.writeAsString(output, callerString);
  }

  @override
  Future<void> generateHandler(
          {ParsedMethodChannelApi api,
          BuildStep buildStep,
          DartObject options}) =>
      throw UnimplementedError("Can't build Dart Handlers yet.");

  String _methodString(ParsedMethod method) {
    final List<String> argList = <String>[];
    final List<String> argMapKeys = <String>[];
    for (Tuple2<ArgType, String> arg in method.args) {
      argList.add('${_fullTypeString(arg.item1)} ${arg.item2}');
      argMapKeys.add("'${arg.item2}': ${arg.item2}");
    }
    String invokeMethod;
    String methodTypeArgs;
    if (method.returnType.type != SupportedType.LIST &&
        method.returnType.type != SupportedType.MAP) {
      invokeMethod = 'invokeMethod';
      methodTypeArgs = _fullTypeString(method.returnType);
    } else {
      methodTypeArgs =
          method.returnType.typeArguments.map(_fullTypeString).join(', ');
      if (method.returnType.type == SupportedType.LIST) {
        invokeMethod = 'invokeListMethod';
      } else if (method.returnType.type == SupportedType.MAP) {
        invokeMethod = 'invokeMapMethod';
      }
    }
    return _invokerMethodTemplate
        .replaceAll('%RETURN_TYPE%', _fullTypeString(method.returnType))
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

  String _fullTypeString(ArgType type) {
    final String parameters =
        type.typeArguments.map(_fullTypeString).join(', ');
    if (parameters.isEmpty) {
      return supportedTypeEnumToDartName[type.type];
    } else {
      return '${supportedTypeEnumToDartName[type.type]}<$parameters>';
    }
  }
}
