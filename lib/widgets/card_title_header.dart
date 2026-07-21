import 'package:flutter/material.dart';

import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';

class CardTitleHeader extends StatelessWidget {
  const CardTitleHeader({
    super.key,
    required this.title,
    required this.onTick,
    required this.showTick,
    this.titleMaxLines = 3,
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
