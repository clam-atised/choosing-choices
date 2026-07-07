import 'package:flutter/material.dart';

import '../data/colour_templates_repository.dart';
import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';

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

  @override
  State<CategoryInfoTutorialDialog> createState() =>
      _CategoryInfoTutorialDialogState();
}

class _CategoryInfoTutorialDialogState extends State<CategoryInfoTutorialDialog> {
  int _currentPage = 0;
  bool _lastPageSeen = false;
  Color _panelColour = AppColours.dark;

  @override
  void initState() {
    super.initState();
    _loadPanelColour();
  }

  Future<void> _loadPanelColour() async {
    final colour =
        await ColourTemplatesRepository.instance.activeDarkColour();
    if (mounted) {
      setState(() => _panelColour = colour);
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
    final width = MediaQuery.sizeOf(context).width * 0.85;

    return GestureDetector(
      onTap: _advance,
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: SizedBox(
            width: width,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: ColoredBox(
                      color: _panelColour,
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
                          _PageIndicator(currentPage: _currentPage),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.currentPage});

  final int currentPage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
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
    );
  }
}

class _TutorialIllustration extends StatelessWidget {
  const _TutorialIllustration({required this.page});

  final int page;

  @override
  Widget build(BuildContext context) {
    return switch (page) {
      0 => const _StepOneIllustration(),
      1 => const _StepTwoIllustration(),
      _ => const _StepThreeIllustration(),
    };
  }
}

class _StepOneIllustration extends StatelessWidget {
  const _StepOneIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 48,
          top: 36,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.folder, color: AppColours.white, size: 40),
                      const Positioned(
                        left: -14,
                        top: -10,
                        child: _SparkleLines(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const SizedBox(
                    width: 2,
                    height: 48,
                    child: CustomPaint(
                      painter: _DashedVerticalLinePainter(),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Fol',
                  style: AppTextStyles.alice(
                    fontSize: 36,
                    color: AppColours.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepTwoIllustration extends StatelessWidget {
  const _StepTwoIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.folder, color: AppColours.white, size: 36),
                const Positioned(
                  left: -12,
                  top: -8,
                  child: _SparkleLines(),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Text(
              'Folder',
              style: AppTextStyles.alice(
                fontSize: 40,
                color: AppColours.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepThreeIllustration extends StatelessWidget {
  const _StepThreeIllustration();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.folder, color: AppColours.white, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'Folder',
                    style: AppTextStyles.alice(
                      fontSize: 28,
                      color: AppColours.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 60,
                height: 36,
                child: CustomPaint(
                  painter: _DashedBranchPainter(),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 44),
                child: Text(
                  'Item',
                  style: AppTextStyles.alice(
                    fontSize: 28,
                    color: AppColours.white,
                  ),
                ),
              ),
              const Positioned(
                left: 40,
                top: 28,
                child: _SparkleLines(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SparkleLines extends StatelessWidget {
  const _SparkleLines();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _SparkleLinesPainter(),
      ),
    );
  }
}

class _SparkleLinesPainter extends CustomPainter {
  const _SparkleLinesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColours.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(size.width * 0.8, 0), Offset(0, size.height * 0.5), paint);
    canvas.drawLine(Offset(size.width, size.height * 0.3), Offset(size.width * 0.2, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.5, 0), Offset(size.width * 0.1, size.height * 0.7), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashedVerticalLinePainter extends CustomPainter {
  const _DashedVerticalLinePainter();

  static const double _dashLength = 4;
  static const double _dashGap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColours.white
      ..strokeWidth = 1;

    var y = 0.0;
    while (y < size.height) {
      final endY = (y + _dashLength).clamp(0.0, size.height);
      canvas.drawLine(Offset(size.width / 2, y), Offset(size.width / 2, endY), paint);
      y += _dashLength + _dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashedBranchPainter extends CustomPainter {
  const _DashedBranchPainter();

  static const double _dashLength = 4;
  static const double _dashGap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColours.white
      ..strokeWidth = 1;

    _drawDashedLine(
      canvas,
      paint,
      const Offset(10, 0),
      Offset(10, size.height * 0.55),
    );
    _drawDashedLine(
      canvas,
      paint,
      Offset(10, size.height * 0.55),
      Offset(size.width, size.height * 0.55),
    );
  }

  void _drawDashedLine(Canvas canvas, Paint paint, Offset start, Offset end) {
    final direction = end - start;
    final totalLength = direction.distance;
    if (totalLength == 0) {
      return;
    }

    final unit = direction / totalLength;
    var distance = 0.0;

    while (distance < totalLength) {
      final dashEnd = (distance + _dashLength).clamp(0.0, totalLength);
      canvas.drawLine(
        start + unit * distance,
        start + unit * dashEnd,
        paint,
      );
      distance += _dashLength + _dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
