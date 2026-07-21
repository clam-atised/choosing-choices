import 'package:flutter/material.dart';

import '../theme/app_colours.dart';

class CardViewActionBar extends StatelessWidget {
  const CardViewActionBar({
    super.key,
    required this.showLeftArrow,
    required this.showRightArrow,
    required this.onPrevious,
    required this.onNext,
    required this.onEdit,
    required this.onDelete,
  });

  final bool showLeftArrow;
  final bool showRightArrow;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const Key leftArrowKey = Key('card_view_left_arrow');
  static const Key rightArrowKey = Key('card_view_right_arrow');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: showLeftArrow
                ? IconButton(
                    key: leftArrowKey,
                    tooltip: 'Previous card',
                    onPressed: onPrevious,
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: AppColours.dark,
                      size: 24,
                    ),
                  )
                : null,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit card',
                  onPressed: onEdit,
                  icon: Icon(Icons.edit_outlined, color: AppColours.dark),
                ),
                IconButton(
                  tooltip: 'Delete card',
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline, color: AppColours.dark),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 48,
            child: showRightArrow
                ? IconButton(
                    key: rightArrowKey,
                    tooltip: 'Next card',
                    onPressed: onNext,
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      color: AppColours.dark,
                      size: 24,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
