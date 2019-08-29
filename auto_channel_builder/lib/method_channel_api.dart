class Language {
  const Language({this.name, this.options});
  final String name;
  final LanguageOptions options;

  static const Language dart = Language(name: dartName);
}

abstract class LanguageOptions {
  const LanguageOptions();
}

/// Options for generating Java sources.
class JavaOptions extends LanguageOptions {
  const JavaOptions({this.packageName, this.outputDirectory});
  /// The package name for the generated files. (`com.example.TestPlugin`)
  final String packageName;
  /// The directory (relative to the package root) to write output to.
  final String outputDirectory;
}

const String javaName = 'Java';
const String dartName = 'Dart';
const List<String> supportedLanguages = <String>[
  javaName,
  dartName,
];

/// Annotation for a class that represents an API that crosses a MethodChannel boundary.
///
/// Use this in conjunction with the [AutoChannel] builder to automatically
/// generate the MethodChannel API bindings.
///
/// This should be tagged on an interface representing the MethodChannel
/// calls in a way that can be translated to arbitrary platforms and languages.
/// There are some extremely strict requirements on the class that this is
/// tagged on, or else generating the MethodChannel will fail.
///
/// 1. The class must be completely abstract. It only represents the API
///    signatures across the MethodChannel. This can't generate working
///    implementation details in multiple langauges for what to do when the API
///    call is actually made.
/// 2. Each method must return a Future. All MethodChannel calls are
///    asynchronous.
/// 3. Only positional, required parameters are supported. The method signatures
///    need to be consistent across all languages, and optional and named
///    parameters aren't universal langauge features.
/// 4. Only data types directly supported by the platform channel (
///    https://flutter.dev/docs/development/platform-integration/platform-channels#platform-channel-data-types-support-and-codecs)
///    can be used.
///
/// This is valid:
///
/// ```dart
///   @MethodChannelApi(channelName: 'foo_channel')
///   abstract class Foo {
///     Future<void> bar(List<int> baz, bool quux);
///   }
/// ```
///
/// This is not OK, since it doesn't return a Future:
///
/// ```dart
///   @MethodChannelApi(channelName: 'foo_channel')
///   abstract class Foo {
///     void bar(List<int> baz, bool quux);
///   }
/// ```
///
/// This is also not OK, since the method isn't abstract:
///
/// ```darLangauget
///   @MethodChannelApi(channelName: 'foo_channel')
///   abstract class Foo {
///     Future<void> bar(List<int> baz, bool quux) => print('hello world');
///   }
/// ```
///
/// This is also not OK, since it has an unsupported type:
///
/// ```dart
///   @MethodChannelApi(channelName: 'foo_channel')
///   abstract class Foo {
///     Future<void> bar(Baz baz);
///   }
/// ```
class MethodChannelApi {
  /// [channelName] is the `String` name of the MethodChannel underneath this API.
  const MethodChannelApi({this.channelName, this.invokers, this.listeners});
  final String channelName;
  /// The languages to generate invokers for.
  final List<Language> invokers;
  /// The langauges to generate listeners for.
  final List<Language> listeners;
}
