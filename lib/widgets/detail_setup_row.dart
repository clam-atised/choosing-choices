import 'package:flutter/material.dart';

import '../models/choice_card.dart';
import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';
import 'dashed_border.dart';
import 'detail_value_editor.dart';
import 'selection_dropdown.dart';

class DetailSetupRow extends StatefulWidget {
  const DetailSetupRow({
    super.key,
    required this.field,
    required this.onChanged,
  });

  final CardDetailField field;
  final ValueChanged<CardDetailField> onChanged;

  @override
  State<DetailSetupRow> createState() => _DetailSetupRowState();
}

class _DetailSetupRowState extends State<DetailSetupRow> {
  late final TextEditingController _labelController;
  bool _isTypeDropdownExpanded = false;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.field.label);
  }

  @override
  void didUpdateWidget(covariant DetailSetupRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.field.label != widget.field.label &&
        _labelController.text != widget.field.label) {
      _labelController.text = widget.field.label;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _onTypeSelected(String displayLabel) {
    final type = DetailFieldType.fromDisplayLabel(displayLabel);
    widget.onChanged(
      widget.field.copyWith(
        type: type,
        yesNoValue: type == DetailFieldType.yesNo ? false : widget.field.yesNoValue,
        weekDays: type == DetailFieldType.days
            ? List<bool>.filled(7, false)
            : widget.field.weekDays,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashedBorder(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _labelController,
                    decoration: InputDecoration(
                      hintText: 'Type detail',
                      hintStyle: AppTextStyles.alice(
                        fontSize: 16,
                        color: AppColours.dark.withValues(alpha: 0.6),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: AppTextStyles.alice(fontSize: 16),
                    onChanged: (value) =>
                        widget.onChanged(widget.field.copyWith(label: value)),
                  ),
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: AppColours.dark.withValues(alpha: 0.3),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                SizedBox(
                  width: 130,
                  child: SelectionDropdown(
                    options: DetailFieldType.displayLabels,
                    selectedValue: widget.field.type.displayLabel,
                    placeholder: 'Type',
                    isExpanded: _isTypeDropdownExpanded,
                    onToggle: () {
                      setState(
                        () => _isTypeDropdownExpanded = !_isTypeDropdownExpanded,
                      );
                    },
                    onSelect: (value) {
                      setState(() => _isTypeDropdownExpanded = false);
                      _onTypeSelected(value);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          DetailValueEditor(
            field: widget.field,
            onChanged: widget.onChanged,
          ),
        ],
      ),
    );
  }
}
