import 'package:flutter/material.dart';
import 'package:flutter_confetti/flutter_confetti.dart';

import '../data/cards_repository.dart';
import '../models/choice_card.dart';
import '../platform/platform_image.dart';
import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';
import '../theme/layout_constants.dart';
import '../utils/card_date_utils.dart';
import '../utils/detail_field_formatters.dart';
import 'add_card_dialog.dart';
import 'card_delete.dart';
import 'card_title_header.dart';
import 'card_view_action_bar.dart';
import 'choices_dialog_shell.dart';

Future<void> showCardDetailDialog(
  BuildContext context, {
  required String folderId,
  required String categoryItemId,
  required String initialCardId,
}) {
  return showChoicesDialog<void>(
    context: context,
    scrollable: false,
    child: _CardDetailDialog(
      folderId: folderId,
      categoryItemId: categoryItemId,
      initialCardId: initialCardId,
    ),
  );
}

class _CardDetailDialog extends StatefulWidget {
  const _CardDetailDialog({
    required this.folderId,
    required this.categoryItemId,
    required this.initialCardId,
  });

  final String folderId;
  final String categoryItemId;
  final String initialCardId;

  @override
  State<_CardDetailDialog> createState() => _CardDetailDialogState();
}

class _CardDetailDialogState extends State<_CardDetailDialog> {
  late String _focusedCardId;

  @override
  void initState() {
    super.initState();
    _focusedCardId = widget.initialCardId;
  }

  List<ChoiceCard> _cardsForCategory() {
    return CardsRepository.instance.cardsForCategory(
      widget.folderId,
      widget.categoryItemId,
    );
  }

  int _indexForCard(List<ChoiceCard> cards, String cardId) {
    final index = cards.indexWhere((card) => card.id == cardId);
    if (index >= 0) {
      return index;
    }
    return 0;
  }

  void _showPrevious(List<ChoiceCard> cards, int currentIndex) {
    if (currentIndex <= 0 || cards.length <= 1) {
      return;
    }
    setState(() => _focusedCardId = cards[currentIndex - 1].id);
  }

  void _showNext(List<ChoiceCard> cards, int currentIndex) {
    if (cards.length <= 1) {
      return;
    }
    final nextIndex = currentIndex >= cards.length - 1 ? 0 : currentIndex + 1;
    setState(() => _focusedCardId = cards[nextIndex].id);
  }

  Future<void> _onTick(ChoiceCard card) async {
    if (isCardInactive(card)) {
      return;
    }

    await CardsRepository.instance.setCardCompleted(
      card.id,
      completed: true,
    );
    if (!mounted) {
      return;
    }

    Confetti.launch(
      context,
      options: ConfettiOptions(
        particleCount: 80,
        spread: 70,
        y: 0,
        angle: 90,
        startVelocity: 35,
        colors: [AppColours.dark, AppColours.light, AppColours.stamp],
      ),
    );
  }

  Future<void> _editCard(ChoiceCard card) async {
    await showAddCardDialog(
      context,
      folderId: widget.folderId,
      existingCard: card,
    );
  }

  Future<void> _deleteCard(ChoiceCard card, List<ChoiceCard> cards) async {
    final shouldDelete = await confirmDeleteCardForever(context);
    if (!shouldDelete || !mounted) {
      return;
    }

    final deletedIndex = cards.indexWhere((entry) => entry.id == card.id);
    await CardsRepository.instance.deleteCard(card.id);
    if (!mounted) {
      return;
    }

    final remainingCards = _cardsForCategory();
    if (remainingCards.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    final nextIndex = deletedIndex >= remainingCards.length
        ? remainingCards.length - 1
        : deletedIndex;
    setState(() => _focusedCardId = remainingCards[nextIndex].id);
  }

  Widget _buildCardBody(ChoiceCard card) {
    final inactive = isCardInactive(card);
    final hasPhoto = card.imagePath != null;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CardTitleHeader(
          title: card.title,
          showTick: !inactive,
          onTick: () => _onTick(card),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final detail in card.details)
                    if (normalizeDetailLabel(detail.label).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          formatDetailLine(detail),
                          style: AppTextStyles.sourceSans(fontSize: 14),
                        ),
                      ),
                ],
              ),
            ),
            if (hasPhoto)
              CollapsiblePlatformImage(
                path: card.imagePath!,
                width: kCardPhotoWidth,
                height: kCardPhotoHeight,
                borderRadius: BorderRadius.circular(12),
                leadingSpacing: 12,
              ),
          ],
        ),
      ],
    );

    if (!inactive) {
      return body;
    }

    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.33, 0.33, 0.33, 0, 0,
        0.33, 0.33, 0.33, 0, 0,
        0.33, 0.33, 0.33, 0, 0,
        0, 0, 0, 0.7, 0,
      ]),
      child: Opacity(
        opacity: 0.65,
        child: body,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CardsRepository.instance,
      builder: (context, _) {
        final cards = _cardsForCategory();
        if (cards.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
          return const SizedBox.shrink();
        }

        final currentIndex = _indexForCard(cards, _focusedCardId);
        final card = cards[currentIndex];
        final showArrows = cards.length > 1;

        return LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: constraints.maxHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildCardBody(card),
                    ),
                  ),
                  CardViewActionBar(
                    showLeftArrow: showArrows && currentIndex > 0,
                    showRightArrow: showArrows,
                    onPrevious: showArrows && currentIndex > 0
                        ? () => _showPrevious(cards, currentIndex)
                        : null,
                    onNext: showArrows
                        ? () => _showNext(cards, currentIndex)
                        : null,
                    onEdit: () => _editCard(card),
                    onDelete: () => _deleteCard(card, cards),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
