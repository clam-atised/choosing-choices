enum DetailFieldType {
  text,
  yesNo,
  dropdown,
  time,
  days,
  date;

  static DetailFieldType fromJson(String value) {
    return DetailFieldType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => DetailFieldType.text,
    );
  }

  String get displayLabel {
    return switch (this) {
      DetailFieldType.text => 'Text',
      DetailFieldType.dropdown => 'Dropdown',
      DetailFieldType.yesNo => 'Yes/No',
      DetailFieldType.time => 'Time',
      DetailFieldType.days => 'Days',
      DetailFieldType.date => 'Date',
    };
  }

  static List<String> get displayLabels =>
      DetailFieldType.values.map((type) => type.displayLabel).toList();

  static DetailFieldType fromDisplayLabel(String label) {
    return DetailFieldType.values.firstWhere(
      (type) => type.displayLabel == label,
      orElse: () => DetailFieldType.text,
    );
  }
}

const List<String> kWeekDayLabels = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

class CardDetailField {
  const CardDetailField({
    required this.id,
    required this.label,
    required this.type,
    this.textValue,
    this.yesNoValue,
    this.dropdownValue,
    this.dropdownOptions = const [],
    this.timeFrom,
    this.timeTo,
    this.weekDays = const [],
    this.dateFrom,
    this.dateTo,
  });

  final String id;
  final String label;
  final DetailFieldType type;
  final String? textValue;
  final bool? yesNoValue;
  final String? dropdownValue;
  final List<String> dropdownOptions;
  final String? timeFrom;
  final String? timeTo;
  final List<bool> weekDays;
  final String? dateFrom;
  final String? dateTo;

  CardDetailField copyWith({
    String? id,
    String? label,
    DetailFieldType? type,
    String? textValue,
    bool? yesNoValue,
    String? dropdownValue,
    List<String>? dropdownOptions,
    String? timeFrom,
    String? timeTo,
    List<bool>? weekDays,
    String? dateFrom,
    String? dateTo,
    bool clearDates = false,
  }) {
    return CardDetailField(
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      textValue: textValue ?? this.textValue,
      yesNoValue: yesNoValue ?? this.yesNoValue,
      dropdownValue: dropdownValue ?? this.dropdownValue,
      dropdownOptions: dropdownOptions ?? this.dropdownOptions,
      timeFrom: timeFrom ?? this.timeFrom,
      timeTo: timeTo ?? this.timeTo,
      weekDays: weekDays ?? this.weekDays,
      dateFrom: clearDates ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDates ? null : (dateTo ?? this.dateTo),
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
      'timeFrom': timeFrom,
      'timeTo': timeTo,
      'weekDays': weekDays,
      'dateFrom': dateFrom,
      'dateTo': dateTo,
    };
  }

  factory CardDetailField.fromJson(Map<String, dynamic> json) {
    final optionsJson = json['dropdownOptions'] as List<dynamic>? ?? [];
    final weekDaysJson = json['weekDays'] as List<dynamic>? ?? [];
    return CardDetailField(
      id: json['id'] as String,
      label: json['label'] as String,
      type: DetailFieldType.fromJson(json['type'] as String),
      textValue: json['textValue'] as String?,
      yesNoValue: json['yesNoValue'] as bool?,
      dropdownValue: json['dropdownValue'] as String?,
      dropdownOptions: optionsJson.map((option) => option as String).toList(),
      timeFrom: json['timeFrom'] as String?,
      timeTo: json['timeTo'] as String?,
      weekDays: weekDaysJson.map((day) => day as bool).toList(),
      dateFrom: json['dateFrom'] as String?,
      dateTo: json['dateTo'] as String?,
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
    this.isStamped = false,
  });

  final String id;
  final String folderId;
  final String categoryItemId;
  final String title;
  final List<CardDetailField> details;
  final String? imagePath;
  final bool isStamped;

  ChoiceCard copyWith({
    String? id,
    String? folderId,
    String? categoryItemId,
    String? title,
    List<CardDetailField>? details,
    String? imagePath,
    bool? isStamped,
  }) {
    return ChoiceCard(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      categoryItemId: categoryItemId ?? this.categoryItemId,
      title: title ?? this.title,
      details: details ?? this.details,
      imagePath: imagePath ?? this.imagePath,
      isStamped: isStamped ?? this.isStamped,
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
      'isStamped': isStamped,
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
      isStamped: json['isStamped'] as bool? ?? false,
    );
  }
}
