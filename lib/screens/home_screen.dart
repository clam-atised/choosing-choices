import 'package:flutter/material.dart';

import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';
import '../widgets/choices_drawer.dart';
import '../widgets/new_folder_item_dialog.dart';
import '../widgets/shared_app_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColours.dark,
      drawer: const ChoicesDrawer(),
      appBar: SharedAppBar(
        showFolderTitle: true,
        showAddButton: true,
        onAddPressed: () => showNewFolderItemDialog(context),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Press '+' to create\nyour first category",
              textAlign: TextAlign.center,
              style: AppTextStyles.alice(
                fontSize: 22,
                color: AppColours.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Choices by clam.atised',
              style: AppTextStyles.sourceSans(
                fontSize: 12,
                color: AppColours.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
