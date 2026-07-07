import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:choices/data/folders_repository.dart';
import 'package:choices/screens/category_item_changes_screen.dart';
import 'package:choices/widgets/category_info_tutorial_dialog.dart';

void main() {
  setUp(() {
    FoldersRepository.instance.configureForTesting();
  });

  testWidgets('Info tutorial advances through pages and closes on 4th tap',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CategoryItemChangesScreen(
          filter: CategoryFilter.all(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();

    expect(
      find.text('Long press on folder icon to move folder arrangement'),
      findsOneWidget,
    );

    await tester.tap(find.byType(CategoryInfoTutorialDialog));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Press on Folder name to change name, hide and export contents',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byType(CategoryInfoTutorialDialog));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Press on Item name to change name, direction of content and export contents',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byType(CategoryInfoTutorialDialog));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Press on Item name to change name, direction of content and export contents',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byType(CategoryInfoTutorialDialog));
    await tester.pumpAndSettle();

    expect(find.byType(CategoryInfoTutorialDialog), findsNothing);
  });
}
