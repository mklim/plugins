import 'dart:io';

import 'package:analyzer/dart/constant/value.dart';
import 'package:auto_channel_builder/language_generator.dart';
import 'package:auto_channel_builder/method_channel_api.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:tuple/tuple.dart';

import '../api.dart';

const Map<SupportedType, String> supportedTypeEnumToJavaName =
    <SupportedType, String>{
  SupportedType.DYNAMIC: 'Object',
  SupportedType.VOID: 'void',
  SupportedType.NULL: 'null',
  SupportedType.BOOL: 'Boolean',
  SupportedType.INT: 'Integer',
  SupportedType.DOUBLE: 'Double',
  SupportedType.STRING: 'String',
  SupportedType.LIST: 'ArrayList',
  SupportedType.MAP: 'HashMap'
};

const String _header = """
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: JavaAutoChannelGenerator
// **************************************************************************
""";

const String _handlerClassTemplate = """$_header

package %PACKAGE%;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import java.util.ArrayList;
import java.util.HashMap;

public final class %BASE_NAME%Handler implements MethodCallHandler {
  private final %BASE_NAME% impl;

  public %BASE_NAME%Handler(%BASE_NAME% impl, Registrar registrar) {
    this.impl = impl;
    MethodChannel channel = new MethodChannel(registrar.messenger(), "%CHANNEL_NAME%");
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(MethodCall call, final Result result) {
    switch (call.method) {
      %HANDLER_CASES%
      default:
        result.notImplemented();
        break;
    }
  }
}
""";

const String _handlerCaseTemplate = """case "%NAME%":
        result.success(impl.%NAME%(%ARGS%));
        break;""";

const String _interfaceMethodTemplate = "%RETURN_TYPE% %NAME%(%ARGS%);";

const String _interfaceClassTemplate = """$_header
package %PACKAGE%;

import java.util.ArrayList;
import java.util.HashMap;

public interface %BASE_NAME% {
  %METHODS%
}
""";

class JavaAutoChannelGenerator extends LanguageGenerator {
  @override
  Future<void> generateCaller(
          {ParsedMethodChannelApi api,
          BuildStep buildStep,
          DartObject options}) =>
      throw UnimplementedError("Can't build Java Handlers yet.");

  @override
  Future<void> generateHandler(
      {ParsedMethodChannelApi api,
      BuildStep buildStep,
      DartObject options}) async {
    final JavaOptions parsedOptions = _parseOptions(options);

    final Future<void> interfaceFuture = _generateInterface(
        api: api, buildStep: buildStep, options: parsedOptions);
    final Future<void> handlerFuture = _generateHandler(
        api: api, buildStep: buildStep, options: parsedOptions);

    await Future.wait(<Future<void>>[interfaceFuture, handlerFuture]);
  }

  @override
  String get supportedLanguageName => javaName;

  @override
  List<String> get extensions =>
      <String>['.auto_channel.java', '.auto_channel.handler.java'];

  Future<void> _generateHandler(
      {ParsedMethodChannelApi api, BuildStep buildStep, JavaOptions options}) {
    final String cases =
        api.methods.map(_buildHandlerCaseString).toList().join('\n\n');

    final String output = _handlerClassTemplate
        .replaceAll('%BASE_NAME%', api.name)
        .replaceAll('%CHANNEL_NAME%', api.methodChannelName)
        .replaceAll('%PACKAGE%', options.packageName)
        .replaceAll('%HANDLER_CASES%', cases);

    return writeOutput(
        output: output,
        extension: '.auto_channel.handler.java',
        filename: '${api.name}Handler.java',
        options: options,
        buildStep: buildStep);
  }

  // Create a generic interface for the API surface on the Java side.
  Future<void> _generateInterface(
      {ParsedMethodChannelApi api, BuildStep buildStep, JavaOptions options}) {
    final String methods =
        api.methods.map(_buildInterfaceMethodString).toList().join('\n\n');
    final String output = _interfaceClassTemplate
        .replaceAll('%BASE_NAME%', api.name)
        .replaceAll('%PACKAGE%', options.packageName)
        .replaceAll('%METHODS%', methods);

    return writeOutput(
        output: output,
        extension: '.auto_channel.java',
        filename: '${api.name}.java',
        options: options,
        buildStep: buildStep);
  }

  static Future<void> writeOutput(
      {String output,
      String extension,
      String filename,
      JavaOptions options,
      BuildStep buildStep}) {
    final AssetId javaFile = buildStep.inputId.changeExtension(extension);

    final Uri linkDir = Uri.parse(options.outputDirectory);

    return buildStep
        .writeAsString(javaFile, output)
        .catchError((dynamic _) async {
      final Link javaLink = Link(options.outputDirectory);
      if (javaLink.existsSync()) {
        await javaLink.delete();
      }
    }).whenComplete(() async {
      final String relativeDir = linkDir.pathSegments
          .sublist(0, linkDir.pathSegments.length - 1)
          .map((String _) => '..')
          .join('/');
      final String absoluteAssetPath =
          Uri.parse(relativeDir).resolve(javaFile.path).toFilePath();
      final Link javaLink = Link(linkDir.resolve(filename).toString());
      if (javaLink.existsSync()) {
        return javaLink.update(absoluteAssetPath);
      } else {
        return javaLink.create(absoluteAssetPath);
      }
    });
  }

  static JavaOptions _parseOptions(DartObject options) {
    if (options.isNull) {
      throw InvalidGenerationSourceError(
          'Java files need a configured pacakgeName and outputDirectory');
    }

    final String packageName = options.getField('packageName').toStringValue();
    final String outputDirectory =
        options.getField('outputDirectory').toStringValue();
    if (packageName == null || outputDirectory == null) {
      throw InvalidGenerationSourceError(
          'Java files need a configured pacakgeName and outputDirectory');
    }

    return JavaOptions(
        packageName: packageName, outputDirectory: outputDirectory);
  }

  static String _buildHandlerCaseString(ParsedMethod method) {
    final String argList = method.args
        .map((Tuple2<ArgType, String> arg) => 'call.argument("${arg.item2}")')
        .join(', ');

    return _handlerCaseTemplate
        .replaceAll('%NAME%', method.name)
        .replaceAll('%ARGS%', argList);
  }

  static String _buildInterfaceMethodString(ParsedMethod method) {
    final List<String> argList = method.args
        .map((Tuple2<ArgType, String> arg) =>
            '${_buildFullTypeString(arg.item1)} ${arg.item2}')
        .toList();
    return _interfaceMethodTemplate
        .replaceAll('%RETURN_TYPE%', _buildFullTypeString(method.returnType))
        .replaceAll('%NAME%', method.name)
        .replaceAll('%ARGS%', argList.join(', '));
  }

  static String _buildFullTypeString(ArgType type) {
    final String parameters =
        type.typeArguments.map(_buildFullTypeString).join(', ');
    if (parameters.isEmpty) {
      return supportedTypeEnumToJavaName[type.type];
    } else {
      return '${supportedTypeEnumToJavaName[type.type]}<$parameters>';
    }
  }
}
