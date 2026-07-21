import 'package:flutter/material.dart';

import '../models/choice_card.dart';
import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';
import '../theme/layout_constants.dart';
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

class FolderVerticalCardsView extends StatelessWidget {
  const FolderVerticalCardsView({
    super.key,
    required this.folderId,
    required this.sections,
  });

  final String folderId;
  final List<FolderCategoryCardsSection> sections;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        for (final section in sections) ...[
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
                  return ChoiceCardTile(card: card);
                },
              ),
            ),
        ],
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
