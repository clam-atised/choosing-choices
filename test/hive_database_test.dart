import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:choices/data/cards_repository.dart';
import 'package:choices/data/folders_repository.dart';
import 'package:choices/data/hive/hive_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('choices_hive_test_');
    await HiveDatabase.initForTesting(path: tempDir.path);
    FoldersRepository.instance.configureForTesting(inMemoryOnly: false);
    CardsRepository.instance.configureForTesting(inMemoryOnly: false);
  });

  tearDown(() async {
    await HiveDatabase.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('seeds Hive boxes once and persists user changes', () async {
    await FoldersRepository.instance.load();
    await CardsRepository.instance.load();

    expect(FoldersRepository.instance.folders, isNotEmpty);
    expect(CardsRepository.instance.cards, isNotEmpty);
    expect(HiveDatabase.foldersIsEmpty, isFalse);
    expect(HiveDatabase.cardsIsEmpty, isFalse);

    final originalFolderName =
        FoldersRepository.instance.folders.first.name;
    await FoldersRepository.instance.updateFolderName(
      FoldersRepository.instance.folders.first.id,
      'Updated Folder Name',
    );

    FoldersRepository.instance.resetToDefaults();
    CardsRepository.instance.resetForTesting();

    await FoldersRepository.instance.load();
    await CardsRepository.instance.load();

    expect(FoldersRepository.instance.folders.first.name, 'Updated Folder Name');
    expect(
      FoldersRepository.instance.folders.first.name,
      isNot(originalFolderName),
    );
    expect(CardsRepository.instance.cards, isNotEmpty);
  });
}
