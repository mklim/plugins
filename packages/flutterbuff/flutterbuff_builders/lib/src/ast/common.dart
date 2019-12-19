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
