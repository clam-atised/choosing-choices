import 'package:flutter/foundation.dart';

import '../models/backup_diff.dart';
import '../models/category_detail_definition.dart';
import '../models/category_item.dart';
import 'cards_repository.dart';
import 'hive/hive_database.dart';
import 'seed_data_loader.dart';

class FoldersRepository extends ChangeNotifier {
  FoldersRepository._();

  static final FoldersRepository instance = FoldersRepository._();

  static const String seedFolderId = 'trip_to_malaysia';

  final List<Folder> _folders = [];
  bool _useInMemoryOnly = false;
  bool _isLoaded = false;

  List<Folder> get folders => List.unmodifiable(_folders);

  List<String> get folderNames => _folders.map((folder) => folder.name).toList();

  bool get isLoaded => _isLoaded;

  @visibleForTesting
  void configureForTesting({bool inMemoryOnly = true}) {
    _useInMemoryOnly = inMemoryOnly;
    resetToDefaults();
  }

  @visibleForTesting
  void resetToDefaults() {
    _folders.clear();
    _isLoaded = false;
    notifyListeners();
  }

  Future<void> load() async {
    if (_isLoaded) {
      return;
    }

    if (_useInMemoryOnly) {
      await _loadFromSeed();
      return;
    }

    try {
      if (HiveDatabase.foldersIsEmpty) {
        await _loadFromSeed();
        await _save();
      } else {
        await _loadFromHive();
      }
    } catch (error, stackTrace) {
      debugPrint('FoldersRepository.load failed: $error');
      debugPrint('$stackTrace');
      await _loadFromSeed();
      await _save();
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _loadFromHive() async {
    final box = HiveDatabase.foldersBox;
    _folders
      ..clear()
      ..addAll(
        box.keys.map(
          (key) => Folder.fromJson(
            Map<String, dynamic>.from(box.get(key)!),
          ),
        ),
      );
  }

  Future<void> _loadFromSeed() async {
    final seedData = await SeedDataLoader.load();
    _folders
      ..clear()
      ..addAll(seedData.folders);
    _isLoaded = true;
    notifyListeners();
  }

  Folder? folderById(String id) {
    for (final folder in _folders) {
      if (folder.id == id) {
        return folder;
      }
    }
    return null;
  }

  Folder? folderByName(String name) {
    for (final folder in _folders) {
      if (folder.name == name) {
        return folder;
      }
    }
    return null;
  }

  CategoryItem? itemById(String folderId, String itemId) {
    final folder = folderById(folderId);
    if (folder == null) {
      return null;
    }

    for (final item in folder.items) {
      if (item.id == itemId) {
        return item;
      }
    }
    return null;
  }

  Future<void> reorderFolders(int oldIndex, int newIndex) async {
    final folder = _folders.removeAt(oldIndex);
    _folders.insert(newIndex, folder);
    await _persist();
  }

  Future<void> setFolderHidden(String folderId, bool hidden) async {
    final index = _folderIndex(folderId);
    if (index == -1) {
      return;
    }

    _folders[index] = _folders[index].copyWith(isHidden: hidden);
    await _persist();
  }

  Future<void> setItemCardDirection(
    String folderId,
    String itemId,
    CardDisplayDirection direction,
  ) async {
    final folderIndex = _folderIndex(folderId);
    if (folderIndex == -1) {
      return;
    }

    final folder = _folders[folderIndex];
    final itemIndex = folder.items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) {
      return;
    }

    final updatedItems = [...folder.items];
    updatedItems[itemIndex] =
        updatedItems[itemIndex].copyWith(cardDisplayDirection: direction);
    _folders[folderIndex] = folder.copyWith(items: updatedItems);
    await _persist();
  }

  Future<void> updateFolderName(String folderId, String name) async {
    final index = _folderIndex(folderId);
    if (index == -1) {
      return;
    }

    _folders[index] = _folders[index].copyWith(name: name);
    await _persist();
  }

  Future<void> updateItemDetailDefinitions(
    String folderId,
    String itemId,
    List<CategoryDetailDefinition> definitions,
  ) async {
    final folderIndex = _folderIndex(folderId);
    if (folderIndex == -1) {
      return;
    }

    final folder = _folders[folderIndex];
    final itemIndex = folder.items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) {
      return;
    }

    final updatedItems = [...folder.items];
    updatedItems[itemIndex] = updatedItems[itemIndex].copyWith(
      detailDefinitions: definitions,
    );
    _folders[folderIndex] = folder.copyWith(items: updatedItems);
    await _persist();
  }

  Future<void> updateItemName(
    String folderId,
    String itemId,
    String name,
  ) async {
    final folderIndex = _folderIndex(folderId);
    if (folderIndex == -1) {
      return;
    }

    final folder = _folders[folderIndex];
    final itemIndex = folder.items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) {
      return;
    }

    final updatedItems = [...folder.items];
    updatedItems[itemIndex] = updatedItems[itemIndex].copyWith(name: name);
    _folders[folderIndex] = folder.copyWith(items: updatedItems);
    await _persist();
  }

  Future<void> deleteFolder(String folderId) async {
    await CardsRepository.instance.deleteCardsForFolder(folderId);
    _folders.removeWhere((folder) => folder.id == folderId);
    await _persist();
  }

  Future<void> deleteItem(String folderId, String itemId) async {
    await CardsRepository.instance.deleteCardsForCategory(folderId, itemId);

    final folderIndex = _folderIndex(folderId);
    if (folderIndex == -1) {
      return;
    }

    final folder = _folders[folderIndex];
    final updatedItems =
        folder.items.where((item) => item.id != itemId).toList();
    _folders[folderIndex] = folder.copyWith(items: updatedItems);
    await _persist();
  }

  Future<Folder> addFolder(String name) async {
    final folder = Folder(
      id: 'folder_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      items: const [],
    );
    _folders.add(folder);
    await _persist();
    return folder;
  }

  Future<CategoryItem?> addItem(String folderId, String itemName) async {
    final folderIndex = _folderIndex(folderId);
    if (folderIndex == -1) {
      return null;
    }

    final folder = _folders[folderIndex];
    final item = CategoryItem(
      id: 'item_${DateTime.now().microsecondsSinceEpoch}',
      name: itemName,
    );
    _folders[folderIndex] = folder.copyWith(items: [...folder.items, item]);
    await _persist();
    return item;
  }

  /// Merges [backupFolders] into local state.
  ///
  /// Device-only folders/categories are never removed. When [mode] is retain,
  /// overlapping categories keep the device version; when replace, they are
  /// overwritten from the backup. Backup-only folders/categories are always added.
  Future<void> mergeFromBackup(
    List<Folder> backupFolders, {
    required BackupMergeMode mode,
  }) async {
    for (final backupFolder in backupFolders) {
      final index = _folderIndex(backupFolder.id);
      if (index == -1) {
        _folders.add(backupFolder);
        continue;
      }

      final deviceFolder = _folders[index];
      final mergedItems = _mergeCategoryItems(
        deviceItems: deviceFolder.items,
        backupItems: backupFolder.items,
        mode: mode,
      );

      if (mode == BackupMergeMode.replace) {
        _folders[index] = deviceFolder.copyWith(
          name: backupFolder.name,
          isHidden: backupFolder.isHidden,
          items: mergedItems,
        );
      } else {
        _folders[index] = deviceFolder.copyWith(items: mergedItems);
      }
    }

    await _persist();
  }

  List<CategoryItem> _mergeCategoryItems({
    required List<CategoryItem> deviceItems,
    required List<CategoryItem> backupItems,
    required BackupMergeMode mode,
  }) {
    final byId = {for (final item in deviceItems) item.id: item};
    for (final backupItem in backupItems) {
      final existing = byId[backupItem.id];
      if (existing == null) {
        byId[backupItem.id] = backupItem;
        continue;
      }
      if (mode == BackupMergeMode.replace) {
        byId[backupItem.id] = backupItem;
      }
    }

    final result = <CategoryItem>[];
    final seen = <String>{};
    for (final item in deviceItems) {
      result.add(byId[item.id]!);
      seen.add(item.id);
    }
    for (final backupItem in backupItems) {
      if (seen.contains(backupItem.id)) continue;
      result.add(byId[backupItem.id]!);
    }
    return result;
  }

  int _folderIndex(String folderId) {
    return _folders.indexWhere((folder) => folder.id == folderId);
  }

  Future<void> _save() async {
    if (_useInMemoryOnly) {
      return;
    }

    final box = HiveDatabase.foldersBox;
    await box.clear();
    for (final folder in _folders) {
      await box.put(folder.id, folder.toJson());
    }
  }

  Future<void> _persist() async {
    await _save();
    notifyListeners();
  }
}
