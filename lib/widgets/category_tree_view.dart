import 'package:flutter/material.dart';

import '../models/category_item.dart';
import '../theme/app_colours.dart';
import 'folder_section.dart';

class CategoryTreeView extends StatelessWidget {
  const CategoryTreeView({
    super.key,
    required this.folders,
    required this.enableReorder,
    this.onReorder,
  });

  final List<Folder> folders;
  final bool enableReorder;
  final Future<void> Function(int oldIndex, int newIndex)? onReorder;

  @override
  Widget build(BuildContext context) {
    if (folders.isEmpty) {
      return const SizedBox.shrink();
    }

    if (!enableReorder || folders.length <= 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final folder in folders)
            FolderSection(
              key: ValueKey(folder.id),
              folder: folder,
            ),
        ],
      );
    }

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: folders.length,
      proxyDecorator: (child, index, animation) {
        return Material(
          color: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColours.light),
          ),
          child: child,
        );
      },
      onReorderItem: (oldIndex, newIndex) {
        onReorder!(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final folder = folders[index];
        return FolderSection(
          key: ValueKey(folder.id),
          folder: folder,
          reorderIndex: index,
        );
      },
    );
  }
}
