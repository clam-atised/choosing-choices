import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:choices/models/category_item.dart';
import 'package:choices/models/choice_card.dart';
import 'package:choices/models/export_format.dart';
import 'package:choices/services/export_service.dart';

void main() {
  const item = CategoryItem(id: 'japan_stay', name: 'Where to stay');
  const cards = [
    ChoiceCard(
      id: 'card_1',
      folderId: 'trip_to_japan',
      categoryItemId: 'japan_stay',
      title: 'Hotel Osaka',
      details: [
        CardDetailField(
          id: 'detail_1',
          label: 'Location',
          type: DetailFieldType.text,
          textValue: 'Osaka, Japan',
        ),
        CardDetailField(
          id: 'detail_2',
          label: 'Recommended',
          type: DetailFieldType.yesNo,
          yesNoValue: true,
        ),
      ],
    ),
  ];

  test('item markdown export includes card contents not settings', () async {
    final bytes = await ExportService.instance.buildItemExportBytes(
      item,
      cards,
      ExportFormat.markdown,
    );
    final content = utf8.decode(bytes);

    expect(content, contains('# Where to stay'));
    expect(content, contains('## Hotel Osaka'));
    expect(content, contains('- Location: Osaka, Japan'));
    expect(content, contains('- Recommended: Yes'));
    expect(content, isNot(contains('Display:')));
    expect(content, isNot(contains('Folder:')));
  });

  test('item csv export includes card field rows', () async {
    final bytes = await ExportService.instance.buildItemExportBytes(
      item,
      cards,
      ExportFormat.csv,
    );
    final content = utf8.decode(bytes);

    expect(content, contains('item,card,field,value'));
    expect(
      content,
      contains('"Where to stay","Hotel Osaka","Location","Osaka, Japan"'),
    );
    expect(
      content,
      contains('"Where to stay","Hotel Osaka","Recommended","Yes"'),
    );
  });

  test('item pdf export produces pdf bytes', () async {
    final bytes = await ExportService.instance.buildItemExportBytes(
      item,
      cards,
      ExportFormat.pdf,
    );

    expect(bytes.length, greaterThan(4));
    expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
  });

  test('item export handles empty cards', () async {
    final bytes = await ExportService.instance.buildItemExportBytes(
      item,
      const [],
      ExportFormat.markdown,
    );
    final content = utf8.decode(bytes);

    expect(content, contains('No cards yet.'));
  });
}
