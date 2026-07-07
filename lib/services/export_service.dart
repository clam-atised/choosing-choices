import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/category_item.dart';
import '../models/export_format.dart';

class ExportService {
  ExportService._();

  static final ExportService instance = ExportService._();

  Future<void> exportFolder(Folder folder, ExportFormat format) async {
    final fileName = _sanitizeFileName(folder.name);
    final bytes = await _folderContent(folder, format);
    await _shareBytes(
      bytes: bytes,
      fileName: '$fileName.${format.fileExtension}',
      format: format,
    );
  }

  Future<void> exportItem(
    Folder folder,
    CategoryItem item,
    ExportFormat format,
  ) async {
    final fileName = _sanitizeFileName('${folder.name}_${item.name}');
    final bytes = await _itemContent(folder, item, format);
    await _shareBytes(
      bytes: bytes,
      fileName: '$fileName.${format.fileExtension}',
      format: format,
    );
  }

  Future<void> _shareBytes({
    required List<int> bytes,
    required String fileName,
    required ExportFormat format,
  }) async {
    await Share.shareXFiles(
      [
        XFile.fromData(
          Uint8List.fromList(bytes),
          name: fileName,
          mimeType: _mimeType(format),
        ),
      ],
      subject: fileName,
    );
  }

  Future<List<int>> _folderContent(Folder folder, ExportFormat format) {
    return switch (format) {
      ExportFormat.pdf => _buildPdfBytes(
          title: folder.name,
          lines: folder.items.map((item) => item.name).toList(),
        ),
      ExportFormat.markdown => Future.value(
          _encodeText(_folderMarkdown(folder)),
        ),
      ExportFormat.csv => Future.value(
          _encodeText(_folderCsv(folder)),
        ),
      ExportFormat.word => Future.value(
          _encodeText(_folderRtf(folder)),
        ),
    };
  }

  Future<List<int>> _itemContent(
    Folder folder,
    CategoryItem item,
    ExportFormat format,
  ) {
    return switch (format) {
      ExportFormat.pdf => _buildPdfBytes(
          title: item.name,
          lines: [
            'Folder: ${folder.name}',
            'Display: ${item.cardDisplayDirection.name}',
          ],
        ),
      ExportFormat.markdown => Future.value(
          _encodeText(_itemMarkdown(folder, item)),
        ),
      ExportFormat.csv => Future.value(
          _encodeText(_itemCsv(folder, item)),
        ),
      ExportFormat.word => Future.value(
          _encodeText(_itemRtf(folder, item)),
        ),
    };
  }

  Future<List<int>> _buildPdfBytes({
    required String title,
    required List<String> lines,
  }) async {
    final document = pw.Document();
    document.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title, style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 16),
              for (final line in lines) pw.Bullet(text: line),
            ],
          );
        },
      ),
    );
    return document.save();
  }

  String _folderMarkdown(Folder folder) {
    final buffer = StringBuffer('# ${folder.name}\n\n');
    for (final item in folder.items) {
      buffer.writeln('- ${item.name}');
    }
    return buffer.toString();
  }

  String _folderCsv(Folder folder) {
    final buffer = StringBuffer('folder,item\n');
    for (final item in folder.items) {
      buffer.writeln('${_escapeCsv(folder.name)},${_escapeCsv(item.name)}');
    }
    return buffer.toString();
  }

  String _folderRtf(Folder folder) {
    final buffer = StringBuffer(r'{\rtf1\ansi ');
    buffer.write(r'{\b ');
    buffer.write(folder.name);
    buffer.write(r'}\par ');
    for (final item in folder.items) {
      buffer.write(r'\bullet ');
      buffer.write(item.name);
      buffer.write(r'\par ');
    }
    buffer.write('}');
    return buffer.toString();
  }

  String _itemMarkdown(Folder folder, CategoryItem item) {
    return '# ${item.name}\n\n'
        '- Folder: ${folder.name}\n'
        '- Display: ${item.cardDisplayDirection.name}\n';
  }

  String _itemCsv(Folder folder, CategoryItem item) {
    return 'folder,item,direction\n'
        '${_escapeCsv(folder.name)},${_escapeCsv(item.name)},'
        '${item.cardDisplayDirection.name}\n';
  }

  String _itemRtf(Folder folder, CategoryItem item) {
    return r'{\rtf1\ansi {\b ' +
        item.name +
        r'}\par Folder: ' +
        folder.name +
        r'\par Display: ' +
        item.cardDisplayDirection.name +
        r'\par }';
  }

  List<int> _encodeText(String content) => utf8.encode(content);

  String _escapeCsv(String value) => '"${value.replaceAll('"', '""')}"';

  String _sanitizeFileName(String value) {
    return value.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  }

  String _mimeType(ExportFormat format) {
    return switch (format) {
      ExportFormat.pdf => 'application/pdf',
      ExportFormat.markdown => 'text/markdown',
      ExportFormat.csv => 'text/csv',
      ExportFormat.word => 'application/msword',
    };
  }
}
