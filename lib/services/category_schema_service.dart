import '../data/cards_repository.dart';
import '../data/folders_repository.dart';
import '../models/category_detail_definition.dart';
import '../models/choice_card.dart';

class CategorySchemaService {
  CategorySchemaService._();

  static final CategorySchemaService instance = CategorySchemaService._();

  bool isCategorySetupMode(String folderId, String categoryId) {
    final item = FoldersRepository.instance.itemById(folderId, categoryId);
    if (item?.detailDefinitions.isNotEmpty == true) {
      return false;
    }
    return CardsRepository.instance
        .cardsForCategory(folderId, categoryId)
        .isEmpty;
  }

  List<CategoryDetailDefinition> deriveDefinitionsFromCard(ChoiceCard card) {
    return [
      for (final detail in card.details)
        if (detail.label.trim().isNotEmpty)
          CategoryDetailDefinition.fromCardDetail(detail),
    ];
  }

  List<CardDetailField> emptyDetailsFromDefinitions(
    List<CategoryDetailDefinition> definitions,
  ) {
    return definitions.map((definition) => definition.toEmptyCardDetail()).toList();
  }

  /// Align card details to schema order: known fields by id, missing fields
  /// filled empty, orphan card-only fields appended.
  ChoiceCard syncCardDetailsToSchema(
    ChoiceCard card,
    List<CategoryDetailDefinition> definitions,
  ) {
    final byId = <String, CardDetailField>{
      for (final detail in card.details) detail.id: detail,
    };
    final ordered = <CardDetailField>[];

    for (final definition in definitions) {
      final existing = byId.remove(definition.id);
      if (existing != null) {
        final labeled = existing.copyWith(label: definition.label);
        if (definition.type == DetailFieldType.dropdown) {
          ordered.add(
            _withDropdownOptions(labeled, definition.dropdownOptions),
          );
        } else {
          ordered.add(labeled);
        }
      } else {
        ordered.add(definition.toEmptyCardDetail());
      }
    }

    ordered.addAll(byId.values);
    return card.copyWith(details: ordered);
  }

  List<CategoryDetailDefinition> mergeDropdownOptions({
    required List<CategoryDetailDefinition> definitions,
    required List<CardDetailField> details,
  }) {
    return [
      for (final definition in definitions)
        _mergeDefinitionOptions(definition, details),
    ];
  }

  CategoryDetailDefinition _mergeDefinitionOptions(
    CategoryDetailDefinition definition,
    List<CardDetailField> details,
  ) {
    if (definition.type != DetailFieldType.dropdown) {
      return definition;
    }

    CardDetailField? matchingDetail;
    for (final detail in details) {
      if (detail.id == definition.id) {
        matchingDetail = detail;
        break;
      }
    }
    if (matchingDetail == null) {
      return definition;
    }

    final mergedOptions = <String>{
      ...definition.dropdownOptions,
      ...matchingDetail.dropdownOptions,
      if (matchingDetail.dropdownValue != null &&
          matchingDetail.dropdownValue!.isNotEmpty)
        matchingDetail.dropdownValue!,
    };
    return definition.copyWith(dropdownOptions: mergedOptions.toList()..sort());
  }

  Future<List<CategoryDetailDefinition>> ensureSchemaForCategory({
    required String folderId,
    required String categoryId,
  }) async {
    final item = FoldersRepository.instance.itemById(folderId, categoryId);
    if (item == null) {
      return const [];
    }

    if (item.detailDefinitions.isNotEmpty) {
      return item.detailDefinitions;
    }

    final cards = CardsRepository.instance.cardsForCategory(folderId, categoryId);
    if (cards.isEmpty) {
      return const [];
    }

    final definitions = deriveDefinitionsFromCard(cards.first);
    await FoldersRepository.instance.updateItemDetailDefinitions(
      folderId,
      categoryId,
      definitions,
    );
    return definitions;
  }

  Future<void> _persistSchemaAndSyncCards({
    required String folderId,
    required String itemId,
    required List<CategoryDetailDefinition> definitions,
    required ChoiceCard Function(ChoiceCard card) mapCard,
  }) async {
    await FoldersRepository.instance.updateItemDetailDefinitions(
      folderId,
      itemId,
      definitions,
    );
    await CardsRepository.instance.updateCardsForCategory(
      folderId,
      itemId,
      mapCard,
    );
  }

  Future<void> reorderDefinitions({
    required String folderId,
    required String itemId,
    required List<CategoryDetailDefinition> definitions,
  }) async {
    await _persistSchemaAndSyncCards(
      folderId: folderId,
      itemId: itemId,
      definitions: definitions,
      mapCard: (card) => syncCardDetailsToSchema(card, definitions),
    );
  }

  Future<void> renameDefinition({
    required String folderId,
    required String itemId,
    required String definitionId,
    required String label,
  }) async {
    final item = FoldersRepository.instance.itemById(folderId, itemId);
    if (item == null) {
      return;
    }

    final definitions = [
      for (final definition in item.detailDefinitions)
        if (definition.id == definitionId)
          definition.copyWith(label: label)
        else
          definition,
    ];

    await _persistSchemaAndSyncCards(
      folderId: folderId,
      itemId: itemId,
      definitions: definitions,
      mapCard: (card) => card.copyWith(
        details: [
          for (final detail in card.details)
            if (detail.id == definitionId)
              detail.copyWith(label: label)
            else
              detail,
        ],
      ),
    );
  }

  Future<void> addDefinition({
    required String folderId,
    required String itemId,
    required CategoryDetailDefinition definition,
  }) async {
    final item = FoldersRepository.instance.itemById(folderId, itemId);
    if (item == null) {
      return;
    }

    final definitions = [...item.detailDefinitions, definition];
    final emptyDetail = definition.toEmptyCardDetail();

    await _persistSchemaAndSyncCards(
      folderId: folderId,
      itemId: itemId,
      definitions: definitions,
      mapCard: (card) {
        if (card.details.any((detail) => detail.id == definition.id)) {
          return card;
        }
        return card.copyWith(details: [...card.details, emptyDetail]);
      },
    );
  }

  Future<void> deleteDefinition({
    required String folderId,
    required String itemId,
    required String definitionId,
  }) async {
    final item = FoldersRepository.instance.itemById(folderId, itemId);
    if (item == null) {
      return;
    }

    final definitions = [
      for (final definition in item.detailDefinitions)
        if (definition.id != definitionId) definition,
    ];

    await _persistSchemaAndSyncCards(
      folderId: folderId,
      itemId: itemId,
      definitions: definitions,
      mapCard: (card) => card.copyWith(
        details: [
          for (final detail in card.details)
            if (detail.id != definitionId) detail,
        ],
      ),
    );
  }

  Future<void> setDropdownOptions({
    required String folderId,
    required String itemId,
    required String definitionId,
    required List<String> options,
  }) async {
    final item = FoldersRepository.instance.itemById(folderId, itemId);
    if (item == null) {
      return;
    }

    final definitions = [
      for (final definition in item.detailDefinitions)
        if (definition.id == definitionId)
          definition.copyWith(dropdownOptions: options)
        else
          definition,
    ];

    await _persistSchemaAndSyncCards(
      folderId: folderId,
      itemId: itemId,
      definitions: definitions,
      mapCard: (card) => card.copyWith(
        details: [
          for (final detail in card.details)
            if (detail.id == definitionId)
              _withDropdownOptions(detail, options)
            else
              detail,
        ],
      ),
    );
  }

  CardDetailField _withDropdownOptions(
    CardDetailField detail,
    List<String> options,
  ) {
    final keepValue = detail.dropdownValue != null &&
        options.contains(detail.dropdownValue);
    return CardDetailField(
      id: detail.id,
      label: detail.label,
      type: detail.type,
      textValue: detail.textValue,
      yesNoValue: detail.yesNoValue,
      dropdownValue: keepValue ? detail.dropdownValue : null,
      dropdownOptions: options,
      timeFrom: detail.timeFrom,
      timeTo: detail.timeTo,
      weekDays: detail.weekDays,
      dateFrom: detail.dateFrom,
      dateTo: detail.dateTo,
    );
  }
}
