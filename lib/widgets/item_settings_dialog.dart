import 'package:flutter/material.dart';

import '../data/folders_repository.dart';
import '../models/category_item.dart';
import '../services/export_service.dart';
import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';
import 'category_card_schema_editor.dart';
import 'choices_dialog_shell.dart';
import 'dialog_title_field.dart';
import 'export_data_dropdown.dart';

enum _ItemSettingsTab { category, card }

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
  _ItemSettingsTab _tab = _ItemSettingsTab.category;

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
            const SizedBox(height: 16),
            _ItemSettingsTabBar(
              selected: _tab,
              onChanged: (tab) => setState(() => _tab = tab),
            ),
            const SizedBox(height: 16),
            if (_tab == _ItemSettingsTab.category)
              _CategorySettingsTab(
                folder: folder,
                item: item,
                folderId: widget.folderId,
                itemId: widget.itemId,
              )
            else
              CategoryCardSchemaEditor(
                folderId: widget.folderId,
                itemId: widget.itemId,
              ),
          ],
        );
      },
    );
  }
}

class _ItemSettingsTabBar extends StatelessWidget {
  const _ItemSettingsTabBar({
    required this.selected,
    required this.onChanged,
  });

  final _ItemSettingsTab selected;
  final ValueChanged<_ItemSettingsTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TabLabel(
          label: 'Category',
          selected: selected == _ItemSettingsTab.category,
          onTap: () => onChanged(_ItemSettingsTab.category),
        ),
        const SizedBox(width: 20),
        _TabLabel(
          label: 'Card',
          selected: selected == _ItemSettingsTab.card,
          onTap: () => onChanged(_ItemSettingsTab.card),
        ),
      ],
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.alice(
              fontSize: 18,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 56,
            color: selected ? AppColours.dark : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

class _CategorySettingsTab extends StatelessWidget {
  const _CategorySettingsTab({
    required this.folder,
    required this.item,
    required this.folderId,
    required this.itemId,
  });

  final Folder folder;
  final CategoryItem item;
  final String folderId;
  final String itemId;

  @override
  Widget build(BuildContext context) {
    final repository = FoldersRepository.instance;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ChoicesDialogSectionLabel(
          label: 'Card display direction:',
        ),
        _CardDirectionRadioGroup(
          direction: item.cardDisplayDirection,
          onChanged: (direction) {
            repository.setItemCardDirection(
              folderId,
              itemId,
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
            await repository.deleteItem(folderId, itemId);
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ],
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
    scrollable: true,
    child: ItemSettingsDialog(
      folderId: folderId,
      itemId: itemId,
    ),
  );
}
