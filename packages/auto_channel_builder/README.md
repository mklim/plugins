# auto_channel_builder

Experimental draft for generating MethodChannel handlers for plugins.

Define the MethodChannel API surface with a `@MethodChannelApi` annotation first
to use this.

This is a rough proof of concept, and certainly buggy and incomplete.

## How to use

Let's assume a desired API similar to the default `flutter create` plugin
template, with a method to `getPlatformVersion`.

First, create a completely abstract dart class tagged with `@MethodChannelApi`
describing the API.

```dart
import 'package:auto_channel_builder/annotation/method_channel_api.dart';

@MethodChannelApi(
  channelName: 'test_plugin', // String name of the MethodChannel.
  invokers: <Language>[Language.dart], // Languages that make calls on the channel.
  // Languages that listen for calls on the channel.
  handlers: <Language>[
    Language(
        name: javaName,
        options: JavaOptions(basePackageName: 'com.example.test_plugin'))
  ],
)
abstract class TestPluginApi {
  Future<String> getPlatformVersion();
}

```

Run the builder: `flutter pub run build_runner build`.

This should generate the boilerplate needed to make MethodChannel calls for the
given `@MethodChannelApi`. For the above example, it would make:

- A `TestPluginApiInvoker` Dart class that implements `TestPluginApi`. It
  internally has several `_methodChannel.invokeMethod` calls matching the
  methods as defined in the API, and relies on those calls to provide any
  output.
- A `TestPluginApi` Java interface that mirrors the Dart `@MethodChannelApi`
  one.
- a `TestPluginApiHandler` Java class that needs a `TestPluginApi`
  implementation when constructed, and listens for MethodChannel calls with
  names, arguments, and return types matching `TestPluginApi` methods. It
  automatically listens for calls, parses arguments, forwards them to matching
  methods on the impl, and then forwards the output of the impl back to the
  calls.

From there there's two major things left to do:

- Write a `TestPluginApi` Java interface implementation that actually does
  whatever it is you expect the methods to do when called. In the sample case
  that would be returning the OS version for `getPlatformVersion`.
- Update `registerWith` to return a new `TestPluginApiHandler` instance using
  a new instance of your custom `TestPlugin` interface implementation.

That's it! From then on, Flutter code can call to the platform by instantiating
`TestPluginApiInvoker` and calling any of the methods directly. Additional
methods can be added to the `@MethodChannelApi` at any point and the code
regenerated with `build_runner` to automatically wire in more methods. (You'll
still need to update the custom interface implementation to do whatever it is
you actually want these methods to achieve, though!)

There's an example repo using this on
[Github](https://github.com/mklim/test_plugin/compare/auto_channel).

## Limitations

This is an early prototype that can only generate Dart classes that call across
the method boundary and Java classes that listen for calls across the method
boundary. Callers and handlers in these and more languages should eventually
follow.

This relies on some workarounds for its reliance on `dart-lang/build`. Normally
`build` can only be used to generate files to the `lib` directory, preferably
Dart ones. This Builder takes advantage of the `PostProcess` step to copy any
non-Dart files out from `lib/` into platform specific, generated directories.
The generated directories are completely deleted and recreated each build cycle
to make sure that outdated artifacts are removed.

This code generation _only_ handles the MethodChannel API boilerplate. It
doesn't have the ability to automatically generate code parsing complicated data
classes across the boundary. It will fail to compile if there are any types in
the method signatures that can't be automatically handled by the MethodChannel
already. See
[flutter.dev](https://flutter.dev/docs/development/platform-integration/platform-channels#platform-channel-data-types-support-and-codecs)
for a list of supported types.