import 'package:flutter/foundation.dart';

import '../models/backup_diff.dart';
import '../models/choice_card.dart';
import '../platform/file_storage.dart';
import '../utils/card_date_utils.dart';
import 'hive/hive_database.dart';
import 'seed_data_loader.dart';

class CardsRepository extends ChangeNotifier {
  CardsRepository._();

  static final CardsRepository instance = CardsRepository._();

  final List<ChoiceCard> _cards = [];
  bool _useInMemoryOnly = false;
  bool _isLoaded = false;

  List<ChoiceCard> get cards => List.unmodifiable(_cards);

  bool get isLoaded => _isLoaded;

  @visibleForTesting
  void configureForTesting({bool inMemoryOnly = true}) {
    _useInMemoryOnly = inMemoryOnly;
    resetForTesting();
  }

  @visibleForTesting
  void resetForTesting() {
    _cards.clear();
    _isLoaded = false;
    notifyListeners();
  }

  @visibleForTesting
  void clearCardsForTesting() {
    _cards.clear();
    notifyListeners();
  }

  @visibleForTesting
  Future<void> loadSeedForTesting() async {
    await _loadFromSeed();
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
      if (HiveDatabase.cardsIsEmpty) {
        await _loadFromSeed();
        await _save();
      } else {
        await _loadFromHive();
      }
    } catch (error, stackTrace) {
      debugPrint('CardsRepository.load failed: $error');
      debugPrint('$stackTrace');
      await _loadFromSeed();
      await _save();
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _loadFromHive() async {
    final box = HiveDatabase.cardsBox;
    _cards
      ..clear()
      ..addAll(
        box.keys.map(
          (key) => ChoiceCard.fromJson(
            Map<String, dynamic>.from(box.get(key)!),
          ),
        ),
      );
  }

  Future<void> _loadFromSeed() async {
    final seedData = await SeedDataLoader.load();
    _cards
      ..clear()
      ..addAll(seedData.cards);
    _isLoaded = true;
    notifyListeners();
  }

  List<ChoiceCard> cardsForCategory(String folderId, String itemId) {
    final cards = _cards.where(
      (card) => card.folderId == folderId && card.categoryItemId == itemId,
    );
    return sortCardsByDateAndActivity(cards);
  }

  Future<void> setCardCompleted(
    String cardId, {
    required bool completed,
  }) async {
    final index = _cards.indexWhere((card) => card.id == cardId);
    if (index == -1) {
      return;
    }

    _cards[index] = _cards[index].copyWith(isStamped: completed);
    await _persist();
  }

  Future<ChoiceCard> addCard(ChoiceCard card) async {
    _cards.add(card);
    await _persist();
    return card;
  }

  Future<void> updateCard(ChoiceCard card) async {
    final index = _cards.indexWhere((existing) => existing.id == card.id);
    if (index == -1) {
      return;
    }

    _cards[index] = card;
    await _persist();
  }

  Future<void> updateCardsForCategory(
    String folderId,
    String itemId,
    ChoiceCard Function(ChoiceCard card) map,
  ) async {
    var changed = false;
    for (var i = 0; i < _cards.length; i++) {
      final card = _cards[i];
      if (card.folderId != folderId || card.categoryItemId != itemId) {
        continue;
      }
      final updated = map(card);
      if (!identical(updated, card)) {
        _cards[i] = updated;
        changed = true;
      }
    }
    if (changed) {
      await _persist();
    }
  }

  Future<void> deleteCard(String cardId) async {
    final index = _cards.indexWhere((card) => card.id == cardId);
    if (index == -1) {
      return;
    }

    final card = _cards.removeAt(index);
    await _deleteImageForCard(card);
    await _persist();
  }

  Future<void> deleteCardsForCategory(String folderId, String itemId) async {
    final removed = <ChoiceCard>[];
    _cards.removeWhere((card) {
      if (card.folderId == folderId && card.categoryItemId == itemId) {
        removed.add(card);
        return true;
      }
      return false;
    });

    await _deleteImagesForCards(removed);
    if (removed.isNotEmpty) {
      await _persist();
    }
  }

  Future<void> deleteCardsForFolder(String folderId) async {
    final removed = <ChoiceCard>[];
    _cards.removeWhere((card) {
      if (card.folderId == folderId) {
        removed.add(card);
        return true;
      }
      return false;
    });

    await _deleteImagesForCards(removed);
    if (removed.isNotEmpty) {
      await _persist();
    }
  }

  /// Merges [backupCards] into local state.
  ///
  /// Device-only cards are never removed. When [mode] is retain, overlapping
  /// cards keep the device version; when replace, they are overwritten from the
  /// backup (and old local images are deleted when replaced). Backup-only cards
  /// are always added.
  Future<void> mergeFromBackup(
    List<ChoiceCard> backupCards, {
    required BackupMergeMode mode,
  }) async {
    final byId = {for (final card in _cards) card.id: card};
    final imagesToDelete = <ChoiceCard>[];

    for (final backupCard in backupCards) {
      final existing = byId[backupCard.id];
      if (existing == null) {
        byId[backupCard.id] = backupCard;
        continue;
      }

      if (mode == BackupMergeMode.retain) {
        continue;
      }

      if (existing.imagePath != backupCard.imagePath) {
        imagesToDelete.add(existing);
      }
      byId[backupCard.id] = backupCard;
    }

    await _deleteImagesForCards(imagesToDelete);

    final result = <ChoiceCard>[];
    final seen = <String>{};
    for (final card in _cards) {
      result.add(byId[card.id]!);
      seen.add(card.id);
    }
    for (final backupCard in backupCards) {
      if (seen.contains(backupCard.id)) continue;
      result.add(byId[backupCard.id]!);
    }

    _cards
      ..clear()
      ..addAll(result);
    await _persist();
  }

  Future<void> _deleteImagesForCards(List<ChoiceCard> cards) async {
    if (_useInMemoryOnly || kIsWeb) {
      return;
    }

    for (final card in cards) {
      await _deleteImageForCard(card);
    }
  }

  Future<void> _deleteImageForCard(ChoiceCard card) async {
    final imagePath = card.imagePath;
    if (imagePath == null || imagePath.startsWith('assets/')) {
      return;
    }

    await deleteFileIfExists(imagePath);
  }

  Future<void> _save() async {
    if (_useInMemoryOnly) {
      return;
    }

    final box = HiveDatabase.cardsBox;
    await box.clear();
    for (final card in _cards) {
      await box.put(card.id, card.toJson());
    }
  }

  Future<void> _persist() async {
    await _save();
    notifyListeners();
  }
}
