import 'package:flutter/material.dart';

import '../models/choice_card.dart';
import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';
import '../utils/card_date_utils.dart';
import '../utils/detail_field_formatters.dart';

class DetailValueEditor extends StatefulWidget {
  const DetailValueEditor({
    super.key,
    required this.field,
    required this.onChanged,
    this.allowDropdownAddData = true,
  });

  final CardDetailField field;
  final ValueChanged<CardDetailField> onChanged;
  final bool allowDropdownAddData;

  @override
  State<DetailValueEditor> createState() => _DetailValueEditorState();
}

class _DetailValueEditorState extends State<DetailValueEditor> {
  final TextEditingController _dropdownAddController = TextEditingController();
  late final TextEditingController _textValueController;

  UnderlineInputBorder get _pinkUnderline => UnderlineInputBorder(
        borderSide: BorderSide(color: AppColours.dark),
      );

  UnderlineInputBorder get _pinkUnderlineFocused => UnderlineInputBorder(
        borderSide: BorderSide(color: AppColours.dark, width: 2),
      );

  @override
  void initState() {
    super.initState();
    _textValueController =
        TextEditingController(text: widget.field.textValue ?? '');
  }

  @override
  void didUpdateWidget(covariant DetailValueEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.field.textValue != widget.field.textValue &&
        _textValueController.text != (widget.field.textValue ?? '')) {
      _textValueController.text = widget.field.textValue ?? '';
    }
  }

  @override
  void dispose() {
    _dropdownAddController.dispose();
    _textValueController.dispose();
    super.dispose();
  }

  InputDecoration _pinkFieldDecoration({
    required String hintText,
    double hintFontSize = 16,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.alice(
        fontSize: hintFontSize,
        color: AppColours.dark.withValues(alpha: 0.6),
      ),
      isDense: true,
      border: _pinkUnderline,
      enabledBorder: _pinkUnderline,
      focusedBorder: _pinkUnderlineFocused,
    );
  }

  Widget _previewLabel() {
    return Text(
      detailFieldPreviewLabel(widget.field),
      style: AppTextStyles.alice(
        fontSize: 16,
        color: AppColours.dark,
      ),
    );
  }

  void _addDropdownOption() {
    final value = _dropdownAddController.text.trim();
    if (value.isEmpty) {
      return;
    }

    final options = [...widget.field.dropdownOptions];
    if (options.contains(value)) {
      widget.onChanged(widget.field.copyWith(dropdownValue: value));
      _dropdownAddController.clear();
      return;
    }

    options.add(value);
    widget.onChanged(
      widget.field.copyWith(
        dropdownOptions: options,
        dropdownValue: value,
      ),
    );
    _dropdownAddController.clear();
  }

  Future<void> _pickTime({required bool isFrom}) async {
    final initial = _parseTime(
      isFrom ? widget.field.timeFrom : widget.field.timeTo,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial ?? TimeOfDay.now(),
    );
    if (picked == null || !mounted) {
      return;
    }

    final formatted = _formatTime(picked);
    widget.onChanged(
      widget.field.copyWith(
        timeFrom: isFrom ? formatted : widget.field.timeFrom,
        timeTo: isFrom ? widget.field.timeTo : formatted,
      ),
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final currentFrom = parseIsoDate(widget.field.dateFrom);
    final currentTo = parseIsoDate(widget.field.dateTo);
    final initial = (isFrom ? currentFrom : currentTo) ??
        currentFrom ??
        currentTo ??
        DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) {
      return;
    }

    final formatted = formatIsoDate(picked);
    if (isFrom) {
      final to = widget.field.dateTo;
      final toDate = parseIsoDate(to);
      widget.onChanged(
        widget.field.copyWith(
          dateFrom: formatted,
          dateTo: toDate != null && toDate.isBefore(dateOnly(picked))
              ? formatted
              : to,
        ),
      );
    } else {
      final from = widget.field.dateFrom;
      final fromDate = parseIsoDate(from);
      widget.onChanged(
        widget.field.copyWith(
          dateFrom: fromDate != null && dateOnly(picked).isBefore(fromDate)
              ? formatted
              : from ?? formatted,
          dateTo: formatted,
        ),
      );
    }
  }

  void _clearDates() {
    widget.onChanged(widget.field.copyWith(clearDates: true));
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null || !value.contains(':')) {
      return null;
    }
    final parts = value.split(':');
    if (parts.length != 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _dateButtonLabel(String? iso, String fallback) {
    final date = parseIsoDate(iso);
    if (date == null) {
      return fallback;
    }
    return detailFieldDisplayValue(
      widget.field.copyWith(dateFrom: iso, dateTo: iso),
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.field.type) {
      DetailFieldType.text => TextField(
          decoration: _pinkFieldDecoration(
            hintText: detailFieldPreviewLabel(
              widget.field.copyWith(textValue: ''),
            ),
          ),
          style: AppTextStyles.alice(fontSize: 16, color: AppColours.dark),
          cursorColor: AppColours.dark,
          controller: _textValueController,
          onChanged: (value) =>
              widget.onChanged(widget.field.copyWith(textValue: value)),
        ),
      DetailFieldType.yesNo => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _previewLabel(),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<bool>(
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.all(AppColours.dark),
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColours.dark.withValues(alpha: 0.12);
                    }
                    return AppColours.light;
                  }),
                  side: WidgetStateProperty.all(
                    BorderSide(color: AppColours.dark),
                  ),
                ),
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(
                      'No',
                      style: AppTextStyles.alice(
                        fontSize: 14,
                        color: AppColours.dark,
                      ),
                    ),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(
                      'Yes',
                      style: AppTextStyles.alice(
                        fontSize: 14,
                        color: AppColours.dark,
                      ),
                    ),
                  ),
                ],
                selected: {widget.field.yesNoValue ?? false},
                onSelectionChanged: (selection) {
                  widget.onChanged(
                    widget.field.copyWith(yesNoValue: selection.first),
                  );
                },
              ),
            ),
          ],
        ),
      DetailFieldType.dropdown => _buildDropdownEditor(),
      DetailFieldType.time => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _previewLabel(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColours.dark,
                      side: BorderSide(color: AppColours.dark),
                    ),
                    onPressed: () => _pickTime(isFrom: true),
                    child: Text(
                      widget.field.timeFrom ?? 'From',
                      style: AppTextStyles.alice(
                        fontSize: 14,
                        color: AppColours.dark,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '–',
                    style: AppTextStyles.alice(
                      fontSize: 16,
                      color: AppColours.dark,
                    ),
                  ),
                ),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColours.dark,
                      side: BorderSide(color: AppColours.dark),
                    ),
                    onPressed: () => _pickTime(isFrom: false),
                    child: Text(
                      widget.field.timeTo ?? 'To',
                      style: AppTextStyles.alice(
                        fontSize: 14,
                        color: AppColours.dark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      DetailFieldType.days => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _previewLabel(),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (var index = 0; index < 7; index++)
                  FilterChip(
                    label: Text(
                      kWeekDayLabels[index],
                      style: AppTextStyles.alice(
                        fontSize: 12,
                        color: AppColours.dark,
                      ),
                    ),
                    selected: normalizeWeekDays(widget.field.weekDays)[index],
                    selectedColor: AppColours.dark.withValues(alpha: 0.2),
                    checkmarkColor: AppColours.dark,
                    backgroundColor: AppColours.light,
                    side: BorderSide(color: AppColours.dark),
                    onSelected: (selected) {
                      final days = normalizeWeekDays(widget.field.weekDays);
                      days[index] = selected;
                      widget.onChanged(widget.field.copyWith(weekDays: days));
                    },
                  ),
              ],
            ),
          ],
        ),
      DetailFieldType.date => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: _previewLabel()),
                if (widget.field.dateFrom != null ||
                    widget.field.dateTo != null)
                  IconButton(
                    tooltip: 'Clear date',
                    icon: Icon(Icons.delete_outline, color: AppColours.dark),
                    onPressed: _clearDates,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColours.dark,
                      side: BorderSide(color: AppColours.dark),
                    ),
                    onPressed: () => _pickDate(isFrom: true),
                    child: Text(
                      _dateButtonLabel(widget.field.dateFrom, 'From'),
                      style: AppTextStyles.alice(
                        fontSize: 14,
                        color: AppColours.dark,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '–',
                    style: AppTextStyles.alice(
                      fontSize: 16,
                      color: AppColours.dark,
                    ),
                  ),
                ),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColours.dark,
                      side: BorderSide(color: AppColours.dark),
                    ),
                    onPressed: () => _pickDate(isFrom: false),
                    child: Text(
                      _dateButtonLabel(widget.field.dateTo, 'To'),
                      style: AppTextStyles.alice(
                        fontSize: 14,
                        color: AppColours.dark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
    };
  }

  Widget _buildDropdownEditor() {
    final options = widget.field.dropdownOptions;
    final selectedValue = widget.field.dropdownValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _previewLabel(),
        const SizedBox(height: 8),
        if (options.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final option in options)
                    Material(
                      color: option == selectedValue
                          ? AppColours.dark.withValues(alpha: 0.08)
                          : Colors.transparent,
                      child: InkWell(
                        onTap: () => widget.onChanged(
                          widget.field.copyWith(dropdownValue: option),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              option,
                              style: AppTextStyles.alice(
                                fontSize: 16,
                                color: AppColours.dark,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          )
        else
          Text(
            'No options yet',
            style: AppTextStyles.alice(
              fontSize: 14,
              color: AppColours.dark.withValues(alpha: 0.6),
            ),
          ),
        if (widget.allowDropdownAddData) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _dropdownAddController,
                  decoration: _pinkFieldDecoration(
                    hintText: 'Add data',
                    hintFontSize: 14,
                  ),
                  style: AppTextStyles.alice(
                    fontSize: 14,
                    color: AppColours.dark,
                  ),
                  cursorColor: AppColours.dark,
                  onSubmitted: (_) => _addDropdownOption(),
                ),
              ),
              IconButton(
                tooltip: 'Add data',
                icon: Icon(Icons.add, color: AppColours.dark),
                onPressed: _addDropdownOption,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
