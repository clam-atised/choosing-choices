import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String> documentsFilePath(String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  return '${directory.path}/$fileName';
}

Future<bool> fileExists(String path) => File(path).exists();

Future<String> readFileAsString(String path) => File(path).readAsString();

Future<Uint8List> readFileAsBytes(String path) => File(path).readAsBytes();

Future<void> writeFileAsString(String path, String contents) =>
    File(path).writeAsString(contents);

Future<void> copyFile(String sourcePath, String destinationPath) =>
    File(sourcePath).copy(destinationPath);

Future<void> deleteFileIfExists(String path) async {
  final file = File(path);
  if (await file.exists()) {
    await file.delete();
  }
}

Future<void> ensureDirectory(String path) async {
  final directory = Directory(path);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
}

Future<String> saveImageBytes(
  Uint8List bytes, {
  String extension = 'jpg',
}) async {
  final directory = await getApplicationDocumentsDirectory();
  const imagesDirName = 'card_images';
  final imagesDirPath = '${directory.path}/$imagesDirName';
  await ensureDirectory(imagesDirPath);

  final destinationPath =
      '$imagesDirPath/card_${DateTime.now().microsecondsSinceEpoch}.$extension';
  await File(destinationPath).writeAsBytes(bytes, flush: true);
  return destinationPath;
}
