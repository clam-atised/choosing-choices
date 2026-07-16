import 'package:flutter/material.dart';

import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';

Future<T?> showChoicesDialog<T>({
  required BuildContext context,
  required Widget child,
  double maxWidth = 520,
  bool scrollable = true,
}) {
  final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

  return showDialog<T>(
    context: context,
    barrierColor: AppColours.dark.withValues(alpha: 0.6),
    builder: (context) => Dialog(
      backgroundColor: AppColours.light,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: scrollable ? SingleChildScrollView(child: child) : child,
        ),
      ),
    ),
  );
}

class ChoicesDialogDeleteButton extends StatelessWidget {
  const ChoicesDialogDeleteButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          label,
          style: AppTextStyles.alice(fontSize: 16),
        ),
      ),
    );
  }
}

class ChoicesDialogSectionLabel extends StatelessWidget {
  const ChoicesDialogSectionLabel({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.alice(fontSize: 16),
    );
  }
}
