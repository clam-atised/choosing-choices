import 'package:flutter/material.dart';

import '../data/folders_repository.dart';
import '../models/category_item.dart';
import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';
import 'bordered_dialog_field.dart';
import 'choices_dialog_shell.dart';

Future<Folder?> showCreateFolderDialog(BuildContext context) {
  return showChoicesDialog<Folder?>(
    context: context,
    child: const CreateFolderDialog(),
  );
}

class CreateFolderDialog extends StatefulWidget {
  const CreateFolderDialog({super.key});

  @override
  State<CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<CreateFolderDialog> {
  final FoldersRepository _repository = FoldersRepository.instance;
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? get _trimmedName {
    final value = _nameController.text.trim();
    return value.isEmpty ? null : value;
  }

  bool get _canCreate => _trimmedName != null;

  Future<void> _create() async {
    final name = _trimmedName;
    if (name == null) {
      return;
    }

    final folder = await _repository.addFolder(name);
    if (mounted) {
      Navigator.of(context).pop(folder);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          hintText: 'Folder',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
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
  }
}
