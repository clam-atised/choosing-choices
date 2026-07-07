import 'package:flutter/material.dart';

import '../data/folders_repository.dart';
import '../models/category_item.dart';
import '../services/export_service.dart';
import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';
import 'choices_dialog_shell.dart';
import 'dialog_title_field.dart';
import 'export_data_dropdown.dart';

class ItemSettingsDialog extends StatefulWidget {
  const ItemSettingsDialog({
    super.key,
    required this.folderId,
    required this.itemId,
  });

  final String folderId;
  final String itemId;

  @override
  State<ItemSettingsDialog> createState() => _ItemSettingsDialogState();
}

class _ItemSettingsDialogState extends State<ItemSettingsDialog> {
  final FoldersRepository _repository = FoldersRepository.instance;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _repository,
      builder: (context, _) {
        final folder = _repository.folderById(widget.folderId);
        final item = _repository.itemById(widget.folderId, widget.itemId);

        if (folder == null || item == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          });
          return const SizedBox.shrink();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DialogTitleField(
              initialValue: item.name,
              onSubmitted: (name) {
                _repository.updateItemName(
                  widget.folderId,
                  widget.itemId,
                  name.trim(),
                );
              },
            ),
            const SizedBox(height: 20),
            const ChoicesDialogSectionLabel(
              label: 'Card display direction:',
            ),
            _CardDirectionRadioGroup(
              direction: item.cardDisplayDirection,
              onChanged: (direction) {
                _repository.setItemCardDirection(
                  widget.folderId,
                  widget.itemId,
                  direction,
                );
              },
            ),
            const SizedBox(height: 20),
            ExportDataDropdown(
              onExport: (format) {
                return ExportService.instance.exportItem(folder, item, format);
              },
            ),
            const SizedBox(height: 12),
            ChoicesDialogDeleteButton(
              label: 'Delete item & contents',
              onPressed: () async {
                await _repository.deleteItem(widget.folderId, widget.itemId);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class _CardDirectionRadioGroup extends StatelessWidget {
  const _CardDirectionRadioGroup({
    required this.direction,
    required this.onChanged,
  });

  final CardDisplayDirection direction;
  final ValueChanged<CardDisplayDirection> onChanged;

  static final _fillColor = WidgetStateProperty.resolveWith<Color>((states) {
    if (states.contains(WidgetState.selected)) {
      return AppColours.dark;
    }
    return AppColours.dark.withValues(alpha: 0.4);
  });

  @override
  Widget build(BuildContext context) {
    return RadioGroup<CardDisplayDirection>(
      groupValue: direction,
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
      child: Column(
        children: [
          RadioListTile<CardDisplayDirection>(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text('Horizontal', style: AppTextStyles.alice(fontSize: 16)),
            value: CardDisplayDirection.horizontal,
            fillColor: _fillColor,
          ),
          RadioListTile<CardDisplayDirection>(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text('Vertical', style: AppTextStyles.alice(fontSize: 16)),
            value: CardDisplayDirection.vertical,
            fillColor: _fillColor,
          ),
        ],
      ),
    );
  }
}

Future<void> showItemSettingsDialog(
  BuildContext context, {
  required String folderId,
  required String itemId,
}) {
  return showChoicesDialog(
    context: context,
    child: ItemSettingsDialog(
      folderId: folderId,
      itemId: itemId,
    ),
  );
}
