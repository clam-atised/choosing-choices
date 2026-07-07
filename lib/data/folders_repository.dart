import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/category_item.dart';
import '../platform/file_storage.dart';
import 'cards_repository.dart';

class FoldersRepository extends ChangeNotifier {
  FoldersRepository._();

  static final FoldersRepository instance = FoldersRepository._();

  static const String _fileName = 'folders.json';

  final List<Folder> _folders = [];
  bool _useInMemoryOnly = false;
  bool _isLoaded = false;

  List<Folder> get folders => List.unmodifiable(_folders);

  List<String> get folderNames => _folders.map((folder) => folder.name).toList();

  bool get isLoaded => _isLoaded;

  static List<Folder> get defaultFolders => [
        const Folder(
          id: 'trip_to_japan',
          name: 'Trip to Japan',
          items: [
            CategoryItem(id: 'japan_eat', name: 'Where to eat'),
            CategoryItem(id: 'japan_stay', name: 'Where to stay'),
            CategoryItem(
              id: 'japan_places',
              name: 'Places to check out',
            ),
          ],
        ),
        const Folder(
          id: 'malaysia_eat',
          name: 'Where to eat in Malaysia',
          items: [
            CategoryItem(id: 'malaysia_state', name: 'State'),
            CategoryItem(id: 'malaysia_popular', name: 'Popular'),
            CategoryItem(id: 'malaysia_tbc', name: 'TBC'),
          ],
        ),
        const Folder(
          id: 'choice_of_unis',
          name: 'Choice of unis',
          items: [
            CategoryItem(id: 'unis_state', name: 'State'),
            CategoryItem(id: 'unis_utilities', name: 'Utilities'),
            CategoryItem(id: 'unis_tbc', name: 'TBC'),
          ],
        ),
      ];

  @visibleForTesting
  void configureForTesting({bool inMemoryOnly = true}) {
    _useInMemoryOnly = inMemoryOnly;
    resetToDefaults();
  }

  @visibleForTesting
  void resetToDefaults() {
    _folders
      ..clear()
      ..addAll(defaultFolders);
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> load() async {
    if (_isLoaded) {
      return;
    }

    if (_useInMemoryOnly || kIsWeb) {
      resetToDefaults();
      return;
    }

    try {
      final path = await _storagePath();
      if (await fileExists(path)) {
        final contents = await readFileAsString(path);
        final data = json.decode(contents) as List<dynamic>;
        _folders
          ..clear()
          ..addAll(
            data.map((entry) => Folder.fromJson(entry as Map<String, dynamic>)),
          );
      } else {
        _folders
          ..clear()
          ..addAll(defaultFolders);
        await _save();
      }
    } catch (error, stackTrace) {
      debugPrint('FoldersRepository.load failed: $error');
      debugPrint('$stackTrace');
      _folders
        ..clear()
        ..addAll(defaultFolders);
    }

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
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
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

  Future<void> addItem(String folderId, String itemName) async {
    final folderIndex = _folderIndex(folderId);
    if (folderIndex == -1) {
      return;
    }

    final folder = _folders[folderIndex];
    final item = CategoryItem(
      id: 'item_${DateTime.now().microsecondsSinceEpoch}',
      name: itemName,
    );
    _folders[folderIndex] = folder.copyWith(items: [...folder.items, item]);
    await _persist();
  }

  int _folderIndex(String folderId) {
    return _folders.indexWhere((folder) => folder.id == folderId);
  }

  Future<String> _storagePath() => documentsFilePath(_fileName);

  Future<void> _save() async {
    if (_useInMemoryOnly || kIsWeb) {
      return;
    }

    final path = await _storagePath();
    final encoded =
        json.encode(_folders.map((folder) => folder.toJson()).toList());
    await writeFileAsString(path, encoded);
  }

  Future<void> _persist() async {
    await _save();
    notifyListeners();
  }
}
