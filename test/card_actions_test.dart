import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:choices/data/cards_repository.dart';
import 'package:choices/data/folders_repository.dart';
import 'package:choices/models/category_item.dart';
import 'package:choices/models/choice_card.dart';
import 'package:choices/widgets/add_card_dialog.dart';
import 'package:choices/widgets/category_card_carousel.dart';
import 'test_helpers.dart';

void main() {
  setUp(() async {
    await configureRepositoriesForTesting();
    CardsRepository.instance.clearCardsForTesting();
  });

  Future<void> pumpCarousel(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CategoryCardCarousel(
            folderId: FoldersRepository.seedFolderId,
            categoryItemId: 'places_to_visit',
            displayDirection: CardDisplayDirection.horizontal,
          ),
        ),
      ),
    );
    await pumpUi(tester);
  }

  testWidgets('long press shows edit and delete actions', (tester) async {
    await CardsRepository.instance.addCard(
      const ChoiceCard(
        id: 'card_1',
        folderId: FoldersRepository.seedFolderId,
        categoryItemId: 'places_to_visit',
        title: 'Ramen shop',
      ),
    );

    await pumpCarousel(tester);

    await tester.longPress(find.text('Ramen shop'));
    await pumpUi(tester);

    expect(find.byTooltip('Edit card'), findsOneWidget);
    expect(find.byTooltip('Delete card'), findsOneWidget);
  });

  testWidgets('edit opens card dialog with existing contents', (tester) async {
    await CardsRepository.instance.addCard(
      const ChoiceCard(
        id: 'card_1',
        folderId: FoldersRepository.seedFolderId,
        categoryItemId: 'places_to_visit',
        title: 'Ramen shop',
      ),
    );

    await pumpCarousel(tester);

    await tester.longPress(find.text('Ramen shop'));
    await pumpUi(tester);
    await tester.tap(find.byTooltip('Edit card'));
    await pumpUi(tester);

    expect(find.byType(AddCardDialog), findsOneWidget);
    expect(find.text('Save Card'), findsOneWidget);
    expect(find.text('Ramen shop'), findsWidgets);
  });

  testWidgets('edit saves updated card title', (tester) async {
    await CardsRepository.instance.addCard(
      const ChoiceCard(
        id: 'card_1',
        folderId: FoldersRepository.seedFolderId,
        categoryItemId: 'places_to_visit',
        title: 'Ramen shop',
      ),
    );

    await pumpCarousel(tester);

    await tester.longPress(find.text('Ramen shop'));
    await pumpUi(tester);
    await tester.tap(find.byTooltip('Edit card'));
    await pumpUi(tester);

    await tester.enterText(find.byType(TextField).first, 'Sushi bar');
    await pumpUi(tester);
    await tester.tap(find.text('Save Card'));
    await pumpUi(tester);

    final cards = CardsRepository.instance.cardsForCategory(
      FoldersRepository.seedFolderId,
      'places_to_visit',
    );
    expect(cards.single.title, 'Sushi bar');
  });

  testWidgets('delete confirmation removes the card', (tester) async {
    await CardsRepository.instance.addCard(
      const ChoiceCard(
        id: 'card_1',
        folderId: FoldersRepository.seedFolderId,
        categoryItemId: 'places_to_visit',
        title: 'Ramen shop',
      ),
    );

    await pumpCarousel(tester);

    await tester.longPress(find.text('Ramen shop'));
    await pumpUi(tester);
    await tester.tap(find.byTooltip('Delete card'));
    await pumpUi(tester);

    expect(
      find.text('Are you sure you want to delete this card?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Delete').last);
    await pumpUi(tester);

    expect(CardsRepository.instance.cards, isEmpty);
    expect(find.byTooltip('Edit card'), findsNothing);
  });
}
