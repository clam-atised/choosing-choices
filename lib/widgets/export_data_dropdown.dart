import 'package:flutter/material.dart';

import '../models/export_format.dart';
import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';

class ExportDataDropdown extends StatefulWidget {
  const ExportDataDropdown({
    super.key,
    required this.onExport,
  });

  final Future<void> Function(ExportFormat format) onExport;

  @override
  State<ExportDataDropdown> createState() => _ExportDataDropdownState();
}

class _ExportDataDropdownState extends State<ExportDataDropdown> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }

  Future<void> _selectFormat(String label) async {
    final format = ExportFormat.fromLabel(label);
    if (format == null) {
      return;
    }

    setState(() => _isExpanded = false);
    await widget.onExport(format);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: AppColours.light,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: Radius.circular(_isExpanded ? 0 : 12),
            ),
            side: BorderSide(color: AppColours.dark),
          ),
          child: InkWell(
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: Radius.circular(_isExpanded ? 0 : 12),
            ),
            onTap: _toggleExpanded,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Export data',
                      style: AppTextStyles.alice(fontSize: 18),
                    ),
                  ),
                  Icon(Icons.play_arrow, color: AppColours.dark),
                ],
              ),
            ),
          ),
        ),
        if (_isExpanded)
          Material(
            color: AppColours.light,
            shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              side: BorderSide(color: AppColours.dark),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.25,
              ),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  for (final label in ExportFormat.labels)
                    InkWell(
                      onTap: () => _selectFormat(label),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            label,
                            style: AppTextStyles.alice(fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
