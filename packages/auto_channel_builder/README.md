# auto_channel_builder

Experimental draft of generating MethodChannel handlers for plugins.

This is a very rough draft and has some terrible flaws based on its reliance on
`dart-lang/build`. Normally `build` can only write to the same source directory
as its input files, but the output here needs to be spread across the directory
structure of a plugin. To work around it this is creating symlinks on the side
to point back to the generated files. The links are _not_ cleaned up when the
build system deletes the files (eg, on rename).