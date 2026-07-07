import 'package:flutter/material.dart';

import '../data/folders_repository.dart';
import '../screens/folder_content_screen.dart';
import '../screens/settings_screen.dart';
import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';

class ChoicesDrawer extends StatelessWidget {
  const ChoicesDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final drawerWidth = MediaQuery.sizeOf(context).width * 0.65;

    return Drawer(
      width: drawerWidth,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColours.light,
          boxShadow: const [
            BoxShadow(
              color: AppColours.shadow,
              blurRadius: 12,
              offset: Offset(4, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListenableBuilder(
              listenable: FoldersRepository.instance,
              builder: (context, _) {
                final folders = FoldersRepository.instance.folders;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Choices,\nchoices,\nchoices',
                                style: AppTextStyles.alice(fontSize: 22),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'by clam.atised',
                                style: AppTextStyles.sourceSans(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.settings,
                            color: AppColours.dark,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    for (final folder in folders)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: folder.isHidden
                                    ? null
                                    : () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute<void>(
                                            builder: (context) =>
                                                FolderContentScreen(
                                              folderId: folder.id,
                                            ),
                                          ),
                                        );
                                      },
                                child: Text(
                                  folder.name,
                                  style: AppTextStyles.alice(fontSize: 20),
                                ),
                              ),
                            ),
                            if (folder.isHidden)
                              const Icon(
                                Icons.visibility_off,
                                color: AppColours.dark,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: IconButton(
                        icon: const Icon(
                          Icons.keyboard_double_arrow_left,
                          color: AppColours.dark,
                          size: 28,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
