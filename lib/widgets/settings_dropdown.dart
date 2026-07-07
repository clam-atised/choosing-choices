import 'package:flutter/material.dart';

import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';

class SettingsDropdown extends StatefulWidget {
  const SettingsDropdown({
    super.key,
    required this.items,
    this.selectedValue,
    this.placeholder,
    this.trailingIcon = Icons.arrow_drop_down,
    this.onChanged,
  });

  final List<String> items;
  final String? selectedValue;
  final String? placeholder;
  final IconData trailingIcon;
  final ValueChanged<String>? onChanged;

  @override
  State<SettingsDropdown> createState() => _SettingsDropdownState();
}

class _SettingsDropdownState extends State<SettingsDropdown> {
  bool _isExpanded = false;
  late String? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.selectedValue;
  }

  @override
  void didUpdateWidget(SettingsDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedValue != oldWidget.selectedValue) {
      _selectedValue = widget.selectedValue;
    }
  }

  void _toggleExpanded() {
    if (widget.items.isEmpty) {
      return;
    }
    setState(() => _isExpanded = !_isExpanded);
  }

  void _selectItem(String value) {
    setState(() {
      _selectedValue = value;
      _isExpanded = false;
    });
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _selectedValue ?? widget.placeholder ?? '';
    final hasItems = widget.items.isNotEmpty;

    return Column(
      children: [
        Material(
          color: AppColours.light,
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(12),
            bottom: Radius.circular(_isExpanded ? 0 : 12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: Radius.circular(_isExpanded ? 0 : 12),
            ),
            onTap: hasItems ? _toggleExpanded : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayText,
                      style: AppTextStyles.alice(fontSize: 18),
                    ),
                  ),
                  Icon(widget.trailingIcon, color: AppColours.dark),
                ],
              ),
            ),
          ),
        ),
        if (_isExpanded && hasItems)
          Material(
            color: AppColours.light,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
            child: Column(
              children: [
                for (final item in widget.items)
                  InkWell(
                    onTap: () => _selectItem(item),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item,
                          style: AppTextStyles.alice(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
