import 'package:flutter_test/flutter_test.dart';

import 'package:choices/data/cards_repository.dart';
import 'package:choices/data/folders_repository.dart';
import 'package:choices/models/choice_card.dart';

void main() {
  setUp(() {
    FoldersRepository.instance.configureForTesting();
    CardsRepository.instance.configureForTesting();
  });

  ChoiceCard _testCard({
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
      _testCard(
        id: 'card_1',
        folderId: 'trip_to_japan',
        itemId: 'japan_eat',
      ),
    );
    await CardsRepository.instance.addCard(
      _testCard(
        id: 'card_2',
        folderId: 'trip_to_japan',
        itemId: 'japan_stay',
      ),
    );
    await CardsRepository.instance.addCard(
      _testCard(
        id: 'card_3',
        folderId: 'malaysia_eat',
        itemId: 'malaysia_state',
      ),
    );

    await FoldersRepository.instance.deleteFolder('trip_to_japan');

    expect(FoldersRepository.instance.folderById('trip_to_japan'), isNull);
    expect(CardsRepository.instance.cards.length, 1);
    expect(CardsRepository.instance.cards.first.id, 'card_3');
  });

  test('deleteItem removes associated cards only for that item', () async {
    await CardsRepository.instance.addCard(
      _testCard(
        id: 'card_1',
        folderId: 'trip_to_japan',
        itemId: 'japan_eat',
      ),
    );
    await CardsRepository.instance.addCard(
      _testCard(
        id: 'card_2',
        folderId: 'trip_to_japan',
        itemId: 'japan_stay',
      ),
    );

    await FoldersRepository.instance.deleteItem('trip_to_japan', 'japan_eat');

    expect(
      FoldersRepository.instance.itemById('trip_to_japan', 'japan_eat'),
      isNull,
    );
    expect(CardsRepository.instance.cards.length, 1);
    expect(CardsRepository.instance.cards.first.categoryItemId, 'japan_stay');
  });

  test('deleteCard removes a single card', () async {
    await CardsRepository.instance.addCard(
      _testCard(
        id: 'card_1',
        folderId: 'trip_to_japan',
        itemId: 'japan_eat',
      ),
    );

    await CardsRepository.instance.deleteCard('card_1');

    expect(CardsRepository.instance.cards, isEmpty);
  });
}
