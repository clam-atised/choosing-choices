import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:choices/platform/file_storage.dart';

Uint8List _loadTestImageBytes() {
  return File('test/fixtures/test_image.png').readAsBytesSync();
}

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.rootPath);

  final String rootPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => rootPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('saveImageBytes', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('choices_image_test');
      PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('writes image bytes to the card_images directory', () async {
      final bytes = _loadTestImageBytes();
      final savedPath = await saveImageBytes(bytes, extension: 'png');

      expect(savedPath, contains('/card_images/card_'));
      expect(savedPath.endsWith('.png'), isTrue);
      expect(await File(savedPath).exists(), isTrue);
      expect(await File(savedPath).readAsBytes(), bytes);
    });
  });
}
