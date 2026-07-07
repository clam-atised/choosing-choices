enum DetailFieldType {
  text,
  yesNo,
  dropdown;

  static DetailFieldType fromJson(String value) {
    return DetailFieldType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => DetailFieldType.text,
    );
  }
}

class CardDetailField {
  const CardDetailField({
    required this.id,
    required this.label,
    required this.type,
    this.textValue,
    this.yesNoValue,
    this.dropdownValue,
    this.dropdownOptions = const [],
  });

  final String id;
  final String label;
  final DetailFieldType type;
  final String? textValue;
  final bool? yesNoValue;
  final String? dropdownValue;
  final List<String> dropdownOptions;

  CardDetailField copyWith({
    String? id,
    String? label,
    DetailFieldType? type,
    String? textValue,
    bool? yesNoValue,
    String? dropdownValue,
    List<String>? dropdownOptions,
  }) {
    return CardDetailField(
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      textValue: textValue ?? this.textValue,
      yesNoValue: yesNoValue ?? this.yesNoValue,
      dropdownValue: dropdownValue ?? this.dropdownValue,
      dropdownOptions: dropdownOptions ?? this.dropdownOptions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'type': type.name,
      'textValue': textValue,
      'yesNoValue': yesNoValue,
      'dropdownValue': dropdownValue,
      'dropdownOptions': dropdownOptions,
    };
  }

  factory CardDetailField.fromJson(Map<String, dynamic> json) {
    final optionsJson = json['dropdownOptions'] as List<dynamic>? ?? [];
    return CardDetailField(
      id: json['id'] as String,
      label: json['label'] as String,
      type: DetailFieldType.fromJson(json['type'] as String),
      textValue: json['textValue'] as String?,
      yesNoValue: json['yesNoValue'] as bool?,
      dropdownValue: json['dropdownValue'] as String?,
      dropdownOptions: optionsJson.map((option) => option as String).toList(),
    );
  }
}

class ChoiceCard {
  const ChoiceCard({
    required this.id,
    required this.folderId,
    required this.categoryItemId,
    required this.title,
    this.details = const [],
    this.imagePath,
  });

  final String id;
  final String folderId;
  final String categoryItemId;
  final String title;
  final List<CardDetailField> details;
  final String? imagePath;

  ChoiceCard copyWith({
    String? id,
    String? folderId,
    String? categoryItemId,
    String? title,
    List<CardDetailField>? details,
    String? imagePath,
  }) {
    return ChoiceCard(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      categoryItemId: categoryItemId ?? this.categoryItemId,
      title: title ?? this.title,
      details: details ?? this.details,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'folderId': folderId,
      'categoryItemId': categoryItemId,
      'title': title,
      'details': details.map((detail) => detail.toJson()).toList(),
      'imagePath': imagePath,
    };
  }

  factory ChoiceCard.fromJson(Map<String, dynamic> json) {
    final detailsJson = json['details'] as List<dynamic>? ?? [];
    return ChoiceCard(
      id: json['id'] as String,
      folderId: json['folderId'] as String,
      categoryItemId: json['categoryItemId'] as String,
      title: json['title'] as String,
      details: detailsJson
          .map((detail) => CardDetailField.fromJson(detail as Map<String, dynamic>))
          .toList(),
      imagePath: json['imagePath'] as String?,
    );
  }
}
