import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:choices/data/cards_repository.dart';
import 'package:choices/data/folders_repository.dart';
import 'package:choices/models/category_detail_definition.dart';
import 'package:choices/models/choice_card.dart';
import 'package:choices/services/category_schema_service.dart';
import 'package:choices/widgets/add_card_dialog.dart';
import 'package:choices/widgets/detail_setup_row.dart';
import 'test_helpers.dart';

Finder _fieldByHint(String hint) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is TextField && widget.decoration?.hintText == hint,
  );
}

Finder _saveCheckInDialog() {
  return find.byKey(const Key('add_card_save_check'));
}

void main() {
  setUp(() async {
    await configureRepositoriesForTesting();
    CardsRepository.instance.clearCardsForTesting();
  });

  Future<String> createEmptyCategory(WidgetTester tester) async {
    final item = await FoldersRepository.instance.addItem(
      FoldersRepository.seedFolderId,
      'Empty Category ${DateTime.now().microsecondsSinceEpoch}',
    );
    return item!.id;
  }

  Future<void> openAddCardDialog(
    WidgetTester tester, {
    required String categoryId,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showAddCardDialog(
                      context,
                      folderId: FoldersRepository.seedFolderId,
                      initialItemId: categoryId,
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    );
    await pumpUi(tester);
    await tester.tap(find.text('Open'));
    await pumpUi(tester);
  }

  test('CategorySchemaService setup mode is true for empty category', () async {
    final item = await FoldersRepository.instance.addItem(
      FoldersRepository.seedFolderId,
      'Schema Test Category',
    );

    expect(
      CategorySchemaService.instance.isCategorySetupMode(
        FoldersRepository.seedFolderId,
        item!.id,
      ),
      isTrue,
    );
  });

  test('time and days serialize correctly', () {
    const detail = CardDetailField(
      id: 'detail_1',
      label: 'Hours',
      type: DetailFieldType.time,
      timeFrom: '09:00',
      timeTo: '17:00',
    );

    final restored = CardDetailField.fromJson(detail.toJson());
    expect(restored.timeFrom, '09:00');
    expect(restored.timeTo, '17:00');

    const daysDetail = CardDetailField(
      id: 'detail_2',
      label: 'Open days',
      type: DetailFieldType.days,
      weekDays: [true, false, true, false, true, false, false],
    );
    final restoredDays = CardDetailField.fromJson(daysDetail.toJson());
    expect(restoredDays.weekDays, daysDetail.weekDays);
  });

  testWidgets('setup mode Add detail adds inline dashed row without modal',
      (WidgetTester tester) async {
    final categoryId = await createEmptyCategory(tester);
    await openAddCardDialog(tester, categoryId: categoryId);

    await tester.tap(find.text('Add detail'));
    await pumpUi(tester);

    expect(find.byType(DetailSetupRow), findsOneWidget);
    expect(find.text('Text cell'), findsNothing);
    expect(find.text('Type detail'), findsOneWidget);
  });

  testWidgets('first card save persists detailDefinitions on category',
      (WidgetTester tester) async {
    final categoryId = await createEmptyCategory(tester);
    await openAddCardDialog(tester, categoryId: categoryId);

    await tester.enterText(_fieldByHint('Title'), 'First Restaurant');
    await tester.tap(find.text('Add detail'));
    await pumpUi(tester);

    await tester.enterText(_fieldByHint('Type detail'), 'Location');
    await pumpUi(tester);

    await tester.enterText(_fieldByHint('Location: <text>'), 'Tokyo');
    await pumpUi(tester);
    await tester.scrollUntilVisible(
      find.text('Create'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Create'));
    await pumpUi(tester);

    final item = FoldersRepository.instance.itemById(
      FoldersRepository.seedFolderId,
      categoryId,
    );
    expect(item?.detailDefinitions.length, 1);
    expect(item?.detailDefinitions.first.label, 'Location');
    expect(item?.detailDefinitions.first.type, DetailFieldType.text);

    final cards = CardsRepository.instance.cardsForCategory(
      FoldersRepository.seedFolderId,
      categoryId,
    );
    expect(cards.length, 1);
    expect(cards.first.title, 'First Restaurant');
  });

  testWidgets('subsequent card uses horizontal layout without Add detail',
      (WidgetTester tester) async {
    final categoryId = await createEmptyCategory(tester);

    await FoldersRepository.instance.updateItemDetailDefinitions(
      FoldersRepository.seedFolderId,
      categoryId,
      const [
        CategoryDetailDefinition(
          id: 'def_1',
          label: 'Location',
          type: DetailFieldType.text,
        ),
      ],
    );
    await CardsRepository.instance.addCard(
      ChoiceCard(
        id: 'card_existing',
        folderId: FoldersRepository.seedFolderId,
        categoryItemId: categoryId,
        title: 'Existing Card',
        details: const [
          CardDetailField(
            id: 'def_1',
            label: 'Location',
            type: DetailFieldType.text,
            textValue: 'KL',
          ),
        ],
      ),
    );

    await openAddCardDialog(tester, categoryId: categoryId);

    expect(find.text('Add detail'), findsNothing);
    expect(find.text('Location:'), findsOneWidget);
    expect(_saveCheckInDialog(), findsOneWidget);
    expect(find.text('Create'), findsNothing);
  });

  testWidgets(
      'type dropdown overlays above later rows and stays tappable',
      (WidgetTester tester) async {
    var upper = const CardDetailField(
      id: 'upper',
      label: 'Reservation needed',
      type: DetailFieldType.text,
    );
    var lower = const CardDetailField(
      id: 'lower',
      label: 'Type detail',
      type: DetailFieldType.text,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  DetailSetupRow(
                    field: upper,
                    onChanged: (updated) => setState(() => upper = updated),
                  ),
                  DetailSetupRow(
                    field: lower,
                    onChanged: (updated) => setState(() => lower = updated),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await pumpUi(tester);

    // Open the upper row's type dropdown (first "Text" header).
    await tester.tap(find.text('Text').first);
    await pumpUi(tester);

    expect(find.text('Days'), findsOneWidget);

    // Overlay menu should shrink-wrap to options, not fill the screen.
    final textOption = tester.getRect(find.text('Text').last);
    final daysOption = tester.getRect(find.text('Days'));
    final dropdownOption = tester.getRect(find.text('Dropdown'));
    expect(daysOption.bottom - textOption.top, lessThan(280));
    expect(dropdownOption.width, lessThan(200));

    await tester.tap(find.text('Days'));
    await pumpUi(tester);

    expect(upper.type, DetailFieldType.days);
    expect(lower.type, DetailFieldType.text);
    expect(find.text('Days'), findsOneWidget);
    expect(find.text('Text'), findsOneWidget);
  });

  testWidgets('dropdown Add data appends option', (WidgetTester tester) async {
    final categoryId = await createEmptyCategory(tester);

    await FoldersRepository.instance.updateItemDetailDefinitions(
      FoldersRepository.seedFolderId,
      categoryId,
      const [
        CategoryDetailDefinition(
          id: 'def_dropdown',
          label: 'Cuisine',
          type: DetailFieldType.dropdown,
          dropdownOptions: ['Malay'],
        ),
      ],
    );
    await CardsRepository.instance.addCard(
      ChoiceCard(
        id: 'card_existing',
        folderId: FoldersRepository.seedFolderId,
        categoryItemId: categoryId,
        title: 'Existing Card',
        details: const [
          CardDetailField(
            id: 'def_dropdown',
            label: 'Cuisine',
            type: DetailFieldType.dropdown,
            dropdownOptions: ['Malay'],
            dropdownValue: 'Malay',
          ),
        ],
      ),
    );

    await openAddCardDialog(tester, categoryId: categoryId);

    await tester.enterText(_fieldByHint('Title'), 'Second Restaurant');
    await tester.enterText(_fieldByHint('Add data'), 'Chinese');
    await pumpUi(tester);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await pumpUi(tester);

    expect(find.text('Chinese'), findsOneWidget);

    await tester.tap(_saveCheckInDialog());
    await pumpUi(tester);

    final item = FoldersRepository.instance.itemById(
      FoldersRepository.seedFolderId,
      categoryId,
    );
    expect(item?.detailDefinitions.first.dropdownOptions, contains('Chinese'));
  });
}
