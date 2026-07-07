import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:choices/data/cards_repository.dart';
import 'package:choices/data/folders_repository.dart';
import 'package:choices/screens/category_content_screen.dart';
import 'package:choices/screens/folder_content_screen.dart';
import 'package:choices/screens/home_screen.dart';
import 'package:choices/widgets/add_card_dialog.dart';

void main() {
  setUp(() {
    FoldersRepository.instance.configureForTesting();
    CardsRepository.instance.configureForTesting();
  });

  testWidgets('Drawer folder tap navigates to FolderContentScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trip to Japan'));
    await tester.pumpAndSettle();

    expect(find.byType(FolderContentScreen), findsOneWidget);
    expect(find.text('Where to eat'), findsOneWidget);
  });

  testWidgets('Folder category name tap opens CategoryContentScreen with Add Card dialog',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FolderContentScreen(folderId: 'trip_to_japan'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Where to eat'));
    await tester.pumpAndSettle();

    expect(find.byType(CategoryContentScreen), findsOneWidget);
    expect(find.byType(AddCardDialog), findsOneWidget);
    expect(find.text('Title'), findsOneWidget);
  });

  testWidgets('Folder category arrow toggles expanded section',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FolderContentScreen(folderId: 'trip_to_japan'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_right), findsWidgets);
  });
}
