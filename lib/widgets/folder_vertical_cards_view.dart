import 'package:flutter/material.dart';

import '../data/cards_repository.dart';
import '../models/choice_card.dart';
import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';
import '../theme/layout_constants.dart';
import 'add_card_dialog.dart';
import 'choice_card_tile.dart';

class FolderCategoryCardsSection {
  const FolderCategoryCardsSection({
    required this.categoryId,
    required this.categoryName,
    required this.cards,
  });

  final String categoryId;
  final String categoryName;
  final List<ChoiceCard> cards;
}

class FolderVerticalCardsView extends StatefulWidget {
  const FolderVerticalCardsView({
    super.key,
    required this.folderId,
    required this.sections,
  });

  final String folderId;
  final List<FolderCategoryCardsSection> sections;

  @override
  State<FolderVerticalCardsView> createState() =>
      _FolderVerticalCardsViewState();
}

class _FolderVerticalCardsViewState extends State<FolderVerticalCardsView> {
  String? _selectedCardId;

  void _onCardLongPress(ChoiceCard card) {
    setState(() => _selectedCardId = card.id);
  }

  void _clearSelection() {
    setState(() => _selectedCardId = null);
  }

  Future<void> _editCard(ChoiceCard card) async {
    await showAddCardDialog(
      context,
      folderId: widget.folderId,
      existingCard: card,
    );
    if (mounted) {
      _clearSelection();
    }
  }

  Future<void> _confirmDeleteCard(ChoiceCard card) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete card?', style: Theme.of(context).textTheme.titleLarge),
          content: const Text('Are you sure you want to delete this card?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    await CardsRepository.instance.deleteCard(card.id);
    if (mounted) {
      _clearSelection();
    }
  }

  ChoiceCard? get _selectedCard {
    if (_selectedCardId == null) {
      return null;
    }
    for (final section in widget.sections) {
      for (final card in section.cards) {
        if (card.id == _selectedCardId) {
          return card;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selectedCard = _selectedCard;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CustomScrollView(
          slivers: [
            for (final section in widget.sections) ...[
              SliverPersistentHeader(
                pinned: true,
                delegate: _CategoryHeaderDelegate(name: section.categoryName),
              ),
              if (section.cards.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      kCardHorizontalPadding,
                      8,
                      kCardHorizontalPadding,
                      16,
                    ),
                    child: Text('No matching cards'),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    kCardHorizontalPadding,
                    8,
                    kCardHorizontalPadding,
                    16,
                  ),
                  sliver: SliverList.separated(
                    itemCount: section.cards.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final card = section.cards[index];
                      return ChoiceCardTile(
                        card: card,
                        onLongPress: () => _onCardLongPress(card),
                      );
                    },
                  ),
                ),
            ],
          ],
        ),
        if (selectedCard != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _CardActionBar(
              onEdit: () => _editCard(selectedCard),
              onDelete: () => _confirmDeleteCard(selectedCard),
              onDismiss: _clearSelection,
            ),
          ),
      ],
    );
  }
}

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  _CategoryHeaderDelegate({required this.name});

  final String name;

  @override
  double get minExtent => 44;

  @override
  double get maxExtent => 44;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColours.dark,
      padding: const EdgeInsets.symmetric(horizontal: kCardHorizontalPadding),
      alignment: Alignment.centerLeft,
      child: Text(
        name,
        style: AppTextStyles.alice(
          fontSize: 20,
          color: AppColours.white,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CategoryHeaderDelegate oldDelegate) {
    return oldDelegate.name != name;
  }
}

class _CardActionBar extends StatelessWidget {
  const _CardActionBar({
    required this.onEdit,
    required this.onDelete,
    required this.onDismiss,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColours.light,
      borderRadius: BorderRadius.circular(24),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Edit card',
              icon: Icon(Icons.edit_outlined, color: AppColours.dark),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: 'Delete card',
              icon: Icon(Icons.delete_outline, color: AppColours.dark),
              onPressed: onDelete,
            ),
            IconButton(
              tooltip: 'Close',
              icon: Icon(Icons.close, color: AppColours.dark),
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
