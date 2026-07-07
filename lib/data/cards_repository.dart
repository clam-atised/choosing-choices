import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/choice_card.dart';
import '../platform/file_storage.dart';

class CardsRepository extends ChangeNotifier {
  CardsRepository._();

  static final CardsRepository instance = CardsRepository._();

  static const String _fileName = 'cards.json';

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
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> load() async {
    if (_isLoaded) {
      return;
    }

    if (_useInMemoryOnly || kIsWeb) {
      resetForTesting();
      return;
    }

    try {
      final path = await _storagePath();
      if (await fileExists(path)) {
        final contents = await readFileAsString(path);
        final data = json.decode(contents) as List<dynamic>;
        _cards
          ..clear()
          ..addAll(
            data.map(
              (entry) => ChoiceCard.fromJson(entry as Map<String, dynamic>),
            ),
          );
      }
    } catch (error, stackTrace) {
      debugPrint('CardsRepository.load failed: $error');
      debugPrint('$stackTrace');
      _cards.clear();
    }

    _isLoaded = true;
    notifyListeners();
  }

  List<ChoiceCard> cardsForCategory(String folderId, String itemId) {
    return _cards
        .where(
          (card) =>
              card.folderId == folderId && card.categoryItemId == itemId,
        )
        .toList();
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
    if (imagePath == null) {
      return;
    }

    await deleteFileIfExists(imagePath);
  }

  Future<String> _storagePath() => documentsFilePath(_fileName);

  Future<void> _save() async {
    if (_useInMemoryOnly || kIsWeb) {
      return;
    }

    final path = await _storagePath();
    final encoded = json.encode(_cards.map((card) => card.toJson()).toList());
    await writeFileAsString(path, encoded);
  }

  Future<void> _persist() async {
    await _save();
    notifyListeners();
  }
}
