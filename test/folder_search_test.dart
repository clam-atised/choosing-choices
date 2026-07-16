import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:choices/data/folders_repository.dart';
import 'package:choices/models/choice_card.dart';
import 'package:choices/models/folder_search_state.dart';
import 'package:choices/screens/folder_content_screen.dart';
import 'package:choices/services/card_search_service.dart';
import 'package:choices/widgets/folder_vertical_cards_view.dart';
import 'package:choices/widgets/selection_dropdown.dart';
import 'test_helpers.dart';

Finder _fieldByHint(String hint) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is TextField && widget.decoration?.hintText == hint,
  );
}

Finder _dropdownByPlaceholder(String placeholder) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is SelectionDropdown && widget.placeholder == placeholder,
  );
}

void main() {
  setUp(() async {
    await configureRepositoriesForTesting();
  });

  group('FolderSearchState', () {
    test('folder-wide search is active when only folder query is set', () {
      const state = FolderSearchState(folderQuery: 'tower');
      expect(state.isFolderWideActive, isTrue);
      expect(state.isDetailSearchActive, isFalse);
      expect(state.isActive, isTrue);
    });

    test('detail search takes precedence over folder query', () {
      const state = FolderSearchState(
        folderQuery: 'tower',
        detailQueries: {'Location': 'KL'},
      );
      expect(state.isDetailSearchActive, isTrue);
      expect(state.isFolderWideActive, isFalse);
      expect(state.isActive, isTrue);
    });

    test('empty state is inactive', () {
      expect(FolderSearchState.empty.isActive, isFalse);
    });
  });

  group('CardSearchService', () {
    final service = CardSearchService.instance;

    test('matchesFolderWide searches title and detail values', () {
      const card = ChoiceCard(
        id: 'card_1',
        folderId: FoldersRepository.seedFolderId,
        categoryItemId: 'places_to_visit',
        title: 'Petronas Twin Towers',
        details: [
          CardDetailField(
            id: 'detail_1',
            label: 'Location',
            type: DetailFieldType.text,
            textValue: 'Kuala Lumpur, Malaysia',
          ),
        ],
      );

      expect(service.matchesFolderWide(card, 'petronas'), isTrue);
      expect(service.matchesFolderWide(card, 'malaysia'), isTrue);
      expect(service.matchesFolderWide(card, 'tokyo'), isFalse);
    });

    test('matchesDetailSearch exact-matches yes/no display values', () {
      const card = ChoiceCard(
        id: 'card_1',
        folderId: FoldersRepository.seedFolderId,
        categoryItemId: 'places_to_visit',
        title: 'Batu Caves',
        details: [
          CardDetailField(
            id: 'detail_1',
            label: 'Accessible by train',
            type: DetailFieldType.yesNo,
            yesNoValue: true,
          ),
        ],
      );

      expect(
        service.matchesDetailSearch(card, {'Accessible by train': 'Yes'}),
        isTrue,
      );
      expect(
        service.matchesDetailSearch(card, {'Accessible by train': 'No'}),
        isFalse,
      );
      expect(
        service.matchesDetailSearch(card, {'Accessible by train': 'yes'}),
        isFalse,
      );
    });

    test('detailLabelsForCategory returns sorted unique labels', () {
      final labels = service.detailLabelsForCategory(
        FoldersRepository.seedFolderId,
        'places_to_visit',
      );

      expect(labels, contains('Location'));
      expect(labels, contains('Accessible by train'));
      expect(labels, labels.toSet().toList());
      expect(labels, labels.toList()..sort());
    });

    test('detailSearchFieldsForCategory exposes types and text options', () {
      final fields = service.detailSearchFieldsForCategory(
        FoldersRepository.seedFolderId,
        'places_to_visit',
      );

      final accessible = fields.firstWhere(
        (field) => field.label == 'Accessible by train',
      );
      expect(accessible.type, DetailFieldType.yesNo);
      expect(accessible.options, isEmpty);

      final location = fields.firstWhere((field) => field.label == 'Location');
      expect(location.type, DetailFieldType.text);
      expect(location.options, contains('Penang, Malaysia'));
      expect(location.options, contains('Kuala Lumpur, Malaysia'));
    });
  });

  group('Folder search UI', () {
    Future<void> pumpFolderScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FolderContentScreen(
            folderId: FoldersRepository.seedFolderId,
          ),
        ),
      );
      await pumpUi(tester);
    }

    Future<void> openSearchDialog(WidgetTester tester) async {
      await tester.tap(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.search),
        ),
      );
      await pumpUi(tester);
    }

    testWidgets('folder screen shows search button left of add',
        (WidgetTester tester) async {
      await pumpFolderScreen(tester);

      final appBarSearch = find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.search),
      );
      expect(appBarSearch, findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      final searchX = tester.getCenter(appBarSearch).dx;
      final addX = tester.getCenter(find.byIcon(Icons.add)).dx;
      expect(searchX, lessThan(addX));
    });

    testWidgets('folder-wide search shows vertical sticky results',
        (WidgetTester tester) async {
      await pumpFolderScreen(tester);

      await openSearchDialog(tester);
      await tester.enterText(_fieldByHint('Search'), 'Petronas');
      await pumpUi(tester);
      await tester.ensureVisible(find.widgetWithText(TextButton, 'Search'));
      await tester.tap(find.widgetWithText(TextButton, 'Search'));
      await pumpUi(tester);

      expect(find.byType(FolderVerticalCardsView), findsOneWidget);
      expect(find.text('Petronas Twin Towers'), findsOneWidget);
      expect(find.text('Batu Caves'), findsNothing);
    });

    testWidgets('text detail search uses dropdown of values',
        (WidgetTester tester) async {
      await pumpFolderScreen(tester);

      await openSearchDialog(tester);
      final locationDropdown = _dropdownByPlaceholder('Location');
      await tester.ensureVisible(locationDropdown);
      await tester.tap(locationDropdown);
      await pumpUi(tester);

      final option = find.text('Penang, Malaysia');
      await tester.ensureVisible(option.last);
      await tester.tap(option.last);
      await pumpUi(tester);

      await tester.ensureVisible(find.widgetWithText(TextButton, 'Search'));
      await tester.tap(find.widgetWithText(TextButton, 'Search'));
      await pumpUi(tester);

      expect(find.byType(FolderVerticalCardsView), findsNothing);
      expect(find.text('George Town Heritage Zone'), findsOneWidget);
      expect(find.text('Petronas Twin Towers'), findsNothing);
    });

    testWidgets('yes/no detail search filters with Yes/No cell',
        (WidgetTester tester) async {
      await pumpFolderScreen(tester);

      await openSearchDialog(tester);
      expect(find.text('Accessible by train:'), findsOneWidget);
      expect(find.byType(SegmentedButton<bool>), findsOneWidget);

      final yesLabel = find.descendant(
        of: find.byType(SegmentedButton<bool>),
        matching: find.text('Yes'),
      );
      await tester.ensureVisible(yesLabel);
      await tester.tap(yesLabel);
      await pumpUi(tester);

      await tester.ensureVisible(find.widgetWithText(TextButton, 'Search'));
      await tester.tap(find.widgetWithText(TextButton, 'Search'));
      await pumpUi(tester);

      expect(find.text('Petronas Twin Towers'), findsOneWidget);
      expect(find.text('Batu Caves'), findsOneWidget);
      expect(find.text('George Town Heritage Zone'), findsNothing);
      expect(find.text('Langkawi Sky Bridge'), findsNothing);
    });

    testWidgets('clear restores accordion view', (WidgetTester tester) async {
      await pumpFolderScreen(tester);

      await openSearchDialog(tester);
      await tester.enterText(_fieldByHint('Search'), 'Petronas');
      await pumpUi(tester);
      await tester.ensureVisible(find.widgetWithText(TextButton, 'Search'));
      await tester.tap(find.widgetWithText(TextButton, 'Search'));
      await pumpUi(tester);
      expect(find.byType(FolderVerticalCardsView), findsOneWidget);

      await openSearchDialog(tester);
      await tester.ensureVisible(find.widgetWithText(TextButton, 'Clear'));
      await tester.tap(find.widgetWithText(TextButton, 'Clear'));
      await pumpUi(tester);

      expect(find.byType(FolderVerticalCardsView), findsNothing);
      expect(find.text('Petronas Twin Towers'), findsOneWidget);
      expect(find.text('Batu Caves'), findsOneWidget);
    });
  });
}
