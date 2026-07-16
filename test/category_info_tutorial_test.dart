import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:choices/screens/category_item_changes_screen.dart';
import 'package:choices/widgets/category_info_tutorial_dialog.dart';
import 'test_helpers.dart';

bool _isTutorialStepImage(Widget widget, String assetPath) {
  return widget is Image &&
      widget.image is AssetImage &&
      (widget.image as AssetImage).assetName == assetPath;
}

Future<void> _openTutorial(WidgetTester tester) async {
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
}

void main() {
  setUp(() async {
    await configureRepositoriesForTesting();
  });

  testWidgets('Info tutorial advances through pages and closes on 4th forward tap',
      (WidgetTester tester) async {
    await _openTutorial(tester);

    expect(
      find.text('Long press on folder icon to move folder arrangement'),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => _isTutorialStepImage(
          widget,
          'assets/tutorial/tutorial_step_1.png',
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Press on Folder name to change name, hide and export contents',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => _isTutorialStepImage(
          widget,
          'assets/tutorial/tutorial_step_2.png',
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Press on Item name to change name, direction of content and export contents',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => _isTutorialStepImage(
          widget,
          'assets/tutorial/tutorial_step_3.png',
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Press on Item name to change name, direction of content and export contents',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(find.byType(CategoryInfoTutorialDialog), findsNothing);
  });

  testWidgets('Info tutorial keeps fixed card width on wide layout',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _openTutorial(tester);

    final dialogFinder = find.byType(CategoryInfoTutorialDialog);
    expect(dialogFinder, findsOneWidget);

    final fixedWidthCard = find.descendant(
      of: dialogFinder,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox &&
            widget.width == CategoryInfoTutorialDialog.cardWidth &&
            widget.child is ClipRRect,
      ),
    );
    expect(fixedWidthCard, findsOneWidget);
  });
}
