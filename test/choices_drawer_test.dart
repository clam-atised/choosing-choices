import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:choices/data/folders_repository.dart';
import 'package:choices/screens/folder_content_screen.dart';
import 'package:choices/widgets/choices_drawer.dart';
import 'test_helpers.dart';

void main() {
  setUp(() async {
    await configureRepositoriesForTesting();
  });

  Future<void> openDrawer(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          drawer: ChoicesDrawer(),
          body: SizedBox.expand(),
        ),
      ),
    );
    await pumpUi(tester);

    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await pumpUi(tester);
  }

  testWidgets('Shows Add New Folder + when all folders are deleted',
      (WidgetTester tester) async {
    await FoldersRepository.instance.deleteFolder(
      FoldersRepository.seedFolderId,
    );

    await openDrawer(tester);

    expect(find.text('Add New Folder +'), findsOneWidget);
    expect(find.text('Trip To Malaysia'), findsNothing);
  });

  testWidgets('Shows Add New Folder + when all folders are hidden',
      (WidgetTester tester) async {
    await FoldersRepository.instance.setFolderHidden(
      FoldersRepository.seedFolderId,
      true,
    );

    await openDrawer(tester);

    expect(find.text('Add New Folder +'), findsOneWidget);
    expect(find.text('Trip To Malaysia'), findsOneWidget);
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
  });

  testWidgets('Add New Folder + creates folder and opens its content screen',
      (WidgetTester tester) async {
    await FoldersRepository.instance.deleteFolder(
      FoldersRepository.seedFolderId,
    );

    await openDrawer(tester);

    await tester.tap(find.text('Add New Folder +'));
    await pumpUi(tester);

    expect(find.text('Create'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'Weekend Plans');
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Create'));
    await pumpUi(tester);

    expect(find.byType(FolderContentScreen), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FolderContentScreen),
        matching: find.text('Weekend Plans'),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.text("Press '+' to add new category"), findsOneWidget);
  });
}
