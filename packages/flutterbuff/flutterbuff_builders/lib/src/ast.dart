import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';
import 'package:tuple/tuple.dart';

/// Represents an API that crosses the MethodChannel boundary.
class ParsedFlutterbuffApi {
  /// Attempts to parse the given [element] into an [ParsedFlutterbuffApi].
  ///
  /// Will throw [InvalidGenerationSourceError] if there's any issues with
  /// creating the struct.
  ///
  /// Expects the top level [element] to be a pure abstract class. Also expects
  /// all the methods to contain only required positional parameters, to return
  /// Futures, and to only use the data types directly supported by the method
  /// channel.
  ///
  /// Also expects [annotation] to have a set `'channelName'` `String` value.
  factory ParsedFlutterbuffApi.generate(
      Element element, ConstantReader annotation) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError('Can only target abstract classes.');
    }
    final ClassElement apiClassDef = element as ClassElement;
    if (!apiClassDef.isAbstract) {
      throw InvalidGenerationSourceError('Can only target abstract classes.');
    }

    final List<ParsedMethod> methods = apiClassDef.methods
        .map((MethodElement el) => ParsedMethod.generate(el))
        .toList();

    return ParsedFlutterbuffApi._(
        name: apiClassDef.name,
        methodChannelName: annotation.read('channelName').stringValue,
        methods: methods);
  }

  const ParsedFlutterbuffApi._(
      {this.name, this.methodChannelName, this.methods});

  /// The name of the API.
  ///
  /// This corresponds to the class name that was originally tagged with the
  /// annotation.
  final String name;

  /// The name of the MethodChannel to send calls on.
  final String methodChannelName;

  /// The list of methods on this API.
  final List<ParsedMethod> methods;
}

/// Represents a single method on a [ParsedFlutterbuffApi].
class ParsedMethod {
  /// Attempts to parse the given [method] into a [ParsedMethod].
  ///
  /// This has some stringent requirements on the [method].
  ///
  ///   - Must be abstract.
  ///   - Must return a Future.
  ///   - Must only use required, positional params.
  ///   - The return value of the Future and the type of any argument must match
  ///     a directly supported type for the platform channel.
  ///
  /// Will throw [InvalidGenerationSourceError] if there's any issues with
  /// creating the struct.
  factory ParsedMethod.generate(MethodElement method) {
    if (!method.isAbstract) {
      throw InvalidGenerationSourceError(
          'Can only target pure abstract classes. Found a non-abstract method "${method.name}"');
    }

    // All the methods should return a Future<T> of some kind. Assert first that
    // it's returning a future, then verify that T is parcelable across the
    // method channel.
    final DartType outerReturnType = method.returnType;
    if (!outerReturnType.isDartAsyncFuture) {
      throw InvalidGenerationSourceError(
          'All MethodChannel API methods must return Futures.');
    }
    final ArgType returnType = ArgType.generate(
        (outerReturnType as ParameterizedType).typeArguments.first);

    final List<Tuple2<ArgType, String>> args = <Tuple2<ArgType, String>>[];
    for (ParameterElement param in method.parameters) {
      if (!param.isRequiredPositional) {
        throw InvalidGenerationSourceError(
            'Can only use required positional parameters. Can\'t parse "${param.name}".');
      }
      args.add(
          Tuple2<ArgType, String>(ArgType.generate(param.type), param.name));
    }

    return ParsedMethod._(
        returnType: returnType, name: method.name, args: args);
  }

  const ParsedMethod._({this.returnType, this.name, this.args});

  final ArgType returnType;
  final String name;
  final List<Tuple2<ArgType, String>> args;
}

/// Language agnostic enum representation of all supported types.
enum SupportedType { DYNAMIC, VOID, NULL, BOOL, INT, DOUBLE, STRING, LIST, MAP }
const Map<SupportedType, String> supportedTypeEnumToDartName =
    <SupportedType, String>{
  SupportedType.DYNAMIC: 'dynamic',
  SupportedType.VOID: 'void',
  SupportedType.NULL: 'null',
  SupportedType.BOOL: 'bool',
  SupportedType.INT: 'int',
  SupportedType.DOUBLE: 'double',
  SupportedType.STRING: 'String',
  SupportedType.LIST: 'List',
  SupportedType.MAP: 'Map'
};
Map<String, SupportedType> dartNameToSupportedTypeEnum =
    supportedTypeEnumToDartName.map((SupportedType type, String dartName) =>
        MapEntry<String, SupportedType>(dartName, type));

/// Represents the Type of some data portion of an [ParsedMethod] signature.
///
/// This is guaranteed to be supported type from the method channel. https://flutter.dev/docs/development/platform-integration/platform-channels#platform-channel-data-types-support-and-codecs
class ArgType {
  /// Creates an [ArgType] from the given [DartType].
  ///
  /// Throws an [InvalidGenerationSourceError] if [type] isn't equivalent to one
  /// of the supported types.
  factory ArgType.generate(DartType type) {
    if (!dartNameToSupportedTypeEnum.containsKey(type.name)) {
      throw InvalidGenerationSourceError(
          'Can only use types directly supported by the platform channels. (https://flutter.dev/docs/development/platform-integration/platform-channels#platform-channel-data-types-support-and-codecs) Found "${type.displayName}".');
    }

    final List<ArgType> typeArgs = <ArgType>[];
    if (type is ParameterizedType) {
      // Make sure that the subtype for list and map are also supported.
      typeArgs.addAll((type as ParameterizedType)
          .typeArguments
          .map((DartType dartType) => ArgType.generate(dartType)));
    }

    final SupportedType supportedType = dartNameToSupportedTypeEnum[type.name];
    return ArgType._(type: supportedType, typeArguments: typeArgs);
  }

  const ArgType._({this.type, this.typeArguments});

  /// Language agnostic representation of the type.
  ///
  /// See https://flutter.dev/docs/development/platform-integration/platform-channels#platform-channel-data-types-support-and-codecs
  final SupportedType type;

  /// In the case of generics, the type arguments specified for the generic.
  ///
  /// For example, for `Map<int, bool>`, this would be a list of the
  /// corresponding ApiTypes for `int` and `bool`.
  ///
  /// This can be nested. For example, `Map<String, List<int>>>`.
  final List<ArgType> typeArguments;
}
