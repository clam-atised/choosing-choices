import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:choices/data/folders_repository.dart';
import 'package:choices/models/category_item.dart';
import 'package:choices/screens/category_item_changes_screen.dart';
import 'package:choices/widgets/choices_drawer.dart';
import 'test_helpers.dart';

void main() {
  setUp(() async {
    await configureRepositoriesForTesting();
  });

  testWidgets('Tapping folder name opens folder settings dialog',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CategoryItemChangesScreen(
          filter: CategoryFilter.all(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Trip To Malaysia'));
    await tester.pumpAndSettle();

    expect(find.text('Hide folder:'), findsOneWidget);
    expect(find.text('Export data'), findsOneWidget);
    expect(find.text('Delete folder & contents'), findsOneWidget);
    expect(find.text('Unhide'), findsOneWidget);
  });

  testWidgets('Selecting Hide marks folder hidden in drawer',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          drawer: ChoicesDrawer(),
          body: CategoryItemChangesScreen(
            filter: CategoryFilter.all(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Trip To Malaysia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hide'));
    await tester.pumpAndSettle();

    expect(
      FoldersRepository.instance.folderById(FoldersRepository.seedFolderId)!.isHidden,
      isTrue,
    );
  });

  testWidgets('Tapping sub-item opens item settings dialog',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CategoryItemChangesScreen(
          filter: CategoryFilter.all(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Places to visit'));
    await tester.pumpAndSettle();

    expect(find.text('Card display direction:'), findsOneWidget);
    expect(find.text('Horizontal'), findsOneWidget);
    expect(find.text('Vertical'), findsOneWidget);
    expect(find.text('Delete item & contents'), findsOneWidget);
  });

  testWidgets('Selecting Vertical persists card display direction',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CategoryItemChangesScreen(
          filter: CategoryFilter.all(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Places to visit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vertical'));
    await tester.pumpAndSettle();

    final item = FoldersRepository.instance.itemById(
      FoldersRepository.seedFolderId,
      'places_to_visit',
    );
    expect(item?.cardDisplayDirection, CardDisplayDirection.vertical);
  });

  testWidgets('Delete folder removes it from repository and tree',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CategoryItemChangesScreen(
          filter: CategoryFilter.all(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Trip To Malaysia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete folder & contents'));
    await tester.pumpAndSettle();

    expect(
      FoldersRepository.instance.folderById(FoldersRepository.seedFolderId),
      isNull,
    );
    expect(find.text('Trip To Malaysia'), findsNothing);
  });
}
