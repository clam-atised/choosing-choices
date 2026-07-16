import 'package:flutter/material.dart';

import '../models/choice_card.dart';
import '../platform/platform_image.dart';
import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';
import '../theme/layout_constants.dart';
import '../utils/detail_field_formatters.dart';
import 'choices_dialog_shell.dart';

Future<void> showCardDetailDialog(
  BuildContext context, {
  required ChoiceCard card,
}) {
  return showChoicesDialog<void>(
    context: context,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                card.title,
                style: AppTextStyles.alice(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.close, color: AppColours.dark),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (card.imagePath != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: kCardPhotoWidth / kCardPhotoHeight,
              child: PlatformImage(
                path: card.imagePath!,
                fit: BoxFit.cover,
                errorWidget: ColoredBox(color: AppColours.light),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        for (final detail in card.details)
          if (normalizeDetailLabel(detail.label).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                formatDetailLine(detail),
                style: AppTextStyles.sourceSans(fontSize: 14),
              ),
            ),
      ],
    ),
  );
}
