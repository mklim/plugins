import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';
import 'package:tuple/tuple.dart';

import 'types.dart';

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
    final FullType returnType = FullType.generate(
        (outerReturnType as ParameterizedType).typeArguments.first);

    final List<Tuple2<FullType, String>> args = <Tuple2<FullType, String>>[];
    for (ParameterElement param in method.parameters) {
      if (!param.isRequiredPositional) {
        throw InvalidGenerationSourceError(
            'Can only use required positional parameters. Can\'t parse "${param.name}".');
      }
      args.add(
          Tuple2<FullType, String>(FullType.generate(param.type), param.name));
    }

    return ParsedMethod._(
        returnType: returnType, name: method.name, args: args);
  }

  const ParsedMethod._({this.returnType, this.name, this.args});

  final FullType returnType;
  final String name;
  final List<Tuple2<FullType, String>> args;
}
