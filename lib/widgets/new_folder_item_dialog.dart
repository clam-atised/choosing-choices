import 'package:flutter/material.dart';

import '../data/folders_repository.dart';
import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';
import 'bordered_dialog_field.dart';
import 'choices_dialog_shell.dart';

Future<void> showNewFolderItemDialog(BuildContext context) {
  return showChoicesDialog<void>(
    context: context,
    child: const NewFolderItemDialog(),
  );
}

class NewFolderItemDialog extends StatefulWidget {
  const NewFolderItemDialog({super.key});

  @override
  State<NewFolderItemDialog> createState() => _NewFolderItemDialogState();
}

class _NewFolderItemDialogState extends State<NewFolderItemDialog> {
  final FoldersRepository _repository = FoldersRepository.instance;
  final TextEditingController _folderNameController = TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();

  String? _selectedFolderName;
  bool _isDropdownExpanded = false;

  @override
  void dispose() {
    _folderNameController.dispose();
    _itemNameController.dispose();
    super.dispose();
  }

  String? get _trimmedFolderName {
    final value = _folderNameController.text.trim();
    return value.isEmpty ? null : value;
  }

  String? get _trimmedItemName {
    final value = _itemNameController.text.trim();
    return value.isEmpty ? null : value;
  }

  bool get _canCreate {
    final folderName = _trimmedFolderName;
    final itemName = _trimmedItemName;

    if (folderName != null) {
      return true;
    }

    if (itemName != null && _selectedFolderName != null) {
      return _repository.folderByName(_selectedFolderName!) != null;
    }

    return false;
  }

  void _syncSelectedFolder(List<String> folderNames) {
    if (folderNames.isEmpty) {
      _selectedFolderName = null;
      return;
    }

    if (_selectedFolderName == null ||
        !folderNames.contains(_selectedFolderName)) {
      _selectedFolderName = folderNames.first;
    }
  }

  Future<void> _create() async {
    if (!_canCreate) {
      return;
    }

    final folderName = _trimmedFolderName;
    final itemName = _trimmedItemName;

    if (folderName != null && itemName != null) {
      final folder = await _repository.addFolder(folderName);
      await _repository.addItem(folder.id, itemName);
    } else if (folderName != null) {
      await _repository.addFolder(folderName);
    } else if (itemName != null && _selectedFolderName != null) {
      final folder = _repository.folderByName(_selectedFolderName!);
      if (folder != null) {
        await _repository.addItem(folder.id, itemName);
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _repository,
      builder: (context, _) {
        final folderNames = _repository.folderNames;
        _syncSelectedFolder(folderNames);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'New',
              style: AppTextStyles.alice(fontSize: 22),
            ),
            const SizedBox(height: 16),
            BorderedDialogField(
              controller: _folderNameController,
              hintText: 'Add folder name',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            BorderedDialogField(
              controller: _itemNameController,
              hintText: 'Add item',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'to folder:',
                style: AppTextStyles.alice(fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
            _FolderDropdown(
              folderNames: folderNames,
              selectedFolderName: _selectedFolderName,
              isExpanded: _isDropdownExpanded,
              onToggle: () {
                if (folderNames.isEmpty) {
                  return;
                }
                setState(() => _isDropdownExpanded = !_isDropdownExpanded);
              },
              onSelect: (name) {
                setState(() {
                  _selectedFolderName = name;
                  _isDropdownExpanded = false;
                });
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _canCreate ? _create : null,
                child: Text(
                  'Create',
                  style: AppTextStyles.alice(
                    fontSize: 16,
                    color: _canCreate
                        ? AppColours.dark
                        : AppColours.dark.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FolderDropdown extends StatelessWidget {
  const _FolderDropdown({
    required this.folderNames,
    required this.selectedFolderName,
    required this.isExpanded,
    required this.onToggle,
    required this.onSelect,
  });

  final List<String> folderNames;
  final String? selectedFolderName;
  final bool isExpanded;
  final VoidCallback onToggle;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final displayText = selectedFolderName ?? 'Folder name';
    final hasItems = folderNames.isNotEmpty;

    return Column(
      children: [
        Material(
          color: AppColours.light,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: Radius.circular(isExpanded ? 0 : 12),
            ),
            side: const BorderSide(color: AppColours.dark),
          ),
          child: InkWell(
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: Radius.circular(isExpanded ? 0 : 12),
            ),
            onTap: hasItems ? onToggle : null,
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
                  Icon(
                    isExpanded ? Icons.arrow_drop_down : Icons.play_arrow,
                    color: AppColours.dark,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isExpanded && hasItems)
          Material(
            color: AppColours.light,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              side: BorderSide(color: AppColours.dark),
            ),
            child: Column(
              children: [
                for (final name in folderNames)
                  InkWell(
                    onTap: () => onSelect(name),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          name,
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
