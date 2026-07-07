import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:choices/data/folders_repository.dart';
// import 'package:choices/models/category_item.dart';
import 'package:choices/screens/category_item_changes_screen.dart';
// import 'package:choices/widgets/choices_drawer.dart';

void main() {
  setUp(() {
    FoldersRepository.instance.configureForTesting();
  });

  testWidgets('Category item changes screen shows hardcoded tree content',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CategoryItemChangesScreen(
          filter: CategoryFilter.all(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trip to Japan'), findsOneWidget);
    expect(find.text('Where to eat in Malaysia'), findsOneWidget);
    expect(find.text('Choice of unis'), findsOneWidget);
    expect(find.text('Where to eat'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });

  testWidgets('Category item changes screen shows single folder only',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CategoryItemChangesScreen(
          filter: CategoryFilter.folder('trip_to_japan'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trip to Japan'), findsOneWidget);
    expect(find.text('Where to eat'), findsOneWidget);
    expect(find.text('Where to eat in Malaysia'), findsNothing);
    expect(find.text('Choice of unis'), findsNothing);
  });
}
