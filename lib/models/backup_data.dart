import 'category_item.dart';
import 'choice_card.dart';

class BackupSettingsData {
  const BackupSettingsData({
    this.colourTemplateName,
  });

  final String? colourTemplateName;

  Map<String, dynamic> toJson() => {
        if (colourTemplateName != null) 'colourTemplateName': colourTemplateName,
      };

  factory BackupSettingsData.fromJson(Map<String, dynamic> json) {
    return BackupSettingsData(
      colourTemplateName: json['colourTemplateName'] as String?,
    );
  }
}

class BackupData {
  BackupData({
    this.version = currentVersion,
    required this.folders,
    required this.cards,
    this.settings = const BackupSettingsData(),
  });

  static const currentVersion = 1;
  static const backupJsonName = 'backup.json';

  final int version;
  final List<Folder> folders;
  final List<ChoiceCard> cards;
  final BackupSettingsData settings;

  Map<String, dynamic> toJson() => {
        'version': version,
        'folders': folders.map((folder) => folder.toJson()).toList(),
        'cards': cards.map((card) => card.toJson()).toList(),
        'settings': settings.toJson(),
      };

  factory BackupData.fromJson(Map<String, dynamic> json) {
    final version = json['version'] as int? ?? 1;
    if (version != currentVersion) {
      throw FormatException('Unsupported backup version: $version');
    }

    final foldersJson = json['folders'] as List<dynamic>? ?? [];
    final cardsJson = json['cards'] as List<dynamic>? ?? [];
    return BackupData(
      version: version,
      folders: foldersJson
          .map((e) => Folder.fromJson(e as Map<String, dynamic>))
          .toList(),
      cards: cardsJson
          .map((e) => ChoiceCard.fromJson(e as Map<String, dynamic>))
          .toList(),
      settings: BackupSettingsData.fromJson(
        json['settings'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}
