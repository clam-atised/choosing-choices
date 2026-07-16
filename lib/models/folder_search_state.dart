class FolderSearchState {
  const FolderSearchState({
    this.folderQuery,
    this.selectedCategoryId,
    this.detailQueries = const {},
  });

  final String? folderQuery;
  final String? selectedCategoryId;
  final Map<String, String> detailQueries;

  bool get isDetailSearchActive =>
      detailQueries.values.any((value) => value.trim().isNotEmpty);

  bool get isFolderWideActive =>
      !isDetailSearchActive && (folderQuery?.trim().isNotEmpty ?? false);

  bool get isActive => isDetailSearchActive || isFolderWideActive;

  FolderSearchState copyWith({
    String? folderQuery,
    String? selectedCategoryId,
    Map<String, String>? detailQueries,
    bool clearFolderQuery = false,
    bool clearSelectedCategoryId = false,
    bool clearDetailQueries = false,
  }) {
    return FolderSearchState(
      folderQuery: clearFolderQuery ? null : (folderQuery ?? this.folderQuery),
      selectedCategoryId: clearSelectedCategoryId
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      detailQueries:
          clearDetailQueries ? const {} : (detailQueries ?? this.detailQueries),
    );
  }

  static const FolderSearchState empty = FolderSearchState();
}
