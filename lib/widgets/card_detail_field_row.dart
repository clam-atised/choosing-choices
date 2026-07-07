import 'package:flutter/material.dart';

import '../models/choice_card.dart';
import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';

class CardDetailFieldRow extends StatelessWidget {
  const CardDetailFieldRow({
    super.key,
    required this.field,
    required this.onChanged,
  });

  final CardDetailField field;
  final ValueChanged<CardDetailField> onChanged;

  @override
  Widget build(BuildContext context) {
    if (field.label.trim().isNotEmpty && _hasDisplayValue) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: RichText(
          text: TextSpan(
            style: AppTextStyles.alice(fontSize: 16, color: AppColours.dark),
            children: [
              TextSpan(
                text: '${field.label}: ',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: _displayValue),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Label',
              isDense: true,
              border: UnderlineInputBorder(),
            ),
            style: AppTextStyles.alice(fontSize: 16),
            onChanged: (value) => onChanged(field.copyWith(label: value)),
          ),
          const SizedBox(height: 8),
          _buildEditor(),
        ],
      ),
    );
  }

  bool get _hasDisplayValue {
    return switch (field.type) {
      DetailFieldType.text => (field.textValue ?? '').trim().isNotEmpty,
      DetailFieldType.yesNo => field.yesNoValue != null,
      DetailFieldType.dropdown =>
        (field.dropdownValue ?? '').trim().isNotEmpty,
    };
  }

  String get _displayValue {
    return switch (field.type) {
      DetailFieldType.text => field.textValue ?? '',
      DetailFieldType.yesNo => (field.yesNoValue ?? false) ? 'Yes' : 'No',
      DetailFieldType.dropdown => field.dropdownValue ?? '',
    };
  }

  Widget _buildEditor() {
    return switch (field.type) {
      DetailFieldType.text => TextField(
          decoration: const InputDecoration(
            hintText: 'Value',
            isDense: true,
            border: UnderlineInputBorder(),
          ),
          style: AppTextStyles.alice(fontSize: 16),
          onChanged: (value) => onChanged(field.copyWith(textValue: value)),
        ),
      DetailFieldType.yesNo => SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('No')),
            ButtonSegment(value: true, label: Text('Yes')),
          ],
          selected: {field.yesNoValue ?? false},
          onSelectionChanged: (selection) {
            onChanged(field.copyWith(yesNoValue: selection.first));
          },
        ),
      DetailFieldType.dropdown => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Options (comma separated)',
                isDense: true,
                border: UnderlineInputBorder(),
              ),
              style: AppTextStyles.alice(fontSize: 16),
              onChanged: (value) {
                final options = value
                    .split(',')
                    .map((option) => option.trim())
                    .where((option) => option.isNotEmpty)
                    .toList();
                onChanged(
                  field.copyWith(
                    dropdownOptions: options,
                    dropdownValue: options.isEmpty
                        ? null
                        : (field.dropdownValue != null &&
                                options.contains(field.dropdownValue))
                            ? field.dropdownValue
                            : options.first,
                  ),
                );
              },
            ),
            if (field.dropdownOptions.isNotEmpty) ...[
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: field.dropdownValue ?? field.dropdownOptions.first,
                isExpanded: true,
                items: [
                  for (final option in field.dropdownOptions)
                    DropdownMenuItem(
                      value: option,
                      child: Text(option),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onChanged(field.copyWith(dropdownValue: value));
                  }
                },
              ),
            ],
          ],
        ),
    };
  }
}
