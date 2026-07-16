import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:choices/data/folders_repository.dart';
import 'package:choices/screens/folder_content_screen.dart';
import 'test_helpers.dart';

void main() {
  setUp(() async {
    await configureRepositoriesForTesting();
  });

  testWidgets('App starts on FolderContentScreen with Malaysia data',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FolderContentScreen(
          folderId: FoldersRepository.seedFolderId,
        ),
      ),
    );
    await pumpUi(tester);

    expect(find.byType(FolderContentScreen), findsOneWidget);
    expect(find.text('Places to visit'), findsOneWidget);
    expect(find.text('Petronas Twin Towers'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('Folder category name tap toggles expanded section',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FolderContentScreen(
          folderId: FoldersRepository.seedFolderId,
        ),
      ),
    );
    await pumpUi(tester);

    expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);

    await tester.tap(find.text('Places to visit'));
    await pumpUi(tester);

    expect(find.byIcon(Icons.arrow_right), findsWidgets);
  });

  testWidgets('Folder category arrow toggles expanded section',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FolderContentScreen(
          folderId: FoldersRepository.seedFolderId,
        ),
      ),
    );
    await pumpUi(tester);

    expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await pumpUi(tester);

    expect(find.byIcon(Icons.arrow_right), findsWidgets);
  });

  testWidgets('Folder content stays left-aligned on wide layout',
      (WidgetTester tester) async {
    await TestWidgetsFlutterBinding.ensureInitialized()
        .setSurfaceSize(const Size(1200, 900));
    addTearDown(() async {
      await TestWidgetsFlutterBinding.ensureInitialized().setSurfaceSize(null);
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: FolderContentScreen(
          folderId: FoldersRepository.seedFolderId,
        ),
      ),
    );
    await pumpUi(tester);

    final labelX = tester.getTopLeft(find.text('Places to visit')).dx;
    expect(labelX, lessThan(140));
  });
}
