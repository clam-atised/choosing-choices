import '../data/cards_repository.dart';
import '../data/folders_repository.dart';
import '../models/category_detail_definition.dart';
import '../models/choice_card.dart';
import '../utils/detail_field_formatters.dart';

class DetailSearchField {
  const DetailSearchField({
    required this.label,
    required this.type,
    this.options = const [],
  });

  final String label;
  final DetailFieldType type;
  final List<String> options;
}

class CardSearchService {
  CardSearchService._();

  static final CardSearchService instance = CardSearchService._();

  List<String> detailLabelsForCategory(String folderId, String categoryId) {
    return detailSearchFieldsForCategory(folderId, categoryId)
        .map((field) => field.label)
        .toList();
  }

  List<DetailSearchField> detailSearchFieldsForCategory(
    String folderId,
    String categoryId,
  ) {
    final cards = CardsRepository.instance.cardsForCategory(
      folderId,
      categoryId,
    );
    final item = FoldersRepository.instance.itemById(folderId, categoryId);

    final definitions = <CategoryDetailDefinition>[];
    if (item != null && item.detailDefinitions.isNotEmpty) {
      definitions.addAll(item.detailDefinitions);
    } else {
      definitions.addAll(_inferDefinitionsFromCards(cards));
    }

    final fields = <DetailSearchField>[];
    for (final definition in definitions) {
      final label = definition.label.trim();
      if (label.isEmpty) {
        continue;
      }

      final options = switch (definition.type) {
        DetailFieldType.text || DetailFieldType.dropdown =>
          _optionsForLabel(
            cards: cards,
            label: label,
            definition: definition,
          ),
        _ => const <String>[],
      };

      fields.add(
        DetailSearchField(
          label: label,
          type: definition.type,
          options: options,
        ),
      );
    }

    fields.sort((a, b) => a.label.compareTo(b.label));
    return fields;
  }

  List<CategoryDetailDefinition> _inferDefinitionsFromCards(
    List<ChoiceCard> cards,
  ) {
    final byLabel = <String, CategoryDetailDefinition>{};
    for (final card in cards) {
      for (final detail in card.details) {
        final label = detail.label.trim();
        if (label.isEmpty || byLabel.containsKey(label)) {
          continue;
        }
        byLabel[label] = CategoryDetailDefinition.fromCardDetail(detail);
      }
    }
    return byLabel.values.toList();
  }

  List<String> _optionsForLabel({
    required List<ChoiceCard> cards,
    required String label,
    required CategoryDetailDefinition definition,
  }) {
    final values = <String>{
      ...definition.dropdownOptions.where((option) => option.trim().isNotEmpty),
    };

    for (final card in cards) {
      final detail = _detailByLabel(card, label);
      if (detail == null) {
        continue;
      }
      final display = detailDisplayValue(detail).trim();
      if (display.isNotEmpty) {
        values.add(display);
      }
      for (final option in detail.dropdownOptions) {
        if (option.trim().isNotEmpty) {
          values.add(option.trim());
        }
      }
    }

    return values.toList()..sort();
  }

  bool matchesFolderWide(ChoiceCard card, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return true;
    }

    if (card.title.toLowerCase().contains(normalizedQuery)) {
      return true;
    }

    for (final detail in card.details) {
      if (detailDisplayValue(detail).toLowerCase().contains(normalizedQuery)) {
        return true;
      }
    }

    return false;
  }

  bool matchesDetailSearch(
    ChoiceCard card,
    Map<String, String> detailQueries,
  ) {
    for (final entry in detailQueries.entries) {
      final query = entry.value.trim();
      if (query.isEmpty) {
        continue;
      }

      final matchingDetail = _detailByLabel(card, entry.key);
      if (matchingDetail == null) {
        return false;
      }

      if (detailDisplayValue(matchingDetail).trim() != query) {
        return false;
      }
    }

    return true;
  }

  String detailDisplayValue(CardDetailField detail) {
    return detailFieldDisplayValue(detail);
  }

  CardDetailField? _detailByLabel(ChoiceCard card, String label) {
    final normalizedLabel = label.trim();
    for (final detail in card.details) {
      if (detail.label.trim() == normalizedLabel) {
        return detail;
      }
    }
    return null;
  }

  List<ChoiceCard> filterCardsForCategory({
    required String folderId,
    required String categoryId,
    required FolderSearchMode mode,
    String? folderQuery,
    Map<String, String> detailQueries = const {},
  }) {
    final cards = CardsRepository.instance.cardsForCategory(folderId, categoryId);

    return switch (mode) {
      FolderSearchMode.none => cards,
      FolderSearchMode.folderWide => cards
          .where((card) => matchesFolderWide(card, folderQuery ?? ''))
          .toList(),
      FolderSearchMode.detail => cards
          .where((card) => matchesDetailSearch(card, detailQueries))
          .toList(),
    };
  }
}

enum FolderSearchMode { none, folderWide, detail }
