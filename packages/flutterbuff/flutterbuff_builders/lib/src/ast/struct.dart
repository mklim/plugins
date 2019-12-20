import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

import 'types.dart';

/// Represents an API that crosses the MethodChannel boundary.
class ParsedFlutterbuffStruct {
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
  factory ParsedFlutterbuffStruct.generate(
      Element element, ConstantReader annotation) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError('Can only target abstract classes.');
    }
    final ClassElement apiClassDef = element as ClassElement;
    final List<ParsedField> fields = apiClassDef.fields
        .map((FieldElement el) => ParsedField.generate(el))
        .toList();

    return ParsedFlutterbuffStruct._(name: apiClassDef.name, fields: fields);
  }

  const ParsedFlutterbuffStruct._({this.name, this.fields});

  /// The name of the API.
  ///
  /// This corresponds to the class name that was originally tagged with the
  /// annotation.
  final String name;

  /// The list of fields on this api.
  final List<ParsedField> fields;
}

class ParsedField {
  factory ParsedField.generate(FieldElement field) => ParsedField._(
      name: field.name, type: FullType.generate(field.type), nullable: false);
  ParsedField._({this.name, this.type, this.nullable});

  final String name;
  final FullType type;
  final bool nullable;
}
