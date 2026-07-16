enum BackupMergeMode {
  retain,
  replace,
}

class BackupDiffEntry {
  const BackupDiffEntry({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

class BackupDiff {
  const BackupDiff({
    this.changedCategories = const [],
    this.changedCards = const [],
    this.addedFolders = const [],
    this.addedCategories = const [],
    this.addedCards = const [],
  });

  final List<BackupDiffEntry> changedCategories;
  final List<BackupDiffEntry> changedCards;
  final List<BackupDiffEntry> addedFolders;
  final List<BackupDiffEntry> addedCategories;
  final List<BackupDiffEntry> addedCards;

  bool get hasConflicts =>
      changedCategories.isNotEmpty || changedCards.isNotEmpty;

  bool get hasAdditions =>
      addedFolders.isNotEmpty ||
      addedCategories.isNotEmpty ||
      addedCards.isNotEmpty;

  bool get isEmpty => !hasConflicts && !hasAdditions;
}
