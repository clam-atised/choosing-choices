import 'choice_card.dart';

class CategoryDetailDefinition {
  const CategoryDetailDefinition({
    required this.id,
    required this.label,
    required this.type,
    this.dropdownOptions = const [],
  });

  final String id;
  final String label;
  final DetailFieldType type;
  final List<String> dropdownOptions;

  CategoryDetailDefinition copyWith({
    String? id,
    String? label,
    DetailFieldType? type,
    List<String>? dropdownOptions,
  }) {
    return CategoryDetailDefinition(
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      dropdownOptions: dropdownOptions ?? this.dropdownOptions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'type': type.name,
      'dropdownOptions': dropdownOptions,
    };
  }

  factory CategoryDetailDefinition.fromJson(Map<String, dynamic> json) {
    final optionsJson = json['dropdownOptions'] as List<dynamic>? ?? [];
    return CategoryDetailDefinition(
      id: json['id'] as String,
      label: json['label'] as String,
      type: DetailFieldType.fromJson(json['type'] as String),
      dropdownOptions: optionsJson.map((option) => option as String).toList(),
    );
  }

  factory CategoryDetailDefinition.fromCardDetail(CardDetailField detail) {
    return CategoryDetailDefinition(
      id: detail.id,
      label: detail.label,
      type: detail.type,
      dropdownOptions: [...detail.dropdownOptions],
    );
  }

  CardDetailField toEmptyCardDetail() {
    return CardDetailField(
      id: id,
      label: label,
      type: type,
      yesNoValue: type == DetailFieldType.yesNo ? false : null,
      dropdownOptions: [...dropdownOptions],
      dropdownValue: dropdownOptions.isNotEmpty ? dropdownOptions.first : null,
      weekDays: type == DetailFieldType.days
          ? List<bool>.filled(7, false)
          : const [],
    );
  }
}
