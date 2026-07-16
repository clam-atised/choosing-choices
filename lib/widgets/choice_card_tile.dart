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
import 'card_detail_dialog.dart';

class ChoiceCardTile extends StatelessWidget {
  const ChoiceCardTile({
    super.key,
    required this.card,
    this.onLongPress,
    this.compact = true,
  });

  final ChoiceCard card;
  final VoidCallback? onLongPress;
  final bool compact;

  static const Key completedCardKey = Key('card_completed_overlay');
  static const String reopenSnackBarMessage =
      "To reopen this card, set a new date that hasn't passed yet.";

  Future<void> _onTick(BuildContext context) async {
    if (isCardInactive(card)) {
      return;
    }

    await CardsRepository.instance.setCardCompleted(
      card.id,
      completed: true,
    );
    if (!context.mounted) {
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

  Future<void> _onCardTap(BuildContext context) async {
    if (isCardInactive(card)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(reopenSnackBarMessage)),
      );
      await showAddCardDialog(
        context,
        folderId: card.folderId,
        existingCard: card,
      );
      return;
    }

    await showCardDetailDialog(context, card: card);
  }

  @override
  Widget build(BuildContext context) {
    final photoWidth = compact ? kCardListPhotoSize : kCardPhotoWidth;
    final photoHeight = compact ? kCardListPhotoSize : kCardPhotoHeight;
    final titleMaxLines = compact ? 1 : 3;
    final detailMaxLines = compact ? 2 : null;
    final hasPhoto = card.imagePath != null;
    final inactive = isCardInactive(card);

    final content = GestureDetector(
      onTap: () => _onCardTap(context),
      onLongPress: onLongPress,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColours.light,
          border: Border.all(color: AppColours.dark),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _CardTitleHeader(
              title: card.title,
              showTick: !inactive,
              titleMaxLines: titleMaxLines,
              onTick: () => _onTick(context),
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
                            padding: EdgeInsets.only(bottom: compact ? 4 : 6),
                            child: Text(
                              formatDetailLine(detail),
                              maxLines: detailMaxLines,
                              overflow: detailMaxLines != null
                                  ? TextOverflow.ellipsis
                                  : TextOverflow.clip,
                              style: AppTextStyles.sourceSans(
                                fontSize: 14,
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
                if (hasPhoto) ...[
                  const SizedBox(width: 12),
                  _CardPhotoBox(
                    imagePath: card.imagePath!,
                    width: photoWidth,
                    height: photoHeight,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );

    final clipped = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: content,
    );

    if (!inactive) {
      return clipped;
    }

    return ColorFiltered(
      key: completedCardKey,
      colorFilter: const ColorFilter.matrix(<double>[
        0.33, 0.33, 0.33, 0, 0,
        0.33, 0.33, 0.33, 0, 0,
        0.33, 0.33, 0.33, 0, 0,
        0, 0, 0, 0.7, 0,
      ]),
      child: Opacity(
        opacity: 0.65,
        child: clipped,
      ),
    );
  }
}

class _CardTitleHeader extends StatelessWidget {
  const _CardTitleHeader({
    required this.title,
    required this.onTick,
    required this.showTick,
    required this.titleMaxLines,
  });

  final String title;
  final VoidCallback onTick;
  final bool showTick;
  final int titleMaxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColours.dark),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: titleMaxLines,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.alice(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (showTick)
            GestureDetector(
              onTap: onTick,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColours.dark,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColours.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CardPhotoBox extends StatelessWidget {
  const _CardPhotoBox({
    required this.imagePath,
    required this.width,
    required this.height,
  });

  final String imagePath;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: PlatformImage(
          path: imagePath,
          fit: BoxFit.cover,
          errorWidget: ColoredBox(color: AppColours.light),
        ),
      ),
    );
  }
}
