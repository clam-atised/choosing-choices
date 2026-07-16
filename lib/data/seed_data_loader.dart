import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/category_detail_definition.dart';
import '../models/category_item.dart';
import '../models/choice_card.dart';

class SeedData {
  const SeedData({
    required this.folders,
    required this.cards,
  });

  final List<Folder> folders;
  final List<ChoiceCard> cards;
}

class SeedDataLoader {
  SeedDataLoader._();

  static const String assetPath = 'assets/seed/initial_data.json';

  static const Map<String, List<CategoryDetailDefinition>> _seedSchemas = {
    'places_to_visit': [
      CategoryDetailDefinition(
        id: 'places_location',
        label: 'Location',
        type: DetailFieldType.text,
      ),
      CategoryDetailDefinition(
        id: 'places_accessible_by_train',
        label: 'Accessible by train',
        type: DetailFieldType.yesNo,
      ),
      CategoryDetailDefinition(
        id: 'places_description',
        label: 'Description',
        type: DetailFieldType.text,
      ),
    ],
    'restaurant_recommendations': [
      CategoryDetailDefinition(
        id: 'restaurants_cuisine',
        label: 'Type of Cuisine',
        type: DetailFieldType.text,
      ),
      CategoryDetailDefinition(
        id: 'restaurants_location',
        label: 'Location',
        type: DetailFieldType.text,
      ),
    ],
    'activities': [
      CategoryDetailDefinition(
        id: 'activities_charge',
        label: 'Charge',
        type: DetailFieldType.text,
      ),
    ],
  };

  static Future<SeedData> load() async {
    final jsonString = await rootBundle.loadString(assetPath);
    final data = json.decode(jsonString) as Map<String, dynamic>;
    return _parseSeedData(data);
  }

  static SeedData parseJsonString(String jsonString) {
    final data = json.decode(jsonString) as Map<String, dynamic>;
    return _parseSeedData(data);
  }

  static SeedData _parseSeedData(Map<String, dynamic> data) {
    final foldersJson = data['folders'] as List<dynamic>? ?? [];
    final folders = <Folder>[];
    final cards = <ChoiceCard>[];

    for (final folderEntry in foldersJson) {
      final folderMap = folderEntry as Map<String, dynamic>;
      final folderId = folderMap['id'] as String;
      final itemsJson = folderMap['items'] as List<dynamic>? ?? [];
      final items = <CategoryItem>[];

      for (final itemEntry in itemsJson) {
        final itemMap = itemEntry as Map<String, dynamic>;
        final itemId = itemMap['id'] as String;
        items.add(
          CategoryItem(
            id: itemId,
            name: itemMap['name'] as String,
            detailDefinitions: _seedSchemas[itemId] ?? const [],
          ),
        );

        final cardsJson = itemMap['cards'] as List<dynamic>? ?? [];
        for (final cardEntry in cardsJson) {
          final cardMap = cardEntry as Map<String, dynamic>;
          cards.add(
            _parseCard(
              cardMap: cardMap,
              folderId: folderId,
              itemId: itemId,
            ),
          );
        }
      }

      folders.add(
        Folder(
          id: folderId,
          name: folderMap['name'] as String,
          items: items,
        ),
      );
    }

    return SeedData(folders: folders, cards: cards);
  }

  static ChoiceCard _parseCard({
    required Map<String, dynamic> cardMap,
    required String folderId,
    required String itemId,
  }) {
    final cardId = cardMap['id'] as String;
    final details = <CardDetailField>[];
    var detailIndex = 0;

    void addTextDetail(String label, String? value) {
      if (value == null || value.isEmpty) {
        return;
      }
      details.add(
        CardDetailField(
          id: '${cardId}_detail_$detailIndex',
          label: label,
          type: DetailFieldType.text,
          textValue: value,
        ),
      );
      detailIndex++;
    }

    void addYesNoDetail(String label, bool? value) {
      if (value == null) {
        return;
      }
      details.add(
        CardDetailField(
          id: '${cardId}_detail_$detailIndex',
          label: label,
          type: DetailFieldType.yesNo,
          yesNoValue: value,
        ),
      );
      detailIndex++;
    }

    addTextDetail('Location', cardMap['location'] as String?);
    addYesNoDetail(
      'Accessible by train',
      cardMap['accessibleByTrain'] as bool?,
    );
    addTextDetail('Description', cardMap['description'] as String?);
    addTextDetail('Type of Cuisine', cardMap['typeOfCuisine'] as String?);
    addTextDetail('Charge', cardMap['charge'] as String?);

    return ChoiceCard(
      id: cardId,
      folderId: folderId,
      categoryItemId: itemId,
      title: cardMap['name'] as String,
      details: details,
      imagePath: cardMap['image'] as String?,
    );
  }
}
