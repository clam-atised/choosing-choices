import 'package:flutter/material.dart';

import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';

class CreateActionsCallbacks {
  const CreateActionsCallbacks({
    required this.onCreateFolder,
    required this.onCreateCategory,
    required this.onCreateCard,
  });

  final VoidCallback onCreateFolder;
  final VoidCallback onCreateCategory;
  final VoidCallback onCreateCard;
}

Future<void> showCreateActionsMenu(
  BuildContext context, {
  required Offset anchor,
  required CreateActionsCallbacks callbacks,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss create menu',
    barrierColor: Colors.transparent,
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _CreateActionsMenuOverlay(
        anchor: anchor,
        callbacks: callbacks,
      );
    },
  );
}

class _CreateActionsMenuOverlay extends StatelessWidget {
  const _CreateActionsMenuOverlay({
    required this.anchor,
    required this.callbacks,
  });

  final Offset anchor;
  final CreateActionsCallbacks callbacks;

  static const List<String> _labels = [
    'Create folder',
    'Create category',
    'Create card',
  ];

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    const buttonHeight = 44.0;
    const buttonSpacing = 10.0;
    const buttonWidth = 168.0;
    const verticalGap = 8.0;

    final menuHeight =
        _labels.length * buttonHeight + (_labels.length - 1) * buttonSpacing;
    final top = anchor.dy + verticalGap;
    final right = screenSize.width - anchor.dx;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        Positioned(
          top: top,
          right: right,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: buttonWidth,
              height: menuHeight,
              child: Stack(
                children: [
                  for (var index = 0; index < _labels.length; index++)
                    Positioned(
                      top: index * (buttonHeight + buttonSpacing),
                      right: 0,
                      child: _CreateActionButton(
                        label: _labels[index],
                        onPressed: () {
                          Navigator.of(context).pop();
                          switch (index) {
                            case 0:
                              callbacks.onCreateFolder();
                            case 1:
                              callbacks.onCreateCategory();
                            case 2:
                              callbacks.onCreateCard();
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CreateActionButton extends StatelessWidget {
  const _CreateActionButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColours.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 2,
      shadowColor: AppColours.shadow.withValues(alpha: 0.2),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 168,
          height: 44,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: AppTextStyles.alice(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

Offset? anchorOffsetForKey(GlobalKey key) {
  final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
  if (renderBox == null || !renderBox.hasSize) {
    return null;
  }

  final offset = renderBox.localToGlobal(Offset.zero);
  return Offset(
    offset.dx + renderBox.size.width,
    offset.dy + renderBox.size.height / 2,
  );
}
