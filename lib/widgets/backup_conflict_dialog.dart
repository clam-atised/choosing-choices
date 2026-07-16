import 'package:flutter/material.dart';

import '../models/backup_diff.dart';
import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';
import 'choices_dialog_shell.dart';

Future<BackupMergeMode?> showBackupConflictDialog({
  required BuildContext context,
  required BackupDiff diff,
}) {
  return showChoicesDialog<BackupMergeMode>(
    context: context,
    child: _BackupConflictDialogBody(diff: diff),
  );
}

class _BackupConflictDialogBody extends StatelessWidget {
  const _BackupConflictDialogBody({required this.diff});

  final BackupDiff diff;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Data conflicts found',
          style: AppTextStyles.alice(fontSize: 22),
        ),
        const SizedBox(height: 12),
        Text(
          'Some categories or cards already exist on this device with different content. '
          'Retain keeps your current versions and still adds new items from the backup. '
          'Replace overwrites the conflicting items from the backup.',
          style: AppTextStyles.alice(fontSize: 15),
        ),
        if (diff.changedCategories.isNotEmpty) ...[
          const SizedBox(height: 20),
          const ChoicesDialogSectionLabel(label: 'Categories changed'),
          const SizedBox(height: 8),
          ...diff.changedCategories.map(_diffLine),
        ],
        if (diff.changedCards.isNotEmpty) ...[
          const SizedBox(height: 16),
          const ChoicesDialogSectionLabel(label: 'Cards changed'),
          const SizedBox(height: 8),
          ...diff.changedCards.map(_diffLine),
        ],
        if (diff.addedFolders.isNotEmpty ||
            diff.addedCategories.isNotEmpty ||
            diff.addedCards.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            _additionsSummary(diff),
            style: AppTextStyles.alice(
              fontSize: 14,
              color: AppColours.dark.withValues(alpha: 0.7),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: AppTextStyles.alice(fontSize: 16),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(BackupMergeMode.retain),
              child: Text(
                'Retain',
                style: AppTextStyles.alice(fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(BackupMergeMode.replace),
              child: Text(
                'Replace',
                style: AppTextStyles.alice(fontSize: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _diffLine(BackupDiffEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        '• ${entry.label}',
        style: AppTextStyles.alice(fontSize: 15),
      ),
    );
  }

  String _additionsSummary(BackupDiff diff) {
    final parts = <String>[];
    if (diff.addedFolders.isNotEmpty) {
      parts.add('${diff.addedFolders.length} new folder(s)');
    }
    if (diff.addedCategories.isNotEmpty) {
      parts.add('${diff.addedCategories.length} new categor${diff.addedCategories.length == 1 ? 'y' : 'ies'}');
    }
    if (diff.addedCards.isNotEmpty) {
      parts.add('${diff.addedCards.length} new card(s)');
    }
    return 'Also adding: ${parts.join(', ')}.';
  }
}
