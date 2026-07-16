import 'package:flutter/material.dart';

import '../models/choice_card.dart';
import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';
import '../utils/detail_field_formatters.dart';
import 'detail_value_editor.dart';

class DetailValueRow extends StatelessWidget {
  const DetailValueRow({
    super.key,
    required this.field,
    required this.onChanged,
    this.allowDropdownAddData = true,
  });

  final CardDetailField field;
  final ValueChanged<CardDetailField> onChanged;
  final bool allowDropdownAddData;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${normalizeDetailLabel(field.label)}:',
            style: AppTextStyles.alice(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColours.dark,
            ),
          ),
          const SizedBox(height: 8),
          DetailValueEditor(
            field: field,
            onChanged: onChanged,
            allowDropdownAddData: allowDropdownAddData,
          ),
        ],
      ),
    );
  }
}
