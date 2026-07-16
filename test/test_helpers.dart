import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:choices/data/cards_repository.dart';
import 'package:choices/data/folders_repository.dart';

Future<void> configureRepositoriesForTesting() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  FoldersRepository.instance.configureForTesting();
  CardsRepository.instance.configureForTesting();
  await FoldersRepository.instance.load();
  await CardsRepository.instance.load();
}

/// Use instead of [WidgetTester.pumpAndSettle] when a [PageView] is on screen.
Future<void> pumpUi(WidgetTester tester, [Duration duration = const Duration(milliseconds: 100)]) async {
  await tester.pump();
  await tester.pump(duration);
}
