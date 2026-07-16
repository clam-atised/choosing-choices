import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'hive_boxes.dart';

/// Local Hive NoSQL store for folders and cards.
abstract final class HiveDatabase {
  static Box<Map>? _foldersBox;
  static Box<Map>? _cardsBox;
  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Box<Map> get foldersBox {
    final box = _foldersBox;
    if (box == null || !box.isOpen) {
      throw StateError('HiveDatabase not initialized. Call init() first.');
    }
    return box;
  }

  static Box<Map> get cardsBox {
    final box = _cardsBox;
    if (box == null || !box.isOpen) {
      throw StateError('HiveDatabase not initialized. Call init() first.');
    }
    return box;
  }

  static Future<void> init() async {
    if (_initialized) {
      return;
    }

    await Hive.initFlutter();
    _foldersBox = await Hive.openBox<Map>(HiveBoxes.folders);
    _cardsBox = await Hive.openBox<Map>(HiveBoxes.cards);
    _initialized = true;
  }

  @visibleForTesting
  static Future<void> initForTesting({String? path}) async {
    await close();
    if (path != null) {
      Hive.init(path);
    } else {
      Hive.init('./.hive_test');
    }
    _foldersBox = await Hive.openBox<Map>(HiveBoxes.folders);
    _cardsBox = await Hive.openBox<Map>(HiveBoxes.cards);
    _initialized = true;
  }

  static bool get foldersIsEmpty => foldersBox.isEmpty;

  static bool get cardsIsEmpty => cardsBox.isEmpty;

  static Future<void> clearAll() async {
    if (!_initialized) {
      return;
    }
    await foldersBox.clear();
    await cardsBox.clear();
  }

  static Future<void> close() async {
    if (_foldersBox?.isOpen ?? false) {
      await _foldersBox!.close();
    }
    if (_cardsBox?.isOpen ?? false) {
      await _cardsBox!.close();
    }
    _foldersBox = null;
    _cardsBox = null;
    _initialized = false;
  }
}
