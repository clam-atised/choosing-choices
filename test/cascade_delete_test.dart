import 'package:flutter_test/flutter_test.dart';

import 'package:choices/data/cards_repository.dart';
import 'package:choices/data/folders_repository.dart';
import 'package:choices/models/choice_card.dart';
import 'test_helpers.dart';

void main() {
  setUp(() async {
    await configureRepositoriesForTesting();
    CardsRepository.instance.clearCardsForTesting();
  });

  ChoiceCard testCard({
    required String id,
    required String folderId,
    required String itemId,
  }) {
    return ChoiceCard(
      id: id,
      folderId: folderId,
      categoryItemId: itemId,
      title: 'Test card $id',
    );
  }

  test('deleteFolder removes associated cards', () async {
    await CardsRepository.instance.addCard(
      testCard(
        id: 'card_1',
        folderId: FoldersRepository.seedFolderId,
        itemId: 'places_to_visit',
      ),
    );
    await CardsRepository.instance.addCard(
      testCard(
        id: 'card_2',
        folderId: FoldersRepository.seedFolderId,
        itemId: 'activities',
      ),
    );
    await FoldersRepository.instance.addFolder('Other Folder');
    await CardsRepository.instance.addCard(
      testCard(
        id: 'card_3',
        folderId: FoldersRepository.instance.folders.last.id,
        itemId: 'item_other',
      ),
    );

    await FoldersRepository.instance.deleteFolder(FoldersRepository.seedFolderId);

    expect(
      FoldersRepository.instance.folderById(FoldersRepository.seedFolderId),
      isNull,
    );
    expect(CardsRepository.instance.cards.length, 1);
    expect(CardsRepository.instance.cards.first.id, 'card_3');
  });

  test('deleteItem removes associated cards only for that item', () async {
    await CardsRepository.instance.addCard(
      testCard(
        id: 'card_1',
        folderId: FoldersRepository.seedFolderId,
        itemId: 'places_to_visit',
      ),
    );
    await CardsRepository.instance.addCard(
      testCard(
        id: 'card_2',
        folderId: FoldersRepository.seedFolderId,
        itemId: 'activities',
      ),
    );

    await FoldersRepository.instance.deleteItem(
      FoldersRepository.seedFolderId,
      'places_to_visit',
    );

    expect(
      FoldersRepository.instance.itemById(
        FoldersRepository.seedFolderId,
        'places_to_visit',
      ),
      isNull,
    );
    expect(CardsRepository.instance.cards.length, 1);
    expect(CardsRepository.instance.cards.first.categoryItemId, 'activities');
  });

  test('deleteCard removes a single card', () async {
    await CardsRepository.instance.addCard(
      testCard(
        id: 'card_1',
        folderId: FoldersRepository.seedFolderId,
        itemId: 'places_to_visit',
      ),
    );

    await CardsRepository.instance.deleteCard('card_1');

    expect(CardsRepository.instance.cards, isEmpty);
  });
}
