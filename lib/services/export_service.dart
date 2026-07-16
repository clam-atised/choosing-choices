import 'dart:convert';
// import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../data/cards_repository.dart';
import '../models/category_item.dart';
import '../models/choice_card.dart';
import '../utils/detail_field_formatters.dart';
import '../models/export_format.dart';
import '../platform/file_storage.dart';

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
    final cards = CardsRepository.instance.cardsForCategory(folder.id, item.id);
    final fileName = _sanitizeFileName('${folder.name}_${item.name}');
    final bytes = await _itemContent(item, cards, format);
    await _shareBytes(
      bytes: bytes,
      fileName: '$fileName.${format.fileExtension}',
      format: format,
    );
  }

  @visibleForTesting
  Future<List<int>> buildItemExportBytes(
    CategoryItem item,
    List<ChoiceCard> cards,
    ExportFormat format,
  ) {
    return _itemContent(item, cards, format);
  }

  Future<void> _shareBytes({
    required List<int> bytes,
    required String fileName,
    required ExportFormat format,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(bytes),
            name: fileName,
            mimeType: _mimeType(format),
          ),
        ],
        subject: fileName,
      ),
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
    CategoryItem item,
    List<ChoiceCard> cards,
    ExportFormat format,
  ) {
    return switch (format) {
      ExportFormat.pdf => _buildItemPdfBytes(title: item.name, cards: cards),
      ExportFormat.markdown => Future.value(
          _encodeText(_itemMarkdown(item, cards)),
        ),
      ExportFormat.csv => Future.value(
          _encodeText(_itemCsv(item, cards)),
        ),
      ExportFormat.word => Future.value(
          _encodeText(_itemRtf(item, cards)),
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

  Future<List<int>> _buildItemPdfBytes({
    required String title,
    required List<ChoiceCard> cards,
  }) async {
    final cardWidgets = <pw.Widget>[];
    for (final card in cards) {
      cardWidgets.addAll(await _cardPdfWidgets(card));
    }

    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        build: (context) => [
          pw.Text(title, style: pw.TextStyle(fontSize: 24)),
          pw.SizedBox(height: 16),
          if (cards.isEmpty) pw.Text('No cards yet.'),
          ...cardWidgets,
        ],
      ),
    );
    return document.save();
  }

  Future<List<pw.Widget>> _cardPdfWidgets(ChoiceCard card) async {
    final widgets = <pw.Widget>[
      pw.Text(
        card.title,
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 8),
    ];

    for (final detail in card.details) {
      if (detail.label.trim().isEmpty) {
        continue;
      }
      widgets.add(
        pw.Bullet(text: formatDetailLine(detail)),
      );
    }

    final imagePath = card.imagePath;
    if (imagePath != null && !kIsWeb) {
      try {
        final bytes = await readFileAsBytes(imagePath);
        widgets
          ..add(pw.SizedBox(height: 8))
          ..add(pw.Image(pw.MemoryImage(bytes), width: 110));
      } catch (_) {
        // Skip images that cannot be read.
      }
    }

    widgets.add(pw.SizedBox(height: 16));
    return widgets;
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

  String _itemMarkdown(CategoryItem item, List<ChoiceCard> cards) {
    final buffer = StringBuffer('# ${item.name}\n\n');
    if (cards.isEmpty) {
      buffer.writeln('No cards yet.');
      return buffer.toString();
    }

    for (final card in cards) {
      buffer.writeln('## ${card.title}\n');
      for (final detail in card.details) {
        if (detail.label.trim().isEmpty) {
          continue;
        }
        buffer.writeln('- ${formatDetailLine(detail)}');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  String _itemCsv(CategoryItem item, List<ChoiceCard> cards) {
    final buffer = StringBuffer('item,card,field,value\n');
    if (cards.isEmpty) {
      buffer.writeln('${_escapeCsv(item.name)},,,');
      return buffer.toString();
    }

    for (final card in cards) {
      for (final detail in card.details) {
        if (detail.label.trim().isEmpty) {
          continue;
        }
        buffer.writeln(
          '${_escapeCsv(item.name)},'
          '${_escapeCsv(card.title)},'
          '${_escapeCsv(detail.label)},'
          '${_escapeCsv(_detailValue(detail))}',
        );
      }
    }
    return buffer.toString();
  }

  String _itemRtf(CategoryItem item, List<ChoiceCard> cards) {
    final buffer = StringBuffer(r'{\rtf1\ansi {\b ');
    buffer.write(item.name);
    buffer.write(r'}\par ');

    if (cards.isEmpty) {
      buffer.write('No cards yet.');
    } else {
      for (final card in cards) {
        buffer.write(r'{\b ');
        buffer.write(card.title);
        buffer.write(r'}\par ');
        for (final detail in card.details) {
          if (detail.label.trim().isEmpty) {
            continue;
          }
          buffer.write(r'\bullet ');
          buffer.write(formatDetailLine(detail));
          buffer.write(r'\par ');
        }
        buffer.write(r'\par ');
      }
    }

    buffer.write('}');
    return buffer.toString();
  }

  String _detailValue(CardDetailField detail) => detailFieldDisplayValue(detail);

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
