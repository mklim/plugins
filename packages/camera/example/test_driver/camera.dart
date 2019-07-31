import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  final Completer<String> completer = Completer<String>();
  enableFlutterDriverExtension(handler: (_) => completer.future);
  tearDownAll(() => completer.complete(null));

  final Map<ResolutionPreset, Point<int>> presetExpectedSizes = {
    ResolutionPreset.veryLow: const Point<int>(288, 352),
    ResolutionPreset.low: Platform.isAndroid ? const Point<int>(480, 720) : const Point<int>(480, 640),
    ResolutionPreset.medium: const Point<int>(720, 1280),
    ResolutionPreset.high: const Point<int>(1080, 1920),
    // Don't bother checking for veryHigh here since it could be anything.
    // ResolutionPreset.veryHigh: const Point<int>(2160, 3840),
  };

  // This tests that the capture is no bigger than the preset, since we have
  // automatic code to fall back to smaller sizes when we need to. Returns
  // whether the image is exactly the desired resolution.
  Future<bool> testStillCaptureResolution(CameraController controller, ResolutionPreset preset) async {
    // Take Picture
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Pictures/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final String filePath =
        '$dirPath/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await controller.takePicture(filePath);

    // Load taken image
    final FileImage fileImage = FileImage(File(filePath));
    final ImageStreamCompleter imageStreamCompleter =
        fileImage.load(await fileImage.obtainKey(ImageConfiguration.empty));
    final Completer<ImageInfo> imageLoadedComplete = Completer<ImageInfo>();
    imageStreamCompleter
        .addListener(ImageStreamListener((ImageInfo image, bool _) {
      imageLoadedComplete.complete(image);
    }));
    final ImageInfo imageInfo = await imageLoadedComplete.future;
    await File(filePath).delete();

    // Make sure image dimensions are correct. We don't care about portrait vs
    // landscape, so just get min vs max.
    final Point<int> expectedSize = presetExpectedSizes[preset];
    print('Test capturing $preset (${expectedSize.x}x${expectedSize.y}) using camera ${controller.description.name}');
    expect(imageInfo.image, isNotNull);
    final int minDimen = min(imageInfo.image.height, imageInfo.image.width);
    final int maxDimen = max(imageInfo.image.height, imageInfo.image.width);
    expect(minDimen, lessThanOrEqualTo(expectedSize.x));
    expect(maxDimen, lessThanOrEqualTo(expectedSize.y));
    return minDimen == expectedSize.x && maxDimen == expectedSize.y;
  }

  test('Capture specific resolutions', () async {
    final List<CameraDescription> cameras = await availableCameras();
    if (cameras.isEmpty) {
      return;
    }
    for (CameraDescription cameraDescription in cameras) {
      bool previousPresetExactlySupported = true;
      for (MapEntry<ResolutionPreset, Point<int>> preset in presetExpectedSizes.entries) {
        final CameraController controller = CameraController(cameraDescription, preset.key);
        await controller.initialize();
        final bool presetExactlySupported = await testStillCaptureResolution(controller, preset.key);
        assert(!(!previousPresetExactlySupported && previousPresetExactlySupported),
          'The camera took higher resolution pictures at a lower resolution.');
        previousPresetExactlySupported = presetExactlySupported;
        await controller.dispose();
      }
    }
  });
}
