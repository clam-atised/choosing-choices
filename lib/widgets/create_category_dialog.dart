import 'package:flutter/material.dart';

import '../data/folders_repository.dart';
import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';
import 'bordered_dialog_field.dart';
import 'choices_dialog_shell.dart';
import 'selection_dropdown.dart';

class CreateCategoryResult {
  const CreateCategoryResult({
    required this.folderId,
    required this.itemId,
  });

  final String folderId;
  final String itemId;
}

Future<CreateCategoryResult?> showCreateCategoryDialog(
  BuildContext context, {
  required String initialFolderId,
}) {
  return showChoicesDialog<CreateCategoryResult>(
    context: context,
    child: CreateCategoryDialog(initialFolderId: initialFolderId),
  );
}

class CreateCategoryDialog extends StatefulWidget {
  const CreateCategoryDialog({
    super.key,
    required this.initialFolderId,
  });

  final String initialFolderId;

  @override
  State<CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<CreateCategoryDialog> {
  final FoldersRepository _repository = FoldersRepository.instance;
  final TextEditingController _nameController = TextEditingController();

  String? _selectedFolderName;
  bool _isDropdownExpanded = false;
  bool _initialFolderApplied = false;

  @override
  void initState() {
    super.initState();
    _applyInitialFolder();
  }

  void _applyInitialFolder() {
    if (_initialFolderApplied) {
      return;
    }

    final folder = _repository.folderById(widget.initialFolderId);
    if (folder != null) {
      _selectedFolderName = folder.name;
      _initialFolderApplied = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? get _trimmedName {
    final value = _nameController.text.trim();
    return value.isEmpty ? null : value;
  }

  bool get _canCreate {
    final name = _trimmedName;
    if (name == null || _selectedFolderName == null) {
      return false;
    }
    return _repository.folderByName(_selectedFolderName!) != null;
  }

  void _syncSelectedFolder(List<String> folderNames) {
    if (folderNames.isEmpty) {
      _selectedFolderName = null;
      return;
    }

    if (_selectedFolderName != null &&
        folderNames.contains(_selectedFolderName)) {
      return;
    }

    _selectedFolderName = folderNames.first;
  }

  Future<void> _create() async {
    if (!_canCreate) {
      return;
    }

    final folder = _repository.folderByName(_selectedFolderName!);
    if (folder == null) {
      return;
    }

    final item = await _repository.addItem(folder.id, _trimmedName!);
    if (!mounted || item == null) {
      return;
    }

    Navigator.of(context).pop(
      CreateCategoryResult(folderId: folder.id, itemId: item.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _repository,
      builder: (context, _) {
        final folderNames = _repository.folderNames;
        _applyInitialFolder();
        _syncSelectedFolder(folderNames);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create',
              style: AppTextStyles.alice(fontSize: 22),
            ),
            const SizedBox(height: 16),
            BorderedDialogField(
              controller: _nameController,
              hintText: 'Category',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'in:',
                style: AppTextStyles.alice(fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
            SelectionDropdown(
              options: folderNames,
              selectedValue: _selectedFolderName,
              placeholder: 'Folder name',
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
