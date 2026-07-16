import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:choices/data/folders_repository.dart';
import 'package:choices/screens/category_item_changes_screen.dart';
import 'test_helpers.dart';

void main() {
  setUp(() async {
    await configureRepositoriesForTesting();
  });

  testWidgets('Category item changes screen shows seed tree content',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CategoryItemChangesScreen(
          filter: CategoryFilter.all(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trip To Malaysia'), findsOneWidget);
    expect(find.text('Places to visit'), findsOneWidget);
    expect(find.text('Restaurant recommendations'), findsOneWidget);
    expect(find.text('Activities'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });

  testWidgets('Category item changes screen shows single folder only',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CategoryItemChangesScreen(
          filter: CategoryFilter.folder(FoldersRepository.seedFolderId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trip To Malaysia'), findsOneWidget);
    expect(find.text('Places to visit'), findsOneWidget);
    expect(find.text('Restaurant recommendations'), findsOneWidget);
  });
}
