import 'package:flutter/material.dart';

import '../data/folders_repository.dart';
import '../services/export_service.dart';
import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';
import 'choices_dialog_shell.dart';
import 'dialog_title_field.dart';
import 'export_data_dropdown.dart';

class FolderSettingsDialog extends StatefulWidget {
  const FolderSettingsDialog({
    super.key,
    required this.folderId,
  });

  final String folderId;

  @override
  State<FolderSettingsDialog> createState() => _FolderSettingsDialogState();
}

class _FolderSettingsDialogState extends State<FolderSettingsDialog> {
  final FoldersRepository _repository = FoldersRepository.instance;

  @override
  Widget build(BuildContext context) {
    final folder = _repository.folderById(widget.folderId);
    if (folder == null) {
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: _repository,
      builder: (context, _) {
        final currentFolder = _repository.folderById(widget.folderId);
        if (currentFolder == null) {
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
              initialValue: currentFolder.name,
              onSubmitted: (name) {
                _repository.updateFolderName(widget.folderId, name.trim());
              },
            ),
            const SizedBox(height: 20),
            const ChoicesDialogSectionLabel(label: 'Hide folder:'),
            _HideFolderRadioGroup(
              isHidden: currentFolder.isHidden,
              onChanged: (hidden) {
                _repository.setFolderHidden(widget.folderId, hidden);
              },
            ),
            const SizedBox(height: 20),
            ExportDataDropdown(
              onExport: (format) {
                return ExportService.instance.exportFolder(currentFolder, format);
              },
            ),
            const SizedBox(height: 12),
            ChoicesDialogDeleteButton(
              label: 'Delete folder & contents',
              onPressed: () async {
                await _repository.deleteFolder(widget.folderId);
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

class _HideFolderRadioGroup extends StatelessWidget {
  const _HideFolderRadioGroup({
    required this.isHidden,
    required this.onChanged,
  });

  final bool isHidden;
  final ValueChanged<bool> onChanged;

  static final _fillColor = WidgetStateProperty.resolveWith<Color>((states) {
    if (states.contains(WidgetState.selected)) {
      return AppColours.dark;
    }
    return AppColours.dark.withValues(alpha: 0.4);
  });

  @override
  Widget build(BuildContext context) {
    return RadioGroup<bool>(
      groupValue: isHidden,
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
      child: Column(
        children: [
          RadioListTile<bool>(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text('Hide', style: AppTextStyles.alice(fontSize: 16)),
            value: true,
            fillColor: _fillColor,
          ),
          RadioListTile<bool>(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text('Unhide', style: AppTextStyles.alice(fontSize: 16)),
            value: false,
            fillColor: _fillColor,
          ),
        ],
      ),
    );
  }
}

Future<void> showFolderSettingsDialog(
  BuildContext context, {
  required String folderId,
}) {
  return showChoicesDialog(
    context: context,
    child: FolderSettingsDialog(folderId: folderId),
  );
}
