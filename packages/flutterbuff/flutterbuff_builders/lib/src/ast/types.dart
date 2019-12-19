import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

/// Language agnostic enum representation of all supported types.
///
/// This is a flat set of simple constants, So while we support a
/// `List<list<int>>`, here there is only an etnry for `LIST` and `INT`.
enum SimpleType { DYNAMIC, VOID, NULL, BOOL, INT, DOUBLE, STRING, LIST, MAP }
const Map<SimpleType, String> supportedTypeEnumToDartName =
    <SimpleType, String>{
  SimpleType.DYNAMIC: 'dynamic',
  SimpleType.VOID: 'void',
  SimpleType.NULL: 'null',
  SimpleType.BOOL: 'bool',
  SimpleType.INT: 'int',
  SimpleType.DOUBLE: 'double',
  SimpleType.STRING: 'String',
  SimpleType.LIST: 'List',
  SimpleType.MAP: 'Map'
};
Map<String, SimpleType> dartNameToSupportedTypeEnum =
    supportedTypeEnumToDartName.map((SimpleType type, String dartName) =>
        MapEntry<String, SimpleType>(dartName, type));

/// Represents the full type of some actual method signature or field.
///
/// This is guaranteed to be supported type from the method channel. https://flutter.dev/docs/development/platform-integration/platform-channels#platform-channel-data-types-support-and-codecs
///
/// In cases where the type is a generic, its full list of type arguments is
/// contained in the field [typeArgumetns].
class FullType {
  /// Creates an [FullType] from the given [DartType].
  ///
  /// Throws an [InvalidGenerationSourceError] if [type] isn't equivalent to one
  /// of the supported types.
  factory FullType.generate(DartType type) {
    if (!dartNameToSupportedTypeEnum.containsKey(type.name)) {
      throw InvalidGenerationSourceError(
          'Can only use types directly supported by the platform channels. (https://flutter.dev/docs/development/platform-integration/platform-channels#platform-channel-data-types-support-and-codecs) Found "${type.displayName}".');
    }

    final List<FullType> typeArgs = <FullType>[];
    if (type is ParameterizedType) {
      // Make sure that the subtype for list and map are also supported.
      typeArgs.addAll((type as ParameterizedType)
          .typeArguments
          .map((DartType dartType) => FullType.generate(dartType)));
    }

    final SimpleType supportedType = dartNameToSupportedTypeEnum[type.name];
    return FullType._(type: supportedType, typeArguments: typeArgs);
  }

  const FullType._({this.type, this.typeArguments});

  /// Language agnostic representation of the type.
  ///
  /// See https://flutter.dev/docs/development/platform-integration/platform-channels#platform-channel-data-types-support-and-codecs
  final SimpleType type;

  /// In the case of generics, the type arguments specified for the generic.
  ///
  /// For example, for `Map<int, bool>`, this would be a list of the
  /// corresponding ApiTypes for `int` and `bool`.
  ///
  /// This can be nested. For example, `Map<String, List<int>>>`.
  final List<FullType> typeArguments;
}
