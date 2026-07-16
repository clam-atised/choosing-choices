import 'package:flutter/material.dart';

import '../models/category_item.dart';
import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';
import 'dashed_tree_connector.dart';
import 'folder_settings_dialog.dart';
import 'item_settings_dialog.dart';

class FolderSection extends StatelessWidget {
  const FolderSection({
    super.key,
    required this.folder,
    this.reorderIndex,
  });

  final Folder folder;
  final int? reorderIndex;

  static const double _iconSize = 22;
  static const double _itemHeight = 36;
  static const double _connectorWidth = 28;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildFolderIcon(),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => showFolderSettingsDialog(
                    context,
                    folderId: folder.id,
                  ),
                  child: Text(
                    folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.alice(
                      fontSize: 18,
                      color: AppColours.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (folder.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashedTreeConnector(
                    itemCount: folder.items.length,
                    itemHeight: _itemHeight,
                    connectorWidth: _connectorWidth,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        for (final item in folder.items)
                          SizedBox(
                            height: _itemHeight,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: GestureDetector(
                                onTap: () => showItemSettingsDialog(
                                  context,
                                  folderId: folder.id,
                                  itemId: item.id,
                                ),
                                child: Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.alice(
                                    fontSize: 18,
                                    color: AppColours.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFolderIcon() {
    const icon = Icon(
      Icons.folder,
      color: AppColours.white,
      size: _iconSize,
    );

    if (reorderIndex != null) {
      return ReorderableDelayedDragStartListener(
        index: reorderIndex!,
        child: icon,
      );
    }

    return icon;
  }
}
