import 'package:flutter/material.dart';

import '../data/cards_repository.dart';
import '../models/category_item.dart';
import '../models/choice_card.dart';
import '../theme/layout_constants.dart';
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
          cards: cards,
          displayDirection: displayDirection,
        );
      },
    );
  }
}

class _CardCollectionView extends StatelessWidget {
  const _CardCollectionView({
    required this.cards,
    required this.displayDirection,
  });

  final List<ChoiceCard> cards;
  final CardDisplayDirection displayDirection;

  Widget _buildCardTile(ChoiceCard card) {
    return ChoiceCardTile(card: card);
  }

  Widget _buildPhoneCarousel(double cardWidth) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: kCardHorizontalPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < cards.length; index++) ...[
            if (index > 0) const SizedBox(width: 16),
            SizedBox(
              width: cardWidth,
              child: _buildCardTile(cards[index]),
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
          for (var index = 0; index < cards.length; index++) ...[
            if (index > 0) const SizedBox(width: 16),
            SizedBox(
              width: kDesktopCardWidth,
              child: _buildCardTile(cards[index]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerticalScrollView(BoxConstraints constraints) {
    if (!constraints.maxHeight.isFinite) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: kCardHorizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < cards.length; index++) ...[
              if (index > 0) const SizedBox(height: 12),
              _buildCardTile(cards[index]),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      primary: false,
      padding: const EdgeInsets.symmetric(horizontal: kCardHorizontalPadding),
      itemCount: cards.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildCardTile(cards[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useVertical = displayDirection == CardDisplayDirection.vertical;
        final useCarousel = !useVertical && isPhoneSize(context);
        final phoneCardWidth = cardPageWidth(context);

        if (useVertical) {
          return _buildVerticalScrollView(constraints);
        }
        if (useCarousel) {
          return _buildPhoneCarousel(phoneCardWidth);
        }
        return _buildWideScrollView();
      },
    );
  }
}
