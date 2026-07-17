import 'dart:js_interop';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:web/web.dart' as web;

Future<String> documentsFilePath(String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  return '${directory.path}/$fileName';
}

Future<bool> fileExists(String path) async => false;

Future<String> readFileAsString(String path) async {
  throw UnsupportedError('File storage is not supported on web');
}

Future<Uint8List> readFileAsBytes(String path) async {
  throw UnsupportedError('File storage is not supported on web');
}

Future<void> writeFileAsString(String path, String contents) async {}

Future<void> copyFile(String sourcePath, String destinationPath) async {}

Future<void> deleteFileIfExists(String path) async {}

Future<void> ensureDirectory(String path) async {}

Future<String> saveImageBytes(
  Uint8List bytes, {
  String extension = 'jpg',
}) async {
  final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  return web.URL.createObjectURL(blob);
}
