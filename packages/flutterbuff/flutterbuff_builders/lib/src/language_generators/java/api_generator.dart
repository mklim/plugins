import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/constant/value.dart';
import 'package:flutterbuff_annotation/flutterbuff_api.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';
import 'package:tuple/tuple.dart';

import '../../ast/api.dart';
import '../../ast/common.dart';
import '../api_generator.dart';

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

package %PACKAGE%;
""";

const String _serverClassTemplate = """$_header

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

const String _serverCaseTemplate = """      case "%NAME%":
        result.success(impl.%NAME%(%ARGS%));
        break;""";

const String _interfaceMethodTemplate = "  %RETURN_TYPE% %NAME%(%ARGS%);";

const String _interfaceClassTemplate = """$_header

import java.util.ArrayList;
import java.util.HashMap;

public interface %BASE_NAME% {
%METHODS%
}
""";

class JavaApiGenerator extends LangaugeApiGenerator {
  Directory _outputDirectory;

  @override
  Future<void> generateClient(
          {ParsedFlutterbuffApi api,
          BuildStep buildStep,
          DartObject options}) =>
      throw UnimplementedError("Can't build Java servers yet.");

  @override
  Future<void> generateServer(
      {ParsedFlutterbuffApi api,
      BuildStep buildStep,
      DartObject options}) async {
    _outputDirectory = null;
    final JavaOptions parsedOptions = _parseOptions(options);

    final Future<void> interfaceFuture = _generateInterface(
        api: api, buildStep: buildStep, options: parsedOptions);
    final Future<void> serverFuture =
        _generateServer(api: api, buildStep: buildStep, options: parsedOptions);

    await Future.wait(<Future<void>>[interfaceFuture, serverFuture]);
  }

  @override
  Future<void> onPostProcess(PostProcessBuildStep buildStep) async {
    // We want to move the file out of `lib/` and into the appropriate Java
    // package.
    final File original = File(buildStep.inputId.path);
    final Stream<String> lines = original
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    String packageName;
    String className;
    final RegExp classRegex =
        RegExp(r'public.*(class|interface) (?<className>\w+)');
    await for (String line in lines) {
      if (packageName != null && className != null) {
        break;
      }

      if (line.startsWith('package ') && packageName == null) {
        packageName = line.substring('package '.length, line.length - 1);
      } else if (classRegex.hasMatch(line) && className == null) {
        className =
            classRegex.firstMatch(line).namedGroup('className').toString();
      }
    }
    if (packageName == null || className == null) {
      return null;
    }

    final String outputDirPath =
        'android/src/main/java/${packageName.replaceAll(".", "/")}';
    _outputDirectory ??= _initOutputDir(outputDirPath);
    final String newFilename =
        "$className${p.extension(buildStep.inputId.path)}";
    original.copySync('$outputDirPath/$newFilename');
    original.deleteSync();
    // We want to move the file out of `lib/` and into the appropriate Java
    return null;
  }

  @override
  String get languageName => javaName;

  @override
  List<String> get extensions =>
      <String>['.flutterbuff.java', '.flutterbuff.server.java'];

  Directory _initOutputDir(String path) {
    final Directory outputDir = Directory(path);
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    } else {
      // There may be outdated output from a previous build. Delete the
      // directory and recreate it to delete any old files.
      outputDir.deleteSync(recursive: true);
      outputDir.createSync(recursive: true);
    }
    return outputDir;
  }

  Future<void> _generateServer(
      {ParsedFlutterbuffApi api, BuildStep buildStep, JavaOptions options}) {
    final String cases =
        api.methods.map(_buildServerCaseString).toList().join('\n\n');

    final String output = _serverClassTemplate
        .replaceAll('%BASE_NAME%', api.name)
        .replaceAll('%CHANNEL_NAME%', api.methodChannelName)
        .replaceAll('%PACKAGE%', options.basePackageName)
        .replaceAll('%HANDLER_CASES%', cases);

    final AssetId javaFile =
        buildStep.inputId.changeExtension('.flutterbuff.server.java');
    return buildStep.writeAsString(javaFile, output);
  }

  // Create a generic interface for the API surface on the Java side.
  Future<void> _generateInterface(
      {ParsedFlutterbuffApi api, BuildStep buildStep, JavaOptions options}) {
    final String methods =
        api.methods.map(_buildInterfaceMethodString).toList().join('\n\n');
    final String output = _interfaceClassTemplate
        .replaceAll('%BASE_NAME%', api.name)
        .replaceAll('%PACKAGE%', options.basePackageName)
        .replaceAll('%METHODS%', methods);

    final AssetId javaFile =
        buildStep.inputId.changeExtension('.flutterbuff.java');
    return buildStep.writeAsString(javaFile, output);
  }

  static JavaOptions _parseOptions(DartObject options) {
    if (options.isNull) {
      throw InvalidGenerationSourceError(
          'Java files need a configured basePackageName.');
    }

    final String basePackageName =
        options.getField('basePackageName').toStringValue();
    if (basePackageName == null) {
      throw InvalidGenerationSourceError(
          'Java files need a configured basePackageName.');
    }

    return JavaOptions(basePackageName: '$basePackageName.generated');
  }

  static String _buildServerCaseString(ParsedMethod method) {
    final String argList = method.args
        .map((Tuple2<ArgType, String> arg) =>
            '(${_buildFullTypeString(arg.item1)}) call.argument("${arg.item2}")')
        .join(', ');

    return _serverCaseTemplate
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
