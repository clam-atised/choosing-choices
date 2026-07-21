import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:choices/data/cards_repository.dart';
import 'package:choices/data/folders_repository.dart';
import 'package:choices/models/category_item.dart';
import 'package:choices/models/choice_card.dart';
import 'package:choices/widgets/add_card_dialog.dart';
import 'package:choices/widgets/card_view_action_bar.dart';
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

  Future<void> openCardView(WidgetTester tester, String title) async {
    await tester.tap(find.text(title));
    await pumpUi(tester);
  }

  ChoiceCard testCard({
    required String id,
    required String title,
  }) {
    return ChoiceCard(
      id: id,
      folderId: FoldersRepository.seedFolderId,
      categoryItemId: 'places_to_visit',
      title: title,
    );
  }

  testWidgets('tap shows edit and delete actions in card view', (tester) async {
    await CardsRepository.instance.addCard(testCard(id: 'card_1', title: 'Ramen shop'));

    await pumpCarousel(tester);
    await openCardView(tester, 'Ramen shop');

    expect(find.byTooltip('Edit card'), findsOneWidget);
    expect(find.byTooltip('Delete card'), findsOneWidget);
  });

  testWidgets('single card hides navigation arrows', (tester) async {
    await CardsRepository.instance.addCard(testCard(id: 'card_1', title: 'Ramen shop'));

    await pumpCarousel(tester);
    await openCardView(tester, 'Ramen shop');

    expect(find.byKey(CardViewActionBar.leftArrowKey), findsNothing);
    expect(find.byKey(CardViewActionBar.rightArrowKey), findsNothing);
  });

  testWidgets('first of three cards hides left arrow only', (tester) async {
    await CardsRepository.instance.addCard(testCard(id: 'card_1', title: 'First card'));
    await CardsRepository.instance.addCard(testCard(id: 'card_2', title: 'Second card'));
    await CardsRepository.instance.addCard(testCard(id: 'card_3', title: 'Third card'));

    await pumpCarousel(tester);
    await openCardView(tester, 'First card');

    expect(find.byKey(CardViewActionBar.leftArrowKey), findsNothing);
    expect(find.byKey(CardViewActionBar.rightArrowKey), findsOneWidget);
  });

  testWidgets('middle card shows both navigation arrows', (tester) async {
    await CardsRepository.instance.addCard(testCard(id: 'card_1', title: 'First card'));
    await CardsRepository.instance.addCard(testCard(id: 'card_2', title: 'Second card'));
    await CardsRepository.instance.addCard(testCard(id: 'card_3', title: 'Third card'));

    await pumpCarousel(tester);
    await openCardView(tester, 'First card');
    await tester.tap(find.byKey(CardViewActionBar.rightArrowKey));
    await pumpUi(tester);

    expect(find.byKey(CardViewActionBar.leftArrowKey), findsOneWidget);
    expect(find.byKey(CardViewActionBar.rightArrowKey), findsOneWidget);
    expect(find.text('Second card'), findsWidgets);
  });

  testWidgets('right arrow on last card wraps to first card', (tester) async {
    await CardsRepository.instance.addCard(testCard(id: 'card_1', title: 'First card'));
    await CardsRepository.instance.addCard(testCard(id: 'card_2', title: 'Second card'));
    await CardsRepository.instance.addCard(testCard(id: 'card_3', title: 'Third card'));

    await pumpCarousel(tester);
    await openCardView(tester, 'First card');
    await tester.tap(find.byKey(CardViewActionBar.rightArrowKey));
    await pumpUi(tester);
    await tester.tap(find.byKey(CardViewActionBar.rightArrowKey));
    await pumpUi(tester);

    expect(find.text('Third card'), findsWidgets);
    expect(find.byKey(CardViewActionBar.leftArrowKey), findsOneWidget);
    expect(find.byKey(CardViewActionBar.rightArrowKey), findsOneWidget);

    await tester.tap(find.byKey(CardViewActionBar.rightArrowKey));
    await pumpUi(tester);

    expect(find.text('First card'), findsWidgets);
  });

  testWidgets('edit opens card dialog with existing contents', (tester) async {
    await CardsRepository.instance.addCard(testCard(id: 'card_1', title: 'Ramen shop'));

    await pumpCarousel(tester);
    await openCardView(tester, 'Ramen shop');
    await tester.tap(find.byTooltip('Edit card'));
    await pumpUi(tester);

    expect(find.byType(AddCardDialog), findsOneWidget);
    expect(find.text('Save Card'), findsOneWidget);
    expect(find.text('Ramen shop'), findsWidgets);
  });

  testWidgets('edit saves updated card title', (tester) async {
    await CardsRepository.instance.addCard(testCard(id: 'card_1', title: 'Ramen shop'));

    await pumpCarousel(tester);
    await openCardView(tester, 'Ramen shop');
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

  testWidgets('delete no keeps card visible', (tester) async {
    await CardsRepository.instance.addCard(testCard(id: 'card_1', title: 'Ramen shop'));

    await pumpCarousel(tester);
    await openCardView(tester, 'Ramen shop');
    await tester.tap(find.byTooltip('Delete card'));
    await pumpUi(tester);

    expect(find.text('Delete forever?'), findsOneWidget);

    await tester.tap(find.text('No'));
    await pumpUi(tester);

    expect(CardsRepository.instance.cards, isNotEmpty);
    expect(find.text('Ramen shop'), findsWidgets);
  });

  testWidgets('delete yes removes the card', (tester) async {
    await CardsRepository.instance.addCard(testCard(id: 'card_1', title: 'Ramen shop'));

    await pumpCarousel(tester);
    await openCardView(tester, 'Ramen shop');
    await tester.tap(find.byTooltip('Delete card'));
    await pumpUi(tester);

    expect(find.text('Delete forever?'), findsOneWidget);

    await tester.tap(find.text('Yes'));
    await pumpUi(tester);

    expect(CardsRepository.instance.cards, isEmpty);
    expect(find.byTooltip('Edit card'), findsNothing);
  });

  testWidgets('delete yes shows next card when others remain', (tester) async {
    await CardsRepository.instance.addCard(testCard(id: 'card_1', title: 'First card'));
    await CardsRepository.instance.addCard(testCard(id: 'card_2', title: 'Second card'));

    await pumpCarousel(tester);
    await openCardView(tester, 'First card');
    await tester.tap(find.byTooltip('Delete card'));
    await pumpUi(tester);
    await tester.tap(find.text('Yes'));
    await pumpUi(tester);

    expect(CardsRepository.instance.cards, hasLength(1));
    expect(find.text('Second card'), findsWidgets);
  });
}
