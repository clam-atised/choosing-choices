import 'package:flutter/material.dart';

import '../data/cards_repository.dart';
import '../models/category_item.dart';
import '../models/choice_card.dart';
import '../theme/app_colours.dart';
import '../theme/layout_constants.dart';
import 'add_card_dialog.dart';
import 'choice_card_tile.dart';

class CategoryCardCarousel extends StatelessWidget {
  const CategoryCardCarousel({
    super.key,
    required this.folderId,
    required this.categoryItemId,
    required this.displayDirection,
    this.filteredCards,
  });

  final String folderId;
  final String categoryItemId;
  final CardDisplayDirection displayDirection;
  final List<ChoiceCard>? filteredCards;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CardsRepository.instance,
      builder: (context, _) {
        final cards = filteredCards ??
            CardsRepository.instance.cardsForCategory(
              folderId,
              categoryItemId,
            );

        if (cards.isEmpty) {
          return const SizedBox.shrink();
        }

        return _CardCollectionView(
          folderId: folderId,
          categoryItemId: categoryItemId,
          cards: cards,
          displayDirection: displayDirection,
        );
      },
    );
  }
}

class _CardCollectionView extends StatefulWidget {
  const _CardCollectionView({
    required this.folderId,
    required this.categoryItemId,
    required this.cards,
    required this.displayDirection,
  });

  final String folderId;
  final String categoryItemId;
  final List<ChoiceCard> cards;
  final CardDisplayDirection displayDirection;

  @override
  State<_CardCollectionView> createState() => _CardCollectionViewState();
}

class _CardCollectionViewState extends State<_CardCollectionView> {
  String? _selectedCardId;

  @override
  void didUpdateWidget(covariant _CardCollectionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedCardId != null &&
        !widget.cards.any((card) => card.id == _selectedCardId)) {
      setState(() => _selectedCardId = null);
    }
  }

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

  Widget _buildCardTile(ChoiceCard card) {
    return ChoiceCardTile(
      card: card,
      onLongPress: () => _onCardLongPress(card),
    );
  }

  Widget _buildPhoneCarousel(double cardWidth) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: kCardHorizontalPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < widget.cards.length; index++) ...[
            if (index > 0) const SizedBox(width: 16),
            SizedBox(
              width: cardWidth,
              child: _buildCardTile(widget.cards[index]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWideScrollView() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: kCardHorizontalPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < widget.cards.length; index++) ...[
            if (index > 0) const SizedBox(width: 16),
            SizedBox(
              width: kDesktopCardWidth,
              child: _buildCardTile(widget.cards[index]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerticalScrollView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kCardHorizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < widget.cards.length; index++) ...[
            if (index > 0) const SizedBox(height: 12),
            _buildCardTile(widget.cards[index]),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useVertical = widget.displayDirection == CardDisplayDirection.vertical;
        final useCarousel = !useVertical && isPhoneSize(context);
        final phoneCardWidth = cardPageWidth(context);

        return Stack(
          alignment: Alignment.topCenter,
          children: [
            if (useVertical)
              _buildVerticalScrollView()
            else if (useCarousel)
              _buildPhoneCarousel(phoneCardWidth)
            else
              _buildWideScrollView(),
            if (_selectedCardId != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: Center(
                  child: _CardActionBar(
                    onEdit: () {
                      final card = widget.cards.firstWhere(
                        (entry) => entry.id == _selectedCardId,
                      );
                      _editCard(card);
                    },
                    onDelete: () {
                      final card = widget.cards.firstWhere(
                        (entry) => entry.id == _selectedCardId,
                      );
                      _confirmDeleteCard(card);
                    },
                    onDismiss: _clearSelection,
                  ),
                ),
              ),
          ],
        );
      },
    );
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
