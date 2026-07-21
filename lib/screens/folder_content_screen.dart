import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/cards_repository.dart';
import '../data/folders_repository.dart';
import '../models/category_item.dart';
import '../models/choice_card.dart';
import '../models/folder_search_state.dart';
import '../services/card_search_service.dart';
import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';
import '../theme/layout_constants.dart';
import '../widgets/add_card_dialog.dart';
import '../widgets/category_card_carousel.dart';
import '../widgets/choices_drawer.dart';
import '../widgets/create_actions_menu.dart';
import '../widgets/create_category_dialog.dart';
import '../widgets/create_folder_dialog.dart';
import '../widgets/folder_search_dialog.dart';
import '../widgets/folder_vertical_cards_view.dart';
import '../widgets/shared_app_bar.dart';

class FolderContentScreen extends StatefulWidget {
  const FolderContentScreen({
    super.key,
    required this.folderId,
  });

  final String folderId;

  @override
  State<FolderContentScreen> createState() => _FolderContentScreenState();
}

class _FolderContentScreenState extends State<FolderContentScreen> {
  final GlobalKey _addButtonKey = GlobalKey();
  final CardSearchService _searchService = CardSearchService.instance;

  final Set<String> _expandedItemIds = {};
  FolderSearchState? _searchState;

  String? get _primaryExpandedItemId =>
      _expandedItemIds.isEmpty ? null : _expandedItemIds.first;

  @override
  void initState() {
    super.initState();
    FoldersRepository.instance.addListener(_onFoldersChanged);
    _initExpandedItem();
  }

  void _initExpandedItem() {
    final folder = FoldersRepository.instance.folderById(widget.folderId);
    if (folder != null && folder.items.isNotEmpty) {
      _expandedItemIds.add(folder.items.first.id);
    }
  }

  @override
  void dispose() {
    FoldersRepository.instance.removeListener(_onFoldersChanged);
    super.dispose();
  }

  void _onFoldersChanged() {
    _syncExpandedItems();
  }

  void _syncExpandedItems() {
    final folder = FoldersRepository.instance.folderById(widget.folderId);
    if (folder == null) {
      return;
    }

    final validIds = folder.items.map((item) => item.id).toSet();
    final pruned = _expandedItemIds.intersection(validIds);
    if (pruned.length != _expandedItemIds.length) {
      setState(() {
        _expandedItemIds
          ..clear()
          ..addAll(pruned);
        if (_expandedItemIds.isEmpty && folder.items.isNotEmpty) {
          _expandedItemIds.add(folder.items.first.id);
        }
      });
    } else if (_expandedItemIds.isEmpty && folder.items.isNotEmpty) {
      setState(() => _expandedItemIds.add(folder.items.first.id));
    }
  }

  void _toggleExpanded(String itemId) {
    setState(() {
      if (_expandedItemIds.contains(itemId)) {
        _expandedItemIds.remove(itemId);
      } else {
        _expandedItemIds.add(itemId);
      }
    });
  }

  CardDisplayDirection _effectiveDirection(CategoryItem item) {
    if (_searchState?.isDetailSearchActive == true &&
        _searchState!.selectedCategoryId == item.id) {
      return CardDisplayDirection.vertical;
    }
    return item.cardDisplayDirection;
  }

  List<FolderCategoryCardsSection> _folderWideSections(Folder folder) {
    final query = _searchState?.folderQuery ?? '';
    return [
      for (final item in folder.items)
        FolderCategoryCardsSection(
          categoryId: item.id,
          categoryName: item.name,
          cards: _searchService.filterCardsForCategory(
            folderId: widget.folderId,
            categoryId: item.id,
            mode: FolderSearchMode.folderWide,
            folderQuery: query,
          ),
        ),
    ].where((section) => section.cards.isNotEmpty).toList();
  }

  List<ChoiceCard> _filteredCardsForItem(CategoryItem item) {
    final searchState = _searchState;
    if (searchState == null || !searchState.isActive) {
      return _searchService.filterCardsForCategory(
        folderId: widget.folderId,
        categoryId: item.id,
        mode: FolderSearchMode.none,
      );
    }

    if (searchState.isFolderWideActive) {
      return _searchService.filterCardsForCategory(
        folderId: widget.folderId,
        categoryId: item.id,
        mode: FolderSearchMode.folderWide,
        folderQuery: searchState.folderQuery,
      );
    }

    if (searchState.isDetailSearchActive &&
        searchState.selectedCategoryId == item.id) {
      return _searchService.filterCardsForCategory(
        folderId: widget.folderId,
        categoryId: item.id,
        mode: FolderSearchMode.detail,
        detailQueries: searchState.detailQueries,
      );
    }

    return _searchService.filterCardsForCategory(
      folderId: widget.folderId,
      categoryId: item.id,
      mode: FolderSearchMode.none,
    );
  }

  Future<void> _showCreateActionsMenu() async {
    final anchor = anchorOffsetForKey(_addButtonKey);
    if (anchor == null || !mounted) {
      return;
    }

    await showCreateActionsMenu(
      context,
      anchor: anchor,
      callbacks: CreateActionsCallbacks(
        onCreateFolder: _onCreateFolder,
        onCreateCategory: _onCreateCategory,
        onCreateCard: _onCreateCard,
      ),
    );
  }

  Future<void> _showSearchDialog() async {
    final result = await showFolderSearchDialog(
      context,
      folderId: widget.folderId,
      initialCategoryId: _primaryExpandedItemId,
      initialState: _searchState,
    );
    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _searchState = result.isActive ? result : null;
      if (result.isDetailSearchActive && result.selectedCategoryId != null) {
        _expandedItemIds.add(result.selectedCategoryId!);
      }
    });
  }

  void _onCreateFolder() {
    showCreateFolderDialog(context);
  }

  Future<void> _onCreateCategory() async {
    final result = await showCreateCategoryDialog(
      context,
      initialFolderId: widget.folderId,
    );
    if (!mounted || result == null) {
      return;
    }

    if (result.folderId == widget.folderId) {
      setState(() => _expandedItemIds.add(result.itemId));
      await showAddCardDialog(
        context,
        folderId: widget.folderId,
        initialItemId: result.itemId,
      );
    }
  }

  Future<void> _onCreateCard() async {
    final folder = FoldersRepository.instance.folderById(widget.folderId);
    if (folder == null || folder.items.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a category first to add a card.'),
        ),
      );
      return;
    }

    final initialItemId = _primaryExpandedItemId ?? folder.items.first.id;
    await showAddCardDialog(
      context,
      folderId: widget.folderId,
      initialItemId: initialItemId,
    );
  }

  Widget _buildBody(Folder folder) {
    if (_searchState?.isFolderWideActive == true) {
      final sections = _folderWideSections(folder);
      if (sections.isEmpty) {
        return const Center(
          child: Text(
            'No matching cards',
            style: TextStyle(color: AppColours.white),
          ),
        );
      }

      return FolderVerticalCardsView(
        folderId: widget.folderId,
        sections: sections,
      );
    }

    if (folder.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Press '+' to add new category",
              textAlign: TextAlign.center,
              style: AppTextStyles.alice(
                fontSize: 18,
                color: AppColours.light,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Created by clam.atised',
              textAlign: TextAlign.center,
              style: AppTextStyles.sourceSans(
                fontSize: 12,
                color: AppColours.light,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final verticalCardsHeight = math.max(
          0.0,
          constraints.maxHeight -
              (2 * _CategorySectionHeaderDelegate.extent),
        );

        return CustomScrollView(
          slivers: [
            for (final item in folder.items) ...[
              SliverPersistentHeader(
                pinned: true,
                delegate: _CategorySectionHeaderDelegate(
                  name: item.name,
                  isExpanded: _expandedItemIds.contains(item.id),
                  onToggle: () => _toggleExpanded(item.id),
                ),
              ),
              if (_expandedItemIds.contains(item.id))
                SliverToBoxAdapter(
                  child: _buildExpandedCarousel(
                    item: item,
                    verticalCardsHeight: verticalCardsHeight,
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildExpandedCarousel({
    required CategoryItem item,
    required double verticalCardsHeight,
  }) {
    final direction = _effectiveDirection(item);
    final carousel = CategoryCardCarousel(
      folderId: widget.folderId,
      categoryItemId: item.id,
      displayDirection: direction,
      filteredCards: _filteredCardsForItem(item),
    );

    if (direction == CardDisplayDirection.vertical) {
      return SizedBox(
        height: verticalCardsHeight,
        child: carousel,
      );
    }

    return carousel;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        FoldersRepository.instance,
        CardsRepository.instance,
        AppColours.instance,
      ]),
      builder: (context, _) {
        final folder = FoldersRepository.instance.folderById(widget.folderId);
        if (folder == null) {
          return const Scaffold(
            body: Center(child: Text('Folder not found')),
          );
        }

        return Scaffold(
          backgroundColor: AppColours.dark,
          drawer: const ChoicesDrawer(),
          appBar: SharedAppBar(
            title: folder.name,
            showSearchButton: true,
            showAddButton: true,
            addButtonKey: _addButtonKey,
            onSearchPressed: _showSearchDialog,
            onAddPressed: _showCreateActionsMenu,
          ),
          body: centerPhoneWidth(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
              child: _buildBody(folder),
            ),
          ),
        );
      },
    );
  }
}

class _CategorySectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  _CategorySectionHeaderDelegate({
    required this.name,
    required this.isExpanded,
    required this.onToggle,
  });

  final String name;
  final bool isExpanded;
  final VoidCallback onToggle;

  static const double extent = 44;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(
      height: extent,
      child: Material(
        color: AppColours.dark,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: kCardHorizontalPadding),
          child: Row(
            children: [
              GestureDetector(
                onTap: onToggle,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4, top: 4, bottom: 4),
                  child: Icon(
                    isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                    color: AppColours.white,
                    size: 28,
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: onToggle,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.alice(
                        fontSize: 20,
                        color: AppColours.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CategorySectionHeaderDelegate oldDelegate) {
    return oldDelegate.name != name ||
        oldDelegate.isExpanded != isExpanded ||
        oldDelegate.onToggle != onToggle;
  }
}
