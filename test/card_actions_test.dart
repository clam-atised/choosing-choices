import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:choices/data/cards_repository.dart';
import 'package:choices/data/folders_repository.dart';
import 'package:choices/models/choice_card.dart';
import 'package:choices/widgets/add_card_dialog.dart';
import 'package:choices/widgets/category_card_carousel.dart';

void main() {
  setUp(() {
    FoldersRepository.instance.configureForTesting();
    CardsRepository.instance.configureForTesting();
  });

  Future<void> pumpCarousel(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CategoryCardCarousel(
            folderId: 'trip_to_japan',
            categoryItemId: 'japan_eat',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('long press shows edit and delete actions', (tester) async {
    await CardsRepository.instance.addCard(
      const ChoiceCard(
        id: 'card_1',
        folderId: 'trip_to_japan',
        categoryItemId: 'japan_eat',
        title: 'Ramen shop',
      ),
    );

    await pumpCarousel(tester);

    await tester.longPress(find.text('Ramen shop'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Edit card'), findsOneWidget);
    expect(find.byTooltip('Delete card'), findsOneWidget);
  });

  testWidgets('edit opens card dialog with existing contents', (tester) async {
    await CardsRepository.instance.addCard(
      const ChoiceCard(
        id: 'card_1',
        folderId: 'trip_to_japan',
        categoryItemId: 'japan_eat',
        title: 'Ramen shop',
      ),
    );

    await pumpCarousel(tester);

    await tester.longPress(find.text('Ramen shop'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit card'));
    await tester.pumpAndSettle();

    expect(find.byType(AddCardDialog), findsOneWidget);
    expect(find.text('Save Card'), findsOneWidget);
    expect(find.text('Ramen shop'), findsOneWidget);
  });

  testWidgets('edit saves updated card title', (tester) async {
    await CardsRepository.instance.addCard(
      const ChoiceCard(
        id: 'card_1',
        folderId: 'trip_to_japan',
        categoryItemId: 'japan_eat',
        title: 'Ramen shop',
      ),
    );

    await pumpCarousel(tester);

    await tester.longPress(find.text('Ramen shop'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit card'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Sushi bar');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Card'));
    await tester.pumpAndSettle();

    final cards = CardsRepository.instance.cardsForCategory(
      'trip_to_japan',
      'japan_eat',
    );
    expect(cards.single.title, 'Sushi bar');
  });

  testWidgets('delete confirmation removes the card', (tester) async {
    await CardsRepository.instance.addCard(
      const ChoiceCard(
        id: 'card_1',
        folderId: 'trip_to_japan',
        categoryItemId: 'japan_eat',
        title: 'Ramen shop',
      ),
    );

    await pumpCarousel(tester);

    await tester.longPress(find.text('Ramen shop'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete card'));
    await tester.pumpAndSettle();

    expect(
      find.text('Are you sure you want to delete this card?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(CardsRepository.instance.cards, isEmpty);
    expect(find.byTooltip('Edit card'), findsNothing);
  });
}
