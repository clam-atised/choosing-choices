import 'category_detail_definition.dart';

enum CardDisplayDirection {
  horizontal,
  vertical;

  static CardDisplayDirection fromJson(String value) {
    return CardDisplayDirection.values.firstWhere(
      (direction) => direction.name == value,
      orElse: () => CardDisplayDirection.horizontal,
    );
  }
}

class CategoryItem {
  const CategoryItem({
    required this.id,
    required this.name,
    this.cardDisplayDirection = CardDisplayDirection.horizontal,
    this.detailDefinitions = const [],
  });

  final String id;
  final String name;
  final CardDisplayDirection cardDisplayDirection;
  final List<CategoryDetailDefinition> detailDefinitions;

  CategoryItem copyWith({
    String? id,
    String? name,
    CardDisplayDirection? cardDisplayDirection,
    List<CategoryDetailDefinition>? detailDefinitions,
  }) {
    return CategoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      cardDisplayDirection: cardDisplayDirection ?? this.cardDisplayDirection,
      detailDefinitions: detailDefinitions ?? this.detailDefinitions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cardDisplayDirection': cardDisplayDirection.name,
      'detailDefinitions':
          detailDefinitions.map((definition) => definition.toJson()).toList(),
    };
  }

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    final definitionsJson = json['detailDefinitions'] as List<dynamic>? ?? [];
    return CategoryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      cardDisplayDirection: CardDisplayDirection.fromJson(
        json['cardDisplayDirection'] as String? ?? 'horizontal',
      ),
      detailDefinitions: definitionsJson
          .map(
            (definition) => CategoryDetailDefinition.fromJson(
              definition as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}

class Folder {
  const Folder({
    required this.id,
    required this.name,
    required this.items,
    this.isHidden = false,
  });

  final String id;
  final String name;
  final List<CategoryItem> items;
  final bool isHidden;

  Folder copyWith({
    String? id,
    String? name,
    List<CategoryItem>? items,
    bool? isHidden,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
      isHidden: isHidden ?? this.isHidden,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isHidden': isHidden,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory Folder.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return Folder(
      id: json['id'] as String,
      name: json['name'] as String,
      isHidden: json['isHidden'] as bool? ?? false,
      items: itemsJson
          .map((item) => CategoryItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
