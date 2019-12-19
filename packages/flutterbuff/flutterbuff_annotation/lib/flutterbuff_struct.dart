/// Annotate abstract data classes with this to generate matching
/// representations in multiple langauges.
///
/// Expected to be applied to a private abstract class.
class FlutterbuffStruct {
  /// The annotation constructor. Can specify whether the attributes are
  /// nullable (defaults to false).
  const FlutterbuffStruct({this.nullable = false});

  /// Whether or not the keys are nullable. Defaults to false.
  final bool nullable;
}
