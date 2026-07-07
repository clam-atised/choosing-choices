import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:choices/data/cards_repository.dart';
import 'package:choices/data/folders_repository.dart';
import 'package:choices/screens/category_content_screen.dart';
import 'package:choices/widgets/add_card_dialog.dart';

Finder _fieldByHint(String hint) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is TextField && widget.decoration?.hintText == hint,
  );
}

void main() {
  setUp(() {
    FoldersRepository.instance.configureForTesting();
    CardsRepository.instance.configureForTesting();
  });

  Future<void> openAddCardDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CategoryContentScreen(
          folderId: 'trip_to_japan',
          itemId: 'japan_eat',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await showAddCardDialog(
      tester.element(find.byType(CategoryContentScreen)),
      folderId: 'trip_to_japan',
      itemId: 'japan_eat',
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Add detail type picker shows three options',
      (WidgetTester tester) async {
    await openAddCardDialog(tester);

    await tester.tap(find.text('Add detail'));
    await tester.pumpAndSettle();

    expect(find.text('Text cell'), findsOneWidget);
    expect(find.text('Yes/No cell'), findsOneWidget);
    expect(find.text('Dropdown cell'), findsOneWidget);
  });

  testWidgets('Add Card saves card with title and text detail',
      (WidgetTester tester) async {
    await openAddCardDialog(tester);

    await tester.enterText(_fieldByHint('Title'), 'Daiso Tokyo');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add detail'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Text cell'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Label',
      ),
      'Location',
    );
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Value',
      ),
      'Tokyo, Japan',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Card'));
    await tester.pumpAndSettle();

    final cards = CardsRepository.instance.cardsForCategory(
      'trip_to_japan',
      'japan_eat',
    );
    expect(cards.length, 1);
    expect(cards.first.title, 'Daiso Tokyo');
    expect(cards.first.details.first.label, 'Location');
    expect(cards.first.details.first.textValue, 'Tokyo, Japan');
  });

  testWidgets('Yes/No detail persists yesNoValue', (WidgetTester tester) async {
    await openAddCardDialog(tester);

    await tester.enterText(_fieldByHint('Title'), 'Test Card');
    await tester.tap(find.text('Add detail'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes/No cell'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Label',
      ),
      'Reservation needed',
    );
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Card'));
    await tester.pumpAndSettle();

    final card = CardsRepository.instance.cardsForCategory(
      'trip_to_japan',
      'japan_eat',
    ).first;
    final detail = card.details.firstWhere(
      (field) => field.label == 'Reservation needed',
    );
    expect(detail.yesNoValue, isTrue);
  });

  testWidgets('Empty title keeps Add Card disabled', (WidgetTester tester) async {
    await openAddCardDialog(tester);

    await tester.tap(find.text('Add Card'));
    await tester.pumpAndSettle();

    expect(find.byType(AddCardDialog), findsOneWidget);
    expect(CardsRepository.instance.cards, isEmpty);
  });
}
