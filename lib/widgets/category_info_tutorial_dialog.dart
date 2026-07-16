import 'package:flutter/material.dart';

import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';

const _tutorialCardWidth = 320.0;
const _tutorialIllustrationHeight = 180.0;
const _tutorialCardRadius = 16.0;

const _tutorialStepAssets = [
  'assets/tutorial/tutorial_step_1.png',
  'assets/tutorial/tutorial_step_2.png',
  'assets/tutorial/tutorial_step_3.png',
];

const _tutorialSteps = [
  'Long press on folder icon to move folder arrangement',
  'Press on Folder name to change name, hide and export contents',
  'Press on Item name to change name, direction of content and export contents',
];

Future<void> showCategoryInfoTutorial(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColours.dark.withValues(alpha: 0.5),
    builder: (context) => const CategoryInfoTutorialDialog(),
  );
}

class CategoryInfoTutorialDialog extends StatefulWidget {
  const CategoryInfoTutorialDialog({super.key});

  static const cardWidth = _tutorialCardWidth;

  @override
  State<CategoryInfoTutorialDialog> createState() =>
      _CategoryInfoTutorialDialogState();
}

class _CategoryInfoTutorialDialogState extends State<CategoryInfoTutorialDialog> {
  int _currentPage = 0;
  bool _lastPageSeen = false;

  void _goBack() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
        _lastPageSeen = false;
      });
    }
  }

  void _advance() {
    if (_currentPage < 2) {
      setState(() => _currentPage++);
      return;
    }

    if (!_lastPageSeen) {
      setState(() => _lastPageSeen = true);
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: SizedBox(
          width: _tutorialCardWidth,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_tutorialCardRadius),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: _tutorialIllustrationHeight,
                  width: _tutorialCardWidth,
                  child: ColoredBox(
                    color: AppColours.dark,
                    child: _TutorialIllustration(page: _currentPage),
                  ),
                ),
                ColoredBox(
                  color: AppColours.light,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Column(
                      children: [
                        Text(
                          _tutorialSteps[_currentPage],
                          textAlign: TextAlign.center,
                          style: AppTextStyles.alice(
                            fontSize: 16,
                            color: AppColours.dark,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _TutorialNavigation(
                          currentPage: _currentPage,
                          onBack: _goBack,
                          onForward: _advance,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TutorialNavigation extends StatelessWidget {
  const _TutorialNavigation({
    required this.currentPage,
    required this.onBack,
    required this.onForward,
  });

  final int currentPage;
  final VoidCallback onBack;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    final canGoBack = currentPage > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: canGoBack ? onBack : null,
          icon: Icon(
            Icons.chevron_left,
            color: canGoBack
                ? AppColours.dark
                : AppColours.dark.withValues(alpha: 0.35),
          ),
        ),
        ...List.generate(3, (index) {
          final isActive = index == currentPage;
          return Container(
            width: isActive ? 10 : 8,
            height: isActive ? 10 : 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? AppColours.dark
                  : AppColours.dark.withValues(alpha: 0.35),
            ),
          );
        }),
        IconButton(
          onPressed: onForward,
          icon: Icon(Icons.chevron_right, color: AppColours.dark),
        ),
      ],
    );
  }
}

class _TutorialIllustration extends StatelessWidget {
  const _TutorialIllustration({required this.page});

  final int page;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _tutorialStepAssets[page],
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
    );
  }
}
