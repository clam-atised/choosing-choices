import 'package:flutter_test/flutter_test.dart';

import 'package:choices/data/cards_repository.dart';
import 'package:choices/data/folders_repository.dart';
import 'package:choices/models/backup_data.dart';
import 'package:choices/models/backup_diff.dart';
import 'package:choices/models/category_item.dart';
import 'package:choices/models/choice_card.dart';
import 'package:choices/services/backup_service.dart';

import 'test_helpers.dart';

void main() {
  setUp(() async {
    await configureRepositoriesForTesting();
  });

  const folder = Folder(
    id: 'folder_a',
    name: 'Trip A',
    items: [
      CategoryItem(id: 'cat_1', name: 'Stay'),
      CategoryItem(id: 'cat_2', name: 'Food'),
    ],
  );

  const deviceCard = ChoiceCard(
    id: 'card_1',
    folderId: 'folder_a',
    categoryItemId: 'cat_1',
    title: 'Hotel Device',
  );

  const backupCard = ChoiceCard(
    id: 'card_1',
    folderId: 'folder_a',
    categoryItemId: 'cat_1',
    title: 'Hotel Backup',
  );

  const newBackupCard = ChoiceCard(
    id: 'card_2',
    folderId: 'folder_a',
    categoryItemId: 'cat_2',
    title: 'Cafe New',
  );

  test('zip round-trip preserves folders and cards without images', () async {
    final zipBytes = await BackupService.instance.buildBackupZipBytes(
      folders: [folder],
      cards: [deviceCard, newBackupCard],
      colourTemplateName: 'Ocean',
    );

    final restored = await BackupService.instance.importBackupBytes(zipBytes);

    expect(restored.version, BackupData.currentVersion);
    expect(restored.folders, hasLength(1));
    expect(restored.folders.first.name, 'Trip A');
    expect(restored.folders.first.items, hasLength(2));
    expect(restored.cards, hasLength(2));
    expect(restored.cards.map((c) => c.title), containsAll(['Hotel Device', 'Cafe New']));
    expect(restored.settings.colourTemplateName, 'Ocean');
  });

  test('diff detects changed and added categories and cards', () {
    final deviceFolders = [
      folder.copyWith(
        items: [
          const CategoryItem(id: 'cat_1', name: 'Stay Device'),
          const CategoryItem(id: 'cat_2', name: 'Food'),
        ],
      ),
    ];
    final backup = BackupData(
      folders: [
        folder.copyWith(
          items: [
            const CategoryItem(id: 'cat_1', name: 'Stay Backup'),
            const CategoryItem(id: 'cat_2', name: 'Food'),
            const CategoryItem(id: 'cat_3', name: 'Transport'),
          ],
        ),
      ],
      cards: [backupCard, newBackupCard],
    );

    final diff = BackupService.instance.diffAgainstDevice(
      backup: backup,
      deviceFolders: deviceFolders,
      deviceCards: [deviceCard],
    );

    expect(diff.hasConflicts, isTrue);
    expect(diff.changedCategories.map((e) => e.id), contains('cat_1'));
    expect(diff.changedCards.map((e) => e.id), contains('card_1'));
    expect(diff.addedCategories.map((e) => e.id), contains('cat_3'));
    expect(diff.addedCards.map((e) => e.id), contains('card_2'));
  });

  test('diff has no conflicts when content matches', () {
    final backup = BackupData(
      folders: [folder],
      cards: [deviceCard],
    );

    final diff = BackupService.instance.diffAgainstDevice(
      backup: backup,
      deviceFolders: [folder],
      deviceCards: [deviceCard],
    );

    expect(diff.hasConflicts, isFalse);
    expect(diff.isEmpty, isTrue);
  });

  test('merge retain keeps device conflicts and adds new items', () async {
    final folders = FoldersRepository.instance;
    final cards = CardsRepository.instance;
    folders.resetToDefaults();
    cards.resetForTesting();

    await folders.mergeFromBackup([folder], mode: BackupMergeMode.replace);
    await cards.mergeFromBackup([deviceCard], mode: BackupMergeMode.replace);

    final backup = BackupData(
      folders: [
        folder.copyWith(
          name: 'Trip Backup',
          items: [
            const CategoryItem(id: 'cat_1', name: 'Stay Backup'),
            const CategoryItem(id: 'cat_2', name: 'Food'),
            const CategoryItem(id: 'cat_3', name: 'Transport'),
          ],
        ),
      ],
      cards: [backupCard, newBackupCard],
    );

    await BackupService.instance.mergeBackup(
      backup: backup,
      mode: BackupMergeMode.retain,
      foldersRepository: folders,
      cardsRepository: cards,
    );

    final mergedFolder = folders.folderById('folder_a')!;
    expect(mergedFolder.name, 'Trip A');
    expect(
      mergedFolder.items.map((item) => item.name),
      containsAll(['Stay', 'Food', 'Transport']),
    );
    expect(folders.itemById('folder_a', 'cat_1')!.name, 'Stay');

    expect(cards.cards.map((c) => c.id), containsAll(['card_1', 'card_2']));
    expect(
      cards.cards.firstWhere((c) => c.id == 'card_1').title,
      'Hotel Device',
    );
    expect(
      cards.cards.firstWhere((c) => c.id == 'card_2').title,
      'Cafe New',
    );
  });

  test('merge replace overwrites conflicts and adds new items', () async {
    final folders = FoldersRepository.instance;
    final cards = CardsRepository.instance;
    folders.resetToDefaults();
    cards.resetForTesting();

    await folders.mergeFromBackup([folder], mode: BackupMergeMode.replace);
    await cards.mergeFromBackup([deviceCard], mode: BackupMergeMode.replace);

    final backup = BackupData(
      folders: [
        folder.copyWith(
          name: 'Trip Backup',
          items: [
            const CategoryItem(id: 'cat_1', name: 'Stay Backup'),
            const CategoryItem(id: 'cat_2', name: 'Food'),
            const CategoryItem(id: 'cat_3', name: 'Transport'),
          ],
        ),
      ],
      cards: [backupCard, newBackupCard],
    );

    await BackupService.instance.mergeBackup(
      backup: backup,
      mode: BackupMergeMode.replace,
      foldersRepository: folders,
      cardsRepository: cards,
    );

    final mergedFolder = folders.folderById('folder_a')!;
    expect(mergedFolder.name, 'Trip Backup');
    expect(folders.itemById('folder_a', 'cat_1')!.name, 'Stay Backup');
    expect(folders.itemById('folder_a', 'cat_3')!.name, 'Transport');

    expect(
      cards.cards.firstWhere((c) => c.id == 'card_1').title,
      'Hotel Backup',
    );
    expect(
      cards.cards.firstWhere((c) => c.id == 'card_2').title,
      'Cafe New',
    );
  });

  test('invalid zip without backup.json throws', () async {
    expect(
      () => BackupService.instance.importBackupBytes(const [1, 2, 3, 4]),
      throwsA(isA<BackupException>()),
    );
  });
}
