import 'package:path_provider/path_provider.dart';

Future<String> documentsFilePath(String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  return '${directory.path}/$fileName';
}

Future<bool> fileExists(String path) async => false;

Future<String> readFileAsString(String path) async {
  throw UnsupportedError('File storage is not supported on web');
}

Future<void> writeFileAsString(String path, String contents) async {}

Future<void> copyFile(String sourcePath, String destinationPath) async {}

Future<void> deleteFileIfExists(String path) async {}

Future<void> ensureDirectory(String path) async {}
