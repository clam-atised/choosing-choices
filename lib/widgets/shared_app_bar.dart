import 'package:flutter/material.dart';

import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';
import 'editable_folder_title.dart';

class SharedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SharedAppBar({
    super.key,
    this.title,
    this.showFolderTitle = false,
    this.showAddButton = false,
    this.showInfoButton = false,
    this.onMenuPressed,
    this.onAddPressed,
    this.onInfoPressed,
  });

  final String? title;
  final bool showFolderTitle;
  final bool showAddButton;
  final bool showInfoButton;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onAddPressed;
  final VoidCallback? onInfoPressed;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColours.light,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Builder(
        builder: (scaffoldContext) => IconButton(
          icon: const Icon(Icons.menu, color: AppColours.dark),
          onPressed:
              onMenuPressed ?? () => Scaffold.of(scaffoldContext).openDrawer(),
        ),
      ),
      title: showFolderTitle
          ? const EditableFolderTitle()
          : title != null
              ? Text(
                  title!,
                  style: AppTextStyles.alice(fontSize: 20),
                )
              : null,
      centerTitle: !showFolderTitle,
      actions: [
        if (showInfoButton)
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColours.dark),
            onPressed: onInfoPressed,
          ),
        if (showAddButton)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: AppColours.dark,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onAddPressed,
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(Icons.add, color: AppColours.white, size: 22),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
