import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';

import '../data/cards_repository.dart';
import '../data/colour_templates_repository.dart';
import '../data/folders_repository.dart';
import '../models/backup_data.dart';
import '../models/backup_diff.dart';
import '../models/category_item.dart';
import '../models/choice_card.dart';
import '../platform/file_storage.dart';
import 'backup_file_io.dart';

class BackupException implements Exception {
  BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackupService {
  BackupService._();

  static final BackupService instance = BackupService._();

  String _backupFileName() {
    final now = DateTime.now();
    final stamp =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    return 'choices_backup_$stamp.zip';
  }

  String _zipImagePath(String cardId, String extension) {
    return 'images/$cardId.$extension';
  }

  String _extensionFromPath(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == path.length - 1) {
      return 'jpg';
    }
    return path.substring(dotIndex + 1).toLowerCase();
  }

  bool _isBundledAsset(String? path) {
    return path != null && path.startsWith('assets/');
  }

  Map<String, dynamic> _cardContentForCompare(ChoiceCard card) {
    final json = card.toJson();
    // Local absolute paths differ across devices; compare image presence by
    // whether a non-asset image exists, plus the rest of the card fields.
    final imagePath = card.imagePath;
    if (imagePath == null) {
      json['imagePath'] = null;
    } else if (_isBundledAsset(imagePath)) {
      json['imagePath'] = imagePath;
    } else {
      json['imagePath'] = 'local:${card.id}';
    }
    return json;
  }

  String _encodeComparable(Object? value) => jsonEncode(value);

  Future<String?> exportBackup({
    List<Folder>? folders,
    List<ChoiceCard>? cards,
    String? colourTemplateName,
  }) async {
    if (kIsWeb) {
      throw BackupException('Backup is not supported on web.');
    }

    final sourceFolders = folders ?? FoldersRepository.instance.folders;
    final sourceCards = cards ?? CardsRepository.instance.cards;
    final templateName = colourTemplateName ??
        ColourTemplatesRepository.instance.selectedTemplateName;

    final exportCards = <ChoiceCard>[];
    final archive = Archive();

    for (final card in sourceCards) {
      final imagePath = card.imagePath;
      if (imagePath == null || _isBundledAsset(imagePath)) {
        exportCards.add(card);
        continue;
      }

      try {
        final bytes = await readFileAsBytes(imagePath);
        final extension = _extensionFromPath(imagePath);
        final zipPath = _zipImagePath(card.id, extension);
        archive.addFile(ArchiveFile(zipPath, bytes.length, bytes));
        exportCards.add(
          card.copyWith(imagePath: card.id),
        );
      } catch (_) {
        exportCards.add(_cardWithoutLocalImage(card));
      }
    }

    final backup = BackupData(
      folders: sourceFolders,
      cards: exportCards,
      settings: BackupSettingsData(colourTemplateName: templateName),
    );

    final jsonBytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(backup.toJson()),
    );
    archive.addFile(
      ArchiveFile(BackupData.backupJsonName, jsonBytes.length, jsonBytes),
    );

    final zipBytes = ZipEncoder().encode(archive);
    return saveBackupZip(
      bytes: zipBytes,
      fileName: _backupFileName(),
    );
  }

  ChoiceCard _cardWithoutLocalImage(ChoiceCard card) {
    return ChoiceCard(
      id: card.id,
      folderId: card.folderId,
      categoryItemId: card.categoryItemId,
      title: card.title,
      details: card.details,
      isStamped: card.isStamped,
    );
  }

  Future<BackupData> importBackupBytes(List<int> bytes) async {
    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw BackupException('Invalid backup: could not read zip file.');
    }
    final jsonFile = archive.findFile(BackupData.backupJsonName);
    if (jsonFile == null) {
      throw BackupException('Invalid backup: missing backup.json.');
    }

    late final BackupData backup;
    try {
      backup = BackupData.fromJson(
        jsonDecode(utf8.decode(jsonFile.content as List<int>))
            as Map<String, dynamic>,
      );
    } catch (error) {
      if (error is BackupException) rethrow;
      throw BackupException('Invalid backup: could not parse backup.json.');
    }

    final restoredCards = <ChoiceCard>[];
    for (final card in backup.cards) {
      final imageRef = card.imagePath;
      if (imageRef == null || _isBundledAsset(imageRef)) {
        restoredCards.add(card);
        continue;
      }

      // Export stores card id (or id.ext) as the imagePath placeholder.
      final cardId = imageRef.contains('.')
          ? imageRef.substring(0, imageRef.lastIndexOf('.'))
          : imageRef;
      var imageFile = archive.findFile(_zipImagePath(cardId, 'jpg'));
      if (imageFile == null) {
        final matches = archive.files.where(
          (file) => file.name.startsWith('images/$cardId.'),
        );
        imageFile = matches.isEmpty ? null : matches.first;
      }

      if (imageFile == null) {
        restoredCards.add(_cardWithoutLocalImage(card));
        continue;
      }

      final extension = _extensionFromPath(imageFile.name);
      final content = Uint8List.fromList(imageFile.content as List<int>);
      final localPath = await writeRestoredCardImage(
        cardId: card.id,
        bytes: content,
        extension: extension,
      );
      restoredCards.add(card.copyWith(imagePath: localPath));
    }

    return BackupData(
      version: backup.version,
      folders: backup.folders,
      cards: restoredCards,
      settings: backup.settings,
    );
  }

  Future<BackupData?> pickAndImportBackup() async {
    if (kIsWeb) {
      throw BackupException('Load data is not supported on web.');
    }
    final bytes = await pickBackupZip();
    if (bytes == null) return null;
    return importBackupBytes(bytes);
  }

  /// Builds a zip in memory and re-imports it (for tests / round-trip).
  @visibleForTesting
  Future<List<int>> buildBackupZipBytes({
    required List<Folder> folders,
    required List<ChoiceCard> cards,
    String? colourTemplateName,
  }) async {
    final exportCards = <ChoiceCard>[];
    final archive = Archive();

    for (final card in cards) {
      final imagePath = card.imagePath;
      if (imagePath == null || _isBundledAsset(imagePath)) {
        exportCards.add(card);
        continue;
      }

      try {
        final bytes = await readFileAsBytes(imagePath);
        final extension = _extensionFromPath(imagePath);
        final zipPath = _zipImagePath(card.id, extension);
        archive.addFile(ArchiveFile(zipPath, bytes.length, bytes));
        exportCards.add(card.copyWith(imagePath: card.id));
      } catch (_) {
        exportCards.add(_cardWithoutLocalImage(card));
      }
    }

    final backup = BackupData(
      folders: folders,
      cards: exportCards,
      settings: BackupSettingsData(colourTemplateName: colourTemplateName),
    );
    final jsonBytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(backup.toJson()),
    );
    archive.addFile(
      ArchiveFile(BackupData.backupJsonName, jsonBytes.length, jsonBytes),
    );
    return ZipEncoder().encode(archive);
  }

  BackupDiff diffAgainstDevice({
    required BackupData backup,
    List<Folder>? deviceFolders,
    List<ChoiceCard>? deviceCards,
  }) {
    final folders = deviceFolders ?? FoldersRepository.instance.folders;
    final cards = deviceCards ?? CardsRepository.instance.cards;

    final folderById = {for (final folder in folders) folder.id: folder};
    final cardById = {for (final card in cards) card.id: card};

    final deviceCategoryById = <String, ({Folder folder, CategoryItem item})>{};
    for (final folder in folders) {
      for (final item in folder.items) {
        deviceCategoryById[item.id] = (folder: folder, item: item);
      }
    }

    final backupCategoryById = <String, ({Folder folder, CategoryItem item})>{};
    for (final folder in backup.folders) {
      for (final item in folder.items) {
        backupCategoryById[item.id] = (folder: folder, item: item);
      }
    }

    final changedCategories = <BackupDiffEntry>[];
    final addedCategories = <BackupDiffEntry>[];
    final addedFolders = <BackupDiffEntry>[];

    for (final folder in backup.folders) {
      final existingFolder = folderById[folder.id];
      if (existingFolder == null) {
        addedFolders.add(
          BackupDiffEntry(id: folder.id, label: folder.name),
        );
        for (final item in folder.items) {
          addedCategories.add(
            BackupDiffEntry(
              id: item.id,
              label: '${folder.name} / ${item.name}',
            ),
          );
        }
        continue;
      }

      // Folder-level metadata change is surfaced via categories / name.
      for (final item in folder.items) {
        final existing = deviceCategoryById[item.id];
        if (existing == null) {
          addedCategories.add(
            BackupDiffEntry(
              id: item.id,
              label: '${folder.name} / ${item.name}',
            ),
          );
          continue;
        }

        final deviceJson = _encodeComparable(existing.item.toJson());
        final backupJson = _encodeComparable(item.toJson());
        final folderNameChanged = existing.folder.name != folder.name ||
            existing.folder.isHidden != folder.isHidden;
        if (deviceJson != backupJson || folderNameChanged) {
          changedCategories.add(
            BackupDiffEntry(
              id: item.id,
              label: '${folder.name} / ${item.name}',
            ),
          );
        }
      }
    }

    final changedCards = <BackupDiffEntry>[];
    final addedCards = <BackupDiffEntry>[];

    for (final card in backup.cards) {
      final existing = cardById[card.id];
      final folderName = _folderNameFor(
        folders: [...folders, ...backup.folders],
        folderId: card.folderId,
      );
      final categoryName = _categoryNameFor(
        folders: [...folders, ...backup.folders],
        folderId: card.folderId,
        categoryId: card.categoryItemId,
      );
      final label = '$folderName / $categoryName / ${card.title}';

      if (existing == null) {
        addedCards.add(BackupDiffEntry(id: card.id, label: label));
        continue;
      }

      final deviceJson = _encodeComparable(_cardContentForCompare(existing));
      final backupJson = _encodeComparable(_cardContentForCompare(card));
      if (deviceJson != backupJson) {
        changedCards.add(BackupDiffEntry(id: card.id, label: label));
      }
    }

    return BackupDiff(
      changedCategories: changedCategories,
      changedCards: changedCards,
      addedFolders: addedFolders,
      addedCategories: addedCategories,
      addedCards: addedCards,
    );
  }

  String _folderNameFor({
    required List<Folder> folders,
    required String folderId,
  }) {
    for (final folder in folders) {
      if (folder.id == folderId) return folder.name;
    }
    return folderId;
  }

  String _categoryNameFor({
    required List<Folder> folders,
    required String folderId,
    required String categoryId,
  }) {
    for (final folder in folders) {
      if (folder.id != folderId) continue;
      for (final item in folder.items) {
        if (item.id == categoryId) return item.name;
      }
    }
    return categoryId;
  }

  Future<void> mergeBackup({
    required BackupData backup,
    required BackupMergeMode mode,
    FoldersRepository? foldersRepository,
    CardsRepository? cardsRepository,
    ColourTemplatesRepository? colourTemplatesRepository,
  }) async {
    final foldersRepo = foldersRepository ?? FoldersRepository.instance;
    final cardsRepo = cardsRepository ?? CardsRepository.instance;
    final coloursRepo =
        colourTemplatesRepository ?? ColourTemplatesRepository.instance;

    await foldersRepo.mergeFromBackup(backup.folders, mode: mode);
    await cardsRepo.mergeFromBackup(backup.cards, mode: mode);

    final templateName = backup.settings.colourTemplateName;
    if (templateName != null && templateName.isNotEmpty) {
      await coloursRepo.selectTemplateByName(templateName);
    }
  }
}
