import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// import 'package:choices/data/folders_repository.dart';
import 'package:choices/main.dart';
import 'package:choices/screens/folder_content_screen.dart';
// import 'package:choices/widgets/new_folder_item_dialog.dart';
import 'test_helpers.dart';

void main() {
  setUp(() async {
    await configureRepositoriesForTesting();
  });

  testWidgets('App opens Trip To Malaysia folder content', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await pumpUi(tester);

    expect(find.byType(FolderContentScreen), findsOneWidget);
    expect(find.text('Trip To Malaysia'), findsOneWidget);
    expect(find.text('Places to visit'), findsOneWidget);
    expect(find.text('Petronas Twin Towers'), findsOneWidget);
  });

  testWidgets('Add button opens create actions menu',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await pumpUi(tester);

    await tester.tap(find.byIcon(Icons.add));
    await pumpUi(tester);

    expect(find.text('Create folder'), findsOneWidget);
    expect(find.text('Create category'), findsOneWidget);
    expect(find.text('Create card'), findsOneWidget);
  });

  testWidgets('Search button opens folder search dialog',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await pumpUi(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.search),
      ),
    );
    await pumpUi(tester);

    expect(find.text('Details:'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Clear'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Search'), findsOneWidget);
  });
}
