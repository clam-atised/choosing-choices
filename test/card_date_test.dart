import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:choices/data/cards_repository.dart';
import 'package:choices/data/folders_repository.dart';
import 'package:choices/models/choice_card.dart';
import 'package:choices/screens/category_content_screen.dart';
import 'package:choices/utils/card_date_utils.dart';
import 'package:choices/utils/detail_field_formatters.dart';
import 'package:choices/widgets/choice_card_tile.dart';
import 'test_helpers.dart';

ChoiceCard _datedCard({
  required String id,
  required String title,
  String? dateFrom,
  String? dateTo,
  bool isStamped = false,
  String? textValue,
}) {
  return ChoiceCard(
    id: id,
    folderId: FoldersRepository.seedFolderId,
    categoryItemId: 'places_to_visit',
    title: title,
    isStamped: isStamped,
    details: [
      CardDetailField(
        id: 'date_$id',
        label: 'Date',
        type: DetailFieldType.date,
        dateFrom: dateFrom,
        dateTo: dateTo ?? dateFrom,
      ),
      if (textValue != null)
        CardDetailField(
          id: 'note_$id',
          label: 'Note',
          type: DetailFieldType.text,
          textValue: textValue,
        ),
    ],
  );
}

void main() {
  setUp(() async {
    await configureRepositoriesForTesting();
  });

  test('date field round-trips through JSON', () {
    const original = CardDetailField(
      id: 'd1',
      label: 'Event date',
      type: DetailFieldType.date,
      dateFrom: '2026-07-16',
      dateTo: '2026-07-18',
    );

    final restored = CardDetailField.fromJson(original.toJson());
    expect(restored.type, DetailFieldType.date);
    expect(restored.dateFrom, '2026-07-16');
    expect(restored.dateTo, '2026-07-18');
  });

  test('formats single day and date ranges', () {
    expect(
      detailFieldDisplayValue(
        const CardDetailField(
          id: 'd1',
          label: 'Date',
          type: DetailFieldType.date,
          dateFrom: '2026-07-16',
          dateTo: '2026-07-16',
        ),
      ),
      '16 Jul 2026',
    );
    expect(
      detailFieldDisplayValue(
        const CardDetailField(
          id: 'd2',
          label: 'Date',
          type: DetailFieldType.date,
          dateFrom: '2026-07-16',
          dateTo: '2026-07-18',
        ),
      ),
      '16 Jul 2026 – 18 Jul 2026',
    );
  });

  test('clearDates removes date values', () {
    const field = CardDetailField(
      id: 'd1',
      label: 'Date',
      type: DetailFieldType.date,
      dateFrom: '2026-07-16',
      dateTo: '2026-07-18',
    );

    final cleared = field.copyWith(clearDates: true);
    expect(cleared.dateFrom, isNull);
    expect(cleared.dateTo, isNull);
  });

  test('sorts by upcoming end date, title tie-break, inactive last', () {
    final now = DateTime(2026, 7, 16);
    final cards = [
      _datedCard(id: 'later', title: 'Zoo', dateFrom: '2026-07-20'),
      _datedCard(id: 'soon', title: 'Beach', dateFrom: '2026-07-17'),
      _datedCard(
        id: 'same_b',
        title: 'Beta',
        dateFrom: '2026-07-18',
        dateTo: '2026-07-19',
      ),
      _datedCard(
        id: 'same_a',
        title: 'Alpha',
        dateFrom: '2026-07-18',
        dateTo: '2026-07-19',
      ),
      const ChoiceCard(
        id: 'undated',
        folderId: FoldersRepository.seedFolderId,
        categoryItemId: 'places_to_visit',
        title: 'No Date',
        details: [],
      ),
      _datedCard(
        id: 'expired',
        title: 'Past',
        dateFrom: '2026-07-01',
        dateTo: '2026-07-10',
      ),
      _datedCard(
        id: 'stamped',
        title: 'Done Soon',
        dateFrom: '2026-07-17',
        isStamped: true,
      ),
    ];

    final sorted = sortCardsByDateAndActivity(cards, now: now);
    expect(
      sorted.map((c) => c.id).toList(),
      ['soon', 'same_a', 'same_b', 'later', 'undated', 'expired', 'stamped'],
    );
  });

  test('isDateExpired after end date; same day is still active', () {
    final card = _datedCard(
      id: 'c1',
      title: 'Event',
      dateFrom: '2026-07-16',
      dateTo: '2026-07-18',
    );
    expect(isDateExpired(card, now: DateTime(2026, 7, 18)), isFalse);
    expect(isDateExpired(card, now: DateTime(2026, 7, 19)), isTrue);
    expect(isCardInactive(card, now: DateTime(2026, 7, 18)), isFalse);
    expect(isCardInactive(card, now: DateTime(2026, 7, 19)), isTrue);
  });

  test('editing non-date fields does not reactivate; future date does', () {
    final previous = _datedCard(
      id: 'c1',
      title: 'Event',
      dateFrom: '2026-07-01',
      dateTo: '2026-07-10',
      isStamped: true,
      textValue: 'old',
    );
    final now = DateTime(2026, 7, 16);

    final otherFieldOnly = previous.copyWith(
      details: [
        previous.details.first,
        const CardDetailField(
          id: 'note_c1',
          label: 'Note',
          type: DetailFieldType.text,
          textValue: 'new note',
        ),
      ],
    );
    expect(
      shouldReactivateOnDateUpdate(
        previous: previous,
        updated: otherFieldOnly,
        now: now,
      ),
      isFalse,
    );

    final futureDate = previous.copyWith(
      details: [
        previous.details.first.copyWith(
          dateFrom: '2026-08-01',
          dateTo: '2026-08-03',
        ),
        previous.details.last,
      ],
    );
    expect(
      shouldReactivateOnDateUpdate(
        previous: previous,
        updated: futureDate,
        now: now,
      ),
      isTrue,
    );
  });

  testWidgets('tick greys card before date passes; tap reopens directly',
      (WidgetTester tester) async {
    CardsRepository.instance.clearCardsForTesting();
    await CardsRepository.instance.addCard(
      _datedCard(
        id: 'card_future',
        title: 'Future Event',
        dateFrom: '2099-01-01',
        dateTo: '2099-01-02',
      ),
    );
    await CardsRepository.instance.addCard(
      const ChoiceCard(
        id: 'card_other',
        folderId: FoldersRepository.seedFolderId,
        categoryItemId: 'places_to_visit',
        title: 'Other Card',
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

    await tester.tap(find.byIcon(Icons.check).first);
    await pumpUi(tester);

    final ordered = CardsRepository.instance.cardsForCategory(
      FoldersRepository.seedFolderId,
      'places_to_visit',
    );
    expect(ordered.last.isStamped, isTrue);
    expect(find.byKey(ChoiceCardTile.completedCardKey), findsOneWidget);

    await tester.tap(find.text('Future Event'));
    await pumpUi(tester);

    expect(find.text(ChoiceCardTile.reopenSnackBarMessage), findsNothing);
    expect(find.text('Save Card'), findsNothing);
    expect(
      CardsRepository.instance
          .cardsForCategory(
            FoldersRepository.seedFolderId,
            'places_to_visit',
          )
          .firstWhere((c) => c.id == 'card_future')
          .isStamped,
      isFalse,
    );
  });

  testWidgets('expired date tap prompts reopen message and date edit',
      (WidgetTester tester) async {
    CardsRepository.instance.clearCardsForTesting();
    await CardsRepository.instance.addCard(
      _datedCard(
        id: 'card_past',
        title: 'Past Event',
        dateFrom: '2020-01-01',
        dateTo: '2020-01-02',
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

    expect(find.byKey(ChoiceCardTile.completedCardKey), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);

    await tester.tap(find.text('Past Event'));
    await pumpUi(tester);

    expect(find.text(ChoiceCardTile.reopenSnackBarMessage), findsOneWidget);
    expect(find.text('Save Card'), findsOneWidget);
  });

  test('saving future date clears stamp via update path', () async {
    CardsRepository.instance.clearCardsForTesting();
    final previous = _datedCard(
      id: 'card_stamped',
      title: 'Stamped Event',
      dateFrom: '2020-01-01',
      dateTo: '2020-01-02',
      isStamped: true,
    );
    await CardsRepository.instance.addCard(previous);

    var updated = previous.copyWith(
      details: [
        previous.details.first.copyWith(
          dateFrom: '2099-06-01',
          dateTo: '2099-06-02',
        ),
      ],
    );
    if (shouldReactivateOnDateUpdate(previous: previous, updated: updated)) {
      updated = updated.copyWith(isStamped: false);
    }
    await CardsRepository.instance.updateCard(updated);

    final saved = CardsRepository.instance.cards
        .firstWhere((c) => c.id == 'card_stamped');
    expect(saved.isStamped, isFalse);
    expect(primaryDateRange(saved)?.from, DateTime(2099, 6, 1));
  });
}