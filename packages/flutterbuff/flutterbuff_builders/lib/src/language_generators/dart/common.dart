import '../../ast/types.dart';

String fullTypeString(FullType type) {
  final String parameters = type.typeArguments.map(fullTypeString).join(', ');
  if (parameters == null || parameters.isEmpty) {
    return supportedTypeEnumToDartName[type.type];
  } else {
    return '${supportedTypeEnumToDartName[type.type]}<$parameters>';
  }
}
