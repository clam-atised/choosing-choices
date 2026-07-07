import 'package:flutter/material.dart';

import '../models/choice_card.dart';
import '../platform/platform_image.dart';
import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';

class ChoiceCardTile extends StatelessWidget {
  const ChoiceCardTile({
    super.key,
    required this.card,
    this.onLongPress,
  });

  final ChoiceCard card;
  final VoidCallback? onLongPress;

  String _detailValue(CardDetailField detail) {
    switch (detail.type) {
      case DetailFieldType.text:
        return detail.textValue ?? '';
      case DetailFieldType.yesNo:
        return detail.yesNoValue == true ? 'Yes' : 'No';
      case DetailFieldType.dropdown:
        return detail.dropdownValue ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColours.light,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title,
                    style: AppTextStyles.alice(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final detail in card.details)
                    if (detail.label.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '${detail.label}: ${_detailValue(detail)}',
                          style: AppTextStyles.sourceSans(fontSize: 14),
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (card.imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 110,
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: PlatformImage(
                      path: card.imagePath!,
                      fit: BoxFit.cover,
                      errorWidget: const ColoredBox(color: AppColours.light),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
