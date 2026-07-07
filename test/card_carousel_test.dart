import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:choices/data/cards_repository.dart';
import 'package:choices/data/folders_repository.dart';
import 'package:choices/models/choice_card.dart';
import 'package:choices/screens/category_content_screen.dart';
import 'package:choices/screens/folder_content_screen.dart';
import 'package:choices/widgets/add_card_dialog.dart';
import 'package:choices/widgets/choice_card_tile.dart';

void main() {
  setUp(() {
    FoldersRepository.instance.configureForTesting();
    CardsRepository.instance.configureForTesting();
  });

  testWidgets('CategoryContentScreen shows saved card in carousel',
      (WidgetTester tester) async {
    await CardsRepository.instance.addCard(
      const ChoiceCard(
        id: 'card_1',
        folderId: 'trip_to_japan',
        categoryItemId: 'japan_eat',
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
          folderId: 'trip_to_japan',
          itemId: 'japan_eat',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Daiso Tokyo'), findsOneWidget);
    expect(find.text('Location: Tokyo, Japan'), findsOneWidget);
    expect(find.byType(ChoiceCardTile), findsOneWidget);
  });

  testWidgets('Folder accordion shows saved card in expanded section',
      (WidgetTester tester) async {
    await CardsRepository.instance.addCard(
      const ChoiceCard(
        id: 'card_1',
        folderId: 'trip_to_japan',
        categoryItemId: 'japan_eat',
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
        home: FolderContentScreen(folderId: 'trip_to_japan'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Daiso Tokyo'), findsOneWidget);
    expect(find.text('Location: Tokyo, Japan'), findsOneWidget);
  });

  testWidgets('Add Card dialog places photo picker on the right',
      (WidgetTester tester) async {
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

    final photoFinder = find.byKey(const Key('add_card_photo_picker'));
    final addDetailFinder = find.text('Add detail');

    expect(photoFinder, findsOneWidget);
    expect(addDetailFinder, findsOneWidget);

    final photoX = tester.getTopLeft(photoFinder).dx;
    final detailX = tester.getTopLeft(addDetailFinder).dx;
    expect(photoX, greaterThan(detailX));
    expect(find.text('Add photo'), findsOneWidget);
  });
}
