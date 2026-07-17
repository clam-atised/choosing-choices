import 'dart:io';
import 'dart:typed_data';

import 'package:choices/widgets/image_crop_page.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

Uint8List _loadTestImageBytes() {
  return File('test/fixtures/test_image.png').readAsBytesSync();
}

Widget _wrapCropPage(
  Uint8List imageBytes, {
  ImageCropper? debugImageCropper,
}) {
  return MaterialApp(
    home: ImageCropPage(
      imageBytes: imageBytes,
      debugImageCropper: debugImageCropper,
    ),
  );
}

class _FailureCropper extends ImageCropper {
  @override
  CircleCropper get circleCropper => throw UnimplementedError();

  @override
  RectCropper get rectCropper => throw UnimplementedError();

  @override
  RectValidator get rectValidator =>
      (_, _, _) => Exception('crop failed');
}

Future<void> _setTestSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _waitForSaveEnabled(WidgetTester tester) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    final saveButtons = tester.widgetList<FilledButton>(
      find.byKey(const Key('image_crop_save')),
    );
    if (saveButtons.any((button) => button.onPressed != null)) {
      return;
    }
  }

  fail('Save button never became enabled.');
}

Future<void> _tapSave(WidgetTester tester) async {
  await _waitForSaveEnabled(tester);
  final saveButton = find.byKey(const Key('image_crop_save'));
  await tester.ensureVisible(saveButton);
  await tester.tap(saveButton);
}

Future<void> _openCropPage(
  WidgetTester tester,
  Uint8List imageBytes,
) async {
  await tester.tap(find.text('Open crop'));
  await pumpUi(tester);
}

void main() {
  late Uint8List testImageBytes;

  setUpAll(() {
    testImageBytes = _loadTestImageBytes();
  });

  setUp(() async {
    await configureRepositoriesForTesting();
  });

  testWidgets('defaults to full image mode with the whole image visible',
      (tester) async {
    await _setTestSurface(tester);
    await tester.pumpWidget(_wrapCropPage(testImageBytes));
    await pumpUi(tester);

    expect(find.byKey(const Key('image_crop_full_preview')), findsOneWidget);
    expect(find.byType(Crop), findsNothing);
    expect(find.text('Full image'), findsOneWidget);
    expect(find.text('The entire image will be saved.'), findsOneWidget);

    final saveButton = tester.widget<FilledButton>(
      find.byKey(const Key('image_crop_save')),
    );
    expect(saveButton.onPressed, isNotNull);
  });

  testWidgets('switches to fixed crop mode', (tester) async {
    await _setTestSurface(tester);
    await tester.pumpWidget(_wrapCropPage(testImageBytes));
    await pumpUi(tester);

    await tester.tap(find.text('Crop 3:4'));
    await pumpUi(tester);

    expect(find.byType(Crop), findsOneWidget);
    expect(find.byKey(const Key('image_crop_full_preview')), findsNothing);
    expect(
      find.text('Drag to move the image. Pinch or scroll to zoom.'),
      findsOneWidget,
    );
  });

  testWidgets('save in full image mode returns original bytes',
      (tester) async {
    await _setTestSurface(tester);
    ImageCropPageResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                result = await showImageCropPage(
                  context,
                  imageBytes: testImageBytes,
                );
              },
              child: const Text('Open crop'),
            );
          },
        ),
      ),
    );
    await pumpUi(tester);
    await _openCropPage(tester, testImageBytes);

    await _tapSave(tester);
    await pumpUi(tester);

    expect(result, isNotNull);
    expect(result!.bytes, testImageBytes);
  });

  testWidgets('save in crop mode returns cropped bytes', (tester) async {
    await _setTestSurface(tester);
    ImageCropPageResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                result = await showImageCropPage(
                  context,
                  imageBytes: testImageBytes,
                );
              },
              child: const Text('Open crop'),
            );
          },
        ),
      ),
    );
    await pumpUi(tester);
    await _openCropPage(tester, testImageBytes);

    await tester.tap(find.text('Crop 3:4'));
    await _waitForSaveEnabled(tester);

    await _tapSave(tester);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await pumpUi(tester);

    expect(result, isNotNull);
    expect(result!.bytes, isNot(equals(testImageBytes)));
    expect(result!.bytes, isNotEmpty);
  });

  testWidgets('crop failure keeps the page open and shows feedback',
      (tester) async {
    await _setTestSurface(tester);
    await tester.pumpWidget(
      _wrapCropPage(
        testImageBytes,
        debugImageCropper: _FailureCropper(),
      ),
    );
    await pumpUi(tester);

    await tester.tap(find.text('Crop 3:4'));
    await _waitForSaveEnabled(tester);

    await _tapSave(tester);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await pumpUi(tester);

    expect(find.byType(ImageCropPage), findsOneWidget);
    expect(
      find.text('Could not crop image. Please try again.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('image_crop_save')), findsOneWidget);
  });
}
