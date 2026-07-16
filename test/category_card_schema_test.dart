import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:choices/data/cards_repository.dart';
import 'package:choices/data/folders_repository.dart';
import 'package:choices/models/category_detail_definition.dart';
import 'package:choices/models/choice_card.dart';
import 'package:choices/services/category_schema_service.dart';
import 'package:choices/widgets/item_settings_dialog.dart';
import 'test_helpers.dart';

void main() {
  setUp(() async {
    await configureRepositoriesForTesting();
  });

  testWidgets('item settings shows Category and Card tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  showItemSettingsDialog(
                    context,
                    folderId: FoldersRepository.seedFolderId,
                    itemId: 'places_to_visit',
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );
    await pumpUi(tester);

    await tester.tap(find.text('Open'));
    await pumpUi(tester);

    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Card'), findsOneWidget);
    expect(find.text('Card display direction:'), findsOneWidget);
    expect(find.text('Delete item & contents'), findsOneWidget);

    await tester.tap(find.text('Card'));
    await pumpUi(tester);

    expect(find.text('Location'), findsWidgets);
    expect(find.text('Text'), findsWidgets);
    expect(find.text('Accessible by train'), findsOneWidget);
    expect(find.text('Yes/No'), findsOneWidget);
    expect(find.text('Add detail'), findsOneWidget);
  });

  test('reorder definitions cascades to card detail order', () async {
    final schema = CategorySchemaService.instance;
    final item = FoldersRepository.instance.itemById(
      FoldersRepository.seedFolderId,
      'places_to_visit',
    )!;
    final reversed = item.detailDefinitions.reversed.toList();

    await schema.reorderDefinitions(
      folderId: FoldersRepository.seedFolderId,
      itemId: 'places_to_visit',
      definitions: reversed,
    );

    final updatedItem = FoldersRepository.instance.itemById(
      FoldersRepository.seedFolderId,
      'places_to_visit',
    )!;
    expect(
      updatedItem.detailDefinitions.map((d) => d.id).toList(),
      reversed.map((d) => d.id).toList(),
    );

    final card = CardsRepository.instance
        .cardsForCategory(FoldersRepository.seedFolderId, 'places_to_visit')
        .first;
    expect(
      card.details.take(reversed.length).map((d) => d.id).toList(),
      reversed.map((d) => d.id).toList(),
    );
  });

  test('add definition appends to schema and all cards', () async {
    final schema = CategorySchemaService.instance;
    const definition = CategoryDetailDefinition(
      id: 'places_notes',
      label: 'Notes',
      type: DetailFieldType.text,
    );

    await schema.addDefinition(
      folderId: FoldersRepository.seedFolderId,
      itemId: 'places_to_visit',
      definition: definition,
    );

    final item = FoldersRepository.instance.itemById(
      FoldersRepository.seedFolderId,
      'places_to_visit',
    )!;
    expect(item.detailDefinitions.last.id, 'places_notes');

    final cards = CardsRepository.instance.cardsForCategory(
      FoldersRepository.seedFolderId,
      'places_to_visit',
    );
    expect(cards, isNotEmpty);
    for (final card in cards) {
      expect(
        card.details.any((detail) => detail.id == 'places_notes'),
        isTrue,
      );
    }
  });

  test('delete definition removes schema field and card data', () async {
    final schema = CategorySchemaService.instance;
    const definitionId = 'places_description';

    await schema.deleteDefinition(
      folderId: FoldersRepository.seedFolderId,
      itemId: 'places_to_visit',
      definitionId: definitionId,
    );

    final item = FoldersRepository.instance.itemById(
      FoldersRepository.seedFolderId,
      'places_to_visit',
    )!;
    expect(
      item.detailDefinitions.any((d) => d.id == definitionId),
      isFalse,
    );

    final cards = CardsRepository.instance.cardsForCategory(
      FoldersRepository.seedFolderId,
      'places_to_visit',
    );
    for (final card in cards) {
      expect(
        card.details.any((detail) => detail.id == definitionId),
        isFalse,
      );
    }
  });

  test('dropdown option remove clears selected value on cards', () async {
    final schema = CategorySchemaService.instance;
    CardsRepository.instance.clearCardsForTesting();

    await FoldersRepository.instance.updateItemDetailDefinitions(
      FoldersRepository.seedFolderId,
      'places_to_visit',
      const [
        CategoryDetailDefinition(
          id: 'places_tag',
          label: 'Tag',
          type: DetailFieldType.dropdown,
          dropdownOptions: ['A', 'B'],
        ),
      ],
    );

    await CardsRepository.instance.addCard(
      const ChoiceCard(
        id: 'card_dropdown',
        folderId: FoldersRepository.seedFolderId,
        categoryItemId: 'places_to_visit',
        title: 'Tagged',
        details: [
          CardDetailField(
            id: 'places_tag',
            label: 'Tag',
            type: DetailFieldType.dropdown,
            dropdownOptions: ['A', 'B'],
            dropdownValue: 'B',
          ),
        ],
      ),
    );

    await schema.setDropdownOptions(
      folderId: FoldersRepository.seedFolderId,
      itemId: 'places_to_visit',
      definitionId: 'places_tag',
      options: const ['A'],
    );

    final item = FoldersRepository.instance.itemById(
      FoldersRepository.seedFolderId,
      'places_to_visit',
    )!;
    expect(item.detailDefinitions.first.dropdownOptions, ['A']);

    final card = CardsRepository.instance.cards
        .firstWhere((c) => c.id == 'card_dropdown');
    expect(card.details.first.dropdownOptions, ['A']);
    expect(card.details.first.dropdownValue, isNull);
  });

  test('syncCardDetailsToSchema fills missing fields', () {
    const definitions = [
      CategoryDetailDefinition(
        id: 'a',
        label: 'A',
        type: DetailFieldType.text,
      ),
      CategoryDetailDefinition(
        id: 'b',
        label: 'B',
        type: DetailFieldType.text,
      ),
    ];
    const card = ChoiceCard(
      id: 'c1',
      folderId: 'f',
      categoryItemId: 'i',
      title: 'T',
      details: [
        CardDetailField(
          id: 'a',
          label: 'A',
          type: DetailFieldType.text,
          textValue: 'kept',
        ),
      ],
    );

    final synced =
        CategorySchemaService.instance.syncCardDetailsToSchema(card, definitions);
    expect(synced.details.map((d) => d.id).toList(), ['a', 'b']);
    expect(synced.details.first.textValue, 'kept');
    expect(synced.details.last.textValue, isNull);
  });

  testWidgets('Card tab can add a detail via UI', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  showItemSettingsDialog(
                    context,
                    folderId: FoldersRepository.seedFolderId,
                    itemId: 'activities',
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );
    await pumpUi(tester);
    await tester.tap(find.text('Open'));
    await pumpUi(tester);
    await tester.tap(find.text('Card'));
    await pumpUi(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Type detail'), 'Season');
    await tester.tap(find.byKey(const Key('schema_add_detail_button')));
    await pumpUi(tester);

    final item = FoldersRepository.instance.itemById(
      FoldersRepository.seedFolderId,
      'activities',
    )!;
    expect(item.detailDefinitions.any((d) => d.label == 'Season'), isTrue);

    final cards = CardsRepository.instance.cardsForCategory(
      FoldersRepository.seedFolderId,
      'activities',
    );
    for (final card in cards) {
      expect(card.details.any((d) => d.label == 'Season'), isTrue);
    }
  });
}
