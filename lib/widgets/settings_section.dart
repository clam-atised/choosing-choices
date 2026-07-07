import 'package:flutter/material.dart';

import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.alice(fontSize: 18, color: AppColours.white),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
