import 'package:flutter/material.dart';

import '../models/choice_card.dart';
// import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';
import 'choices_dialog_shell.dart';

Future<DetailFieldType?> showDetailTypePicker(BuildContext context) {
  return showChoicesDialog<DetailFieldType>(
    context: context,
    child: const DetailTypePickerSheet(),
  );
}

class DetailTypePickerSheet extends StatelessWidget {
  const DetailTypePickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Add detail',
          style: AppTextStyles.alice(fontSize: 20),
        ),
        const SizedBox(height: 12),
        _TypeOption(
          label: 'Text cell',
          onTap: () => Navigator.pop(context, DetailFieldType.text),
        ),
        _TypeOption(
          label: 'Yes/No cell',
          onTap: () => Navigator.pop(context, DetailFieldType.yesNo),
        ),
        _TypeOption(
          label: 'Dropdown cell',
          onTap: () => Navigator.pop(context, DetailFieldType.dropdown),
        ),
      ],
    );
  }
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          label,
          style: AppTextStyles.alice(fontSize: 18),
        ),
      ),
    );
  }
}
