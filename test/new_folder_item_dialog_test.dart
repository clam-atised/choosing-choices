import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:choices/data/folders_repository.dart';
import 'package:choices/screens/home_screen.dart';
import 'package:choices/widgets/new_folder_item_dialog.dart';

Finder _fieldByHint(String hint) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is TextField &&
        widget.decoration?.hintText == hint,
  );
}

void main() {
  setUp(() {
    FoldersRepository.instance.configureForTesting();
  });

  Future<void> openNewDialog(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
  }

  testWidgets('Add button opens New dialog with fields and dropdown',
      (WidgetTester tester) async {
    await openNewDialog(tester);

    expect(find.text('New'), findsOneWidget);
    expect(find.text('Add folder name'), findsOneWidget);
    expect(find.text('Add item'), findsOneWidget);
    expect(find.text('to folder:'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
    expect(find.text('Trip to Japan'), findsOneWidget);
  });

  testWidgets('Dropdown lists repository folder names when expanded',
      (WidgetTester tester) async {
    await openNewDialog(tester);

    await tester.tap(find.text('Trip to Japan'));
    await tester.pumpAndSettle();

    expect(find.text('Where to eat in Malaysia'), findsOneWidget);
    expect(find.text('Choice of unis'), findsOneWidget);
  });

  testWidgets('Create with folder name only adds folder to repository',
      (WidgetTester tester) async {
    await openNewDialog(tester);

    final initialCount = FoldersRepository.instance.folders.length;

    await tester.enterText(_fieldByHint('Add folder name'), 'My New Folder');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.byType(NewFolderItemDialog), findsNothing);
    expect(FoldersRepository.instance.folders.length, initialCount + 1);
    expect(
      FoldersRepository.instance.folderByName('My New Folder'),
      isNotNull,
    );
  });

  testWidgets('Create with item only adds item to selected folder',
      (WidgetTester tester) async {
    await openNewDialog(tester);

    await tester.enterText(_fieldByHint('Add item'), 'New sub item');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    final folder = FoldersRepository.instance.folderByName('Trip to Japan');
    expect(folder, isNotNull);
    expect(
      folder!.items.any((item) => item.name == 'New sub item'),
      isTrue,
    );
  });

  testWidgets('Create with both fields adds folder and item',
      (WidgetTester tester) async {
    await openNewDialog(tester);

    await tester.enterText(_fieldByHint('Add folder name'), 'Combined Folder');
    await tester.enterText(_fieldByHint('Add item'), 'Combined Item');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    final folder = FoldersRepository.instance.folderByName('Combined Folder');
    expect(folder, isNotNull);
    expect(
      folder!.items.any((item) => item.name == 'Combined Item'),
      isTrue,
    );
  });

  testWidgets('Create with empty fields does not change repository',
      (WidgetTester tester) async {
    await openNewDialog(tester);

    final initialCount = FoldersRepository.instance.folders.length;

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.byType(NewFolderItemDialog), findsOneWidget);
    expect(FoldersRepository.instance.folders.length, initialCount);
  });
}
