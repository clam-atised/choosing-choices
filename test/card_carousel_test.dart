import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:choices/data/cards_repository.dart';
import 'package:choices/data/folders_repository.dart';
import 'package:choices/models/category_item.dart';
import 'package:choices/models/choice_card.dart';
import 'package:choices/screens/category_content_screen.dart';
import 'package:choices/screens/folder_content_screen.dart';
import 'package:choices/theme/layout_constants.dart';
import 'package:choices/widgets/add_card_dialog.dart';
import 'package:choices/widgets/choice_card_tile.dart';
import 'test_helpers.dart';

void main() {
  setUp(() async {
    await configureRepositoriesForTesting();
  });

  testWidgets('CategoryContentScreen shows saved card in carousel',
      (WidgetTester tester) async {
    CardsRepository.instance.clearCardsForTesting();
    await CardsRepository.instance.addCard(
      const ChoiceCard(
        id: 'card_1',
        folderId: FoldersRepository.seedFolderId,
        categoryItemId: 'places_to_visit',
        title: 'Daiso Tokyo',
        details: [
          CardDetailField(
            id: 'detail_1',
            label: 'Location',
            type: DetailFieldType.text,
            textValue: 'Tokyo, Japan',
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: CategoryContentScreen(
          folderId: FoldersRepository.seedFolderId,
          itemId: 'places_to_visit',
        ),
      ),
    );
    await pumpUi(tester);

    expect(find.text('Daiso Tokyo'), findsOneWidget);
    expect(find.text('Location: Tokyo, Japan'), findsOneWidget);
    expect(find.byType(ChoiceCardTile), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('saved card without image omits photo placeholder',
      (WidgetTester tester) async {
    CardsRepository.instance.clearCardsForTesting();
    await CardsRepository.instance.addCard(
      const ChoiceCard(
        id: 'card_no_image',
        folderId: FoldersRepository.seedFolderId,
        categoryItemId: 'places_to_visit',
        title: 'No Photo Place',
        details: [
          CardDetailField(
            id: 'detail_1',
            label: 'Location',
            type: DetailFieldType.text,
            textValue: 'Tokyo, Japan',
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: CategoryContentScreen(
          folderId: FoldersRepository.seedFolderId,
          itemId: 'places_to_visit',
        ),
      ),
    );
    await pumpUi(tester);

    expect(
      find.descendant(
        of: find.byType(ChoiceCardTile),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is SizedBox &&
              widget.width == kCardListPhotoSize &&
              widget.height == kCardListPhotoSize,
        ),
      ),
      findsNothing,
    );
  });

  testWidgets('Folder accordion packs next category under cards',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FolderContentScreen(
          folderId: FoldersRepository.seedFolderId,
        ),
      ),
    );
    await pumpUi(tester);

    expect(find.text('Petronas Twin Towers'), findsOneWidget);
    expect(find.textContaining('Kuala Lumpur'), findsOneWidget);

    final cardBottom = tester.getBottomLeft(find.byType(ChoiceCardTile).first).dy;
    final nextCategoryTop =
        tester.getTopLeft(find.text('Restaurant recommendations')).dy;
    expect(nextCategoryTop - cardBottom, lessThan(48));
  });

  testWidgets(
      'vertical category keeps category name visible while scrolling cards',
      (WidgetTester tester) async {
    CardsRepository.instance.clearCardsForTesting();
    await FoldersRepository.instance.setItemCardDirection(
      FoldersRepository.seedFolderId,
      'places_to_visit',
      CardDisplayDirection.vertical,
    );

    for (var index = 0; index < 12; index++) {
      await CardsRepository.instance.addCard(
        ChoiceCard(
          id: 'vertical_card_$index',
          folderId: FoldersRepository.seedFolderId,
          categoryItemId: 'places_to_visit',
          title: 'Vertical Card $index',
          details: const [],
        ),
      );
    }

    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: FolderContentScreen(
          folderId: FoldersRepository.seedFolderId,
        ),
      ),
    );
    await pumpUi(tester);

    final categoryFinder = find.text('Places to visit');
    expect(categoryFinder, findsOneWidget);
    final initialCategoryTop = tester.getTopLeft(categoryFinder).dy;

    final nextCategoryTopBefore =
        tester.getTopLeft(find.text('Restaurant recommendations')).dy;
    final cardViewportBottom =
        tester.getBottomLeft(find.byType(ListView).first).dy;
    expect(nextCategoryTopBefore - cardViewportBottom, lessThan(48));

    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await pumpUi(tester);

    expect(categoryFinder, findsOneWidget);
    expect(tester.getTopLeft(categoryFinder).dy, initialCategoryTop);
    expect(find.text('Vertical Card 0'), findsNothing);
    expect(
      tester.getTopLeft(find.text('Restaurant recommendations')).dy,
      nextCategoryTopBefore,
    );
  });

  testWidgets(
      'CategoryContentScreen keeps category name while scrolling vertical cards',
      (WidgetTester tester) async {
    CardsRepository.instance.clearCardsForTesting();
    await FoldersRepository.instance.setItemCardDirection(
      FoldersRepository.seedFolderId,
      'places_to_visit',
      CardDisplayDirection.vertical,
    );

    for (var index = 0; index < 12; index++) {
      await CardsRepository.instance.addCard(
        ChoiceCard(
          id: 'content_vertical_card_$index',
          folderId: FoldersRepository.seedFolderId,
          categoryItemId: 'places_to_visit',
          title: 'Content Vertical Card $index',
          details: const [],
        ),
      );
    }

    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: CategoryContentScreen(
          folderId: FoldersRepository.seedFolderId,
          itemId: 'places_to_visit',
        ),
      ),
    );
    await pumpUi(tester);

    final categoryFinder = find.text('Places to visit');
    expect(categoryFinder, findsOneWidget);
    final initialCategoryTop = tester.getTopLeft(categoryFinder).dy;

    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await pumpUi(tester);

    expect(categoryFinder, findsOneWidget);
    expect(tester.getTopLeft(categoryFinder).dy, initialCategoryTop);
    expect(find.text('Content Vertical Card 0'), findsNothing);
  });

  test('ChoiceCard.fromJson defaults isStamped to false when missing', () {
    final card = ChoiceCard.fromJson({
      'id': 'card_json',
      'folderId': 'folder_1',
      'categoryItemId': 'item_1',
      'title': 'Test',
      'details': <dynamic>[],
    });

    expect(card.isStamped, isFalse);
  });

  test('ChoiceCard round-trips isStamped through JSON', () {
    const original = ChoiceCard(
      id: 'card_stamped',
      folderId: 'folder_1',
      categoryItemId: 'item_1',
      title: 'Stamped',
      isStamped: true,
    );

    final restored = ChoiceCard.fromJson(original.toJson());
    expect(restored.isStamped, isTrue);
  });

  testWidgets('tick button completes card, greys it, and moves it to end',
      (WidgetTester tester) async {
    CardsRepository.instance.clearCardsForTesting();
    await CardsRepository.instance.addCard(
      const ChoiceCard(
        id: 'card_a',
        folderId: FoldersRepository.seedFolderId,
        categoryItemId: 'places_to_visit',
        title: 'First Card',
        details: [],
      ),
    );
    await CardsRepository.instance.addCard(
      const ChoiceCard(
        id: 'card_b',
        folderId: FoldersRepository.seedFolderId,
        categoryItemId: 'places_to_visit',
        title: 'Second Card',
        details: [],
      ),
    );

    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: CategoryContentScreen(
          folderId: FoldersRepository.seedFolderId,
          itemId: 'places_to_visit',
        ),
      ),
    );
    await pumpUi(tester);

    expect(find.byKey(ChoiceCardTile.completedCardKey), findsNothing);
    expect(
      CardsRepository.instance
          .cardsForCategory(
            FoldersRepository.seedFolderId,
            'places_to_visit',
          )
          .map((card) => card.id)
          .toList(),
      ['card_a', 'card_b'],
    );

    await tester.tap(find.byIcon(Icons.check).first);
    await pumpUi(tester);

    final ordered = CardsRepository.instance.cardsForCategory(
      FoldersRepository.seedFolderId,
      'places_to_visit',
    );
    expect(ordered.map((card) => card.id).toList(), ['card_b', 'card_a']);
    expect(ordered.last.isStamped, isTrue);
    expect(find.byKey(ChoiceCardTile.completedCardKey), findsOneWidget);

    await tester.tap(find.text('First Card'));
    await pumpUi(tester);

    expect(find.text(ChoiceCardTile.reopenSnackBarMessage), findsNothing);
    expect(find.text('Save Card'), findsNothing);
    expect(
      CardsRepository.instance
          .cardsForCategory(
            FoldersRepository.seedFolderId,
            'places_to_visit',
          )
          .firstWhere((card) => card.id == 'card_a')
          .isStamped,
      isFalse,
    );
  });

  testWidgets('Edit card dialog places photo picker on the right',
      (WidgetTester tester) async {
    CardsRepository.instance.clearCardsForTesting();
    await CardsRepository.instance.addCard(
      const ChoiceCard(
        id: 'card_edit_test',
        folderId: FoldersRepository.seedFolderId,
        categoryItemId: 'places_to_visit',
        title: 'Daiso Tokyo',
        details: [],
      ),
    );

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
      existingCard: CardsRepository.instance.cards.first,
    );
    await pumpUi(tester);

    final photoFinder = find.byKey(const Key('add_card_photo_picker'));
    final saveFinder = find.text('Save Card');

    expect(photoFinder, findsOneWidget);
    expect(saveFinder, findsOneWidget);

    final photoX = tester.getTopLeft(photoFinder).dx;
    final detailX = tester.getTopLeft(saveFinder).dx;
    expect(photoX, greaterThan(detailX));
    expect(find.text('Add photo'), findsOneWidget);
  });
}
