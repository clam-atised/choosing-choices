import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<String?> saveBackupZip({
  required List<int> bytes,
  required String fileName,
}) async {
  final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  final savedPath = await FilePicker.saveFile(
    fileName: fileName,
    bytes: data,
    type: FileType.custom,
    allowedExtensions: ['zip'],
  );
  if (savedPath != null) {
    return fileName;
  }

  final tempDir = await getTemporaryDirectory();
  final tempFile = File('${tempDir.path}/$fileName');
  await tempFile.writeAsBytes(data, flush: true);

  final downloadsDir = await getDownloadsDirectory();
  if (downloadsDir != null) {
    final downloadsFile = File('${downloadsDir.path}/$fileName');
    await downloadsFile.writeAsBytes(data, flush: true);
    return downloadsFile.path.split(Platform.pathSeparator).last;
  }

  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile(tempFile.path, mimeType: 'application/zip', name: fileName),
      ],
      subject: 'Choices backup',
      text: 'Save this backup file to restore your data later.',
    ),
  );
  return fileName;
}

Future<List<int>?> pickBackupZip() async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['zip'],
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;

  final file = result.files.first;
  if (file.bytes != null) {
    return file.bytes;
  }

  final path = file.path;
  if (path == null) return null;
  return File(path).readAsBytes();
}

Future<String> writeRestoredCardImage({
  required String cardId,
  required List<int> bytes,
  required String extension,
}) async {
  final docsDir = await getApplicationDocumentsDirectory();
  final imagesDir = Directory('${docsDir.path}/card_images');
  if (!await imagesDir.exists()) {
    await imagesDir.create(recursive: true);
  }

  final safeExtension = extension.isEmpty ? 'jpg' : extension;
  final file = File('${imagesDir.path}/$cardId.$safeExtension');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
