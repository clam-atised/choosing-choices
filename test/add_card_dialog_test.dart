import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:choices/data/cards_repository.dart';
import 'package:choices/data/folders_repository.dart';
import 'package:choices/models/category_detail_definition.dart';
import 'package:choices/models/choice_card.dart';
import 'package:choices/screens/category_content_screen.dart';
import 'package:choices/widgets/add_card_dialog.dart';
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
  });

  Future<void> openAddCardDialogForSeedCategory(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CategoryContentScreen(
          folderId: FoldersRepository.seedFolderId,
          itemId: 'places_to_visit',
        ),
      ),
    );
    await pumpUi(tester);
    showAddCardDialog(
      tester.element(find.byType(CategoryContentScreen)),
      folderId: FoldersRepository.seedFolderId,
      initialItemId: 'places_to_visit',
    );
    await pumpUi(tester);
  }

  testWidgets('subsequent mode shows schema fields for seed category',
      (WidgetTester tester) async {
    await openAddCardDialogForSeedCategory(tester);

    expect(find.text('Add detail'), findsNothing);
    expect(find.text('Location:'), findsOneWidget);
    expect(_saveCheckInDialog(), findsOneWidget);
  });

  testWidgets('subsequent card saves with title and text detail value',
      (WidgetTester tester) async {
    await openAddCardDialogForSeedCategory(tester);

    await tester.enterText(_fieldByHint('Title'), 'Daiso Tokyo');
    await pumpUi(tester);

    await tester.enterText(
      find.descendant(
        of: find.byType(AddCardDialog),
        matching: _fieldByHint('Location: <text>'),
      ).first,
      'Tokyo, Japan',
    );
    await pumpUi(tester);

    await tester.tap(_saveCheckInDialog());
    await pumpUi(tester);

    final cards = CardsRepository.instance.cardsForCategory(
      FoldersRepository.seedFolderId,
      'places_to_visit',
    );
    expect(cards.any((card) => card.title == 'Daiso Tokyo'), isTrue);
    final saved = cards.firstWhere((card) => card.title == 'Daiso Tokyo');
    final location = saved.details.firstWhere(
      (field) => field.label == 'Location',
    );
    expect(location.textValue, 'Tokyo, Japan');
  });

  testWidgets('Yes/No detail persists yesNoValue', (WidgetTester tester) async {
    final categoryId = (await FoldersRepository.instance.addItem(
      FoldersRepository.seedFolderId,
      'Yes No Category',
    ))!
        .id;

    await FoldersRepository.instance.updateItemDetailDefinitions(
      FoldersRepository.seedFolderId,
      categoryId,
      const [
        CategoryDetailDefinition(
          id: 'def_yesno',
          label: 'Reservation needed',
          type: DetailFieldType.yesNo,
        ),
      ],
    );
    await CardsRepository.instance.addCard(
      ChoiceCard(
        id: 'card_seed',
        folderId: FoldersRepository.seedFolderId,
        categoryItemId: categoryId,
        title: 'Seed Card',
        details: const [
          CardDetailField(
            id: 'def_yesno',
            label: 'Reservation needed',
            type: DetailFieldType.yesNo,
            yesNoValue: false,
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  showAddCardDialog(
                    context,
                    folderId: FoldersRepository.seedFolderId,
                    initialItemId: categoryId,
                  );
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );
    await pumpUi(tester);
    await tester.tap(find.text('Open'));
    await pumpUi(tester);

    await tester.enterText(_fieldByHint('Title'), 'Test Card');
    await tester.tap(find.text('Yes'));
    await pumpUi(tester);
    await tester.tap(_saveCheckInDialog());
    await pumpUi(tester);

    final card = CardsRepository.instance.cardsForCategory(
      FoldersRepository.seedFolderId,
      categoryId,
    ).last;
    final detail = card.details.firstWhere(
      (field) => field.label == 'Reservation needed',
    );
    expect(detail.yesNoValue, isTrue);
  });

  testWidgets('Empty title keeps save disabled', (WidgetTester tester) async {
    await openAddCardDialogForSeedCategory(tester);

    await tester.tap(_saveCheckInDialog());
    await pumpUi(tester);

    expect(find.byType(AddCardDialog), findsOneWidget);
    expect(
      CardsRepository.instance.cardsForCategory(
        FoldersRepository.seedFolderId,
        'places_to_visit',
      ).where((card) => card.title.isEmpty),
      isEmpty,
    );
  });
}
