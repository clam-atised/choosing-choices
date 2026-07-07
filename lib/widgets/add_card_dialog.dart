import 'package:flutter/material.dart';

import '../data/cards_repository.dart';
import '../models/choice_card.dart';
import '../platform/platform_image.dart';
import '../services/image_storage_service.dart';
import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';
import 'bordered_dialog_field.dart';
import 'card_detail_field_row.dart';
import 'choices_dialog_shell.dart';
import 'detail_type_picker_sheet.dart';

Future<void> showAddCardDialog(
  BuildContext context, {
  required String folderId,
  required String itemId,
  ChoiceCard? existingCard,
}) {
  return showChoicesDialog<void>(
    context: context,
    child: AddCardDialog(
      folderId: folderId,
      itemId: itemId,
      existingCard: existingCard,
    ),
  );
}

class AddCardDialog extends StatefulWidget {
  const AddCardDialog({
    super.key,
    required this.folderId,
    required this.itemId,
    this.existingCard,
  });

  final String folderId;
  final String itemId;
  final ChoiceCard? existingCard;

  bool get isEditing => existingCard != null;

  @override
  State<AddCardDialog> createState() => _AddCardDialogState();
}

class _AddCardDialogState extends State<AddCardDialog> {
  static const double _photoColumnWidth = 130;
  static const double _contentMinHeight = 280;

  late final TextEditingController _titleController;
  late final List<CardDetailField> _details;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    final existingCard = widget.existingCard;
    _titleController = TextEditingController(text: existingCard?.title ?? '');
    _details = existingCard == null
        ? []
        : existingCard.details
            .map(
              (detail) => detail.copyWith(
                dropdownOptions: [...detail.dropdownOptions],
              ),
            )
            .toList();
    _imagePath = existingCard?.imagePath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  bool get _canSaveCard => _titleController.text.trim().isNotEmpty;

  Future<void> _addDetail() async {
    final type = await showDetailTypePicker(context);
    if (type == null || !mounted) {
      return;
    }

    setState(() {
      _details.add(
        CardDetailField(
          id: 'detail_${DateTime.now().microsecondsSinceEpoch}',
          label: '',
          type: type,
          yesNoValue: type == DetailFieldType.yesNo ? false : null,
        ),
      );
    });
  }

  Future<void> _pickPhoto() async {
    final path = await ImageStorageService.instance.pickAndSaveImage(context);
    if (path != null && mounted) {
      setState(() => _imagePath = path);
    }
  }

  Future<void> _saveCard() async {
    if (!_canSaveCard) {
      return;
    }

    final details = _details
        .where((detail) => detail.label.trim().isNotEmpty)
        .toList();

    if (widget.isEditing) {
      final existingCard = widget.existingCard!;
      await CardsRepository.instance.updateCard(
        existingCard.copyWith(
          title: _titleController.text.trim(),
          details: details,
          imagePath: _imagePath,
        ),
      );
    } else {
      final card = ChoiceCard(
        id: 'card_${DateTime.now().microsecondsSinceEpoch}',
        folderId: widget.folderId,
        categoryItemId: widget.itemId,
        title: _titleController.text.trim(),
        details: details,
        imagePath: _imagePath,
      );

      await CardsRepository.instance.addCard(card);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailsMaxHeight = MediaQuery.sizeOf(context).height * 0.28;
    final saveLabel = widget.isEditing ? 'Save Card' : 'Add Card';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BorderedDialogField(
          controller: _titleController,
          hintText: 'Title',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: detailsMaxHeight,
                        minHeight: 80,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            for (var index = 0; index < _details.length; index++)
                              CardDetailFieldRow(
                                field: _details[index],
                                onChanged: (updated) {
                                  setState(() => _details[index] = updated);
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _addDetail,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: AppColours.dark,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: AppColours.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Add detail',
                              style: AppTextStyles.alice(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: _canSaveCard ? _saveCard : null,
                        child: Text(
                          saveLabel,
                          style: AppTextStyles.alice(
                            fontSize: 16,
                            color: _canSaveCard
                                ? AppColours.dark
                                : AppColours.dark.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: _photoColumnWidth,
                child: GestureDetector(
                  key: const Key('add_card_photo_picker'),
                  onTap: _pickPhoto,
                  child: CustomPaint(
                    painter: _DashedBorderPainter(
                      color: AppColours.dark,
                      borderRadius: 12,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: _contentMinHeight,
                      ),
                      child: _imagePath == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: AppColours.dark,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: AppColours.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add photo',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.alice(fontSize: 14),
                                ),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: PlatformImage(
                                path: _imagePath!,
                                width: _photoColumnWidth,
                                fit: BoxFit.cover,
                                errorWidget: const SizedBox(
                                  height: _contentMinHeight,
                                ),
                              ),
                            ),
                    ),
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

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
  });

  final Color color;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rect);
    const dashWidth = 5.0;
    const dashSpace = 4.0;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, end.clamp(0.0, metric.length)),
          paint,
        );
        distance = end + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => false;
}
