import 'package:flutter/material.dart';

import '../data/cards_repository.dart';
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
  });

  final String folderId;
  final String categoryItemId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CardsRepository.instance,
      builder: (context, _) {
        final cards = CardsRepository.instance.cardsForCategory(
          folderId,
          categoryItemId,
        );

        if (cards.isEmpty) {
          return const _EmptyCardCarousel();
        }

        return _CardPageView(
          folderId: folderId,
          categoryItemId: categoryItemId,
          cards: cards,
        );
      },
    );
  }
}

class _CardPageView extends StatefulWidget {
  const _CardPageView({
    required this.folderId,
    required this.categoryItemId,
    required this.cards,
  });

  final String folderId;
  final String categoryItemId;
  final List<ChoiceCard> cards;

  @override
  State<_CardPageView> createState() => _CardPageViewState();
}

class _CardPageViewState extends State<_CardPageView> {
  late final PageController _pageController;
  String? _selectedCardId;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1);
  }

  @override
  void didUpdateWidget(covariant _CardPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedCardId != null &&
        !widget.cards.any((card) => card.id == _selectedCardId)) {
      setState(() => _selectedCardId = null);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
      itemId: widget.categoryItemId,
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            PageView.builder(
              controller: _pageController,
              padEnds: false,
              itemCount: widget.cards.length,
              itemBuilder: (context, index) {
                final card = widget.cards[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kCardHorizontalPadding,
                  ),
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: ChoiceCardTile(
                      card: card,
                      onLongPress: () => _onCardLongPress(card),
                    ),
                  ),
                );
              },
            ),
            if (_selectedCardId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
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
              icon: const Icon(Icons.edit_outlined, color: AppColours.dark),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: 'Delete card',
              icon: const Icon(Icons.delete_outline, color: AppColours.dark),
              onPressed: onDelete,
            ),
            IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close, color: AppColours.dark),
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCardCarousel extends StatelessWidget {
  const _EmptyCardCarousel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kCardHorizontalPadding),
      child: Row(
        children: const [
          Expanded(child: _PlaceholderCard()),
          SizedBox(width: 12),
          Expanded(child: _PlaceholderCard()),
        ],
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColours.light,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
