import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colours.dart';
import '../theme/layout_constants.dart';

enum ImageCropMode {
  fullImage,
  fixedCrop,
}

class ImageCropPageResult {
  const ImageCropPageResult({required this.bytes});

  final Uint8List bytes;
}

Future<ImageCropPageResult?> showImageCropPage(
  BuildContext context, {
  required Uint8List imageBytes,
}) {
  return Navigator.of(context).push<ImageCropPageResult>(
    MaterialPageRoute(
      builder: (context) => ImageCropPage(imageBytes: imageBytes),
    ),
  );
}

class ImageCropPage extends StatefulWidget {
  const ImageCropPage({
    super.key,
    required this.imageBytes,
    this.debugImageCropper,
  });

  final Uint8List imageBytes;

  @visibleForTesting
  final ImageCropper? debugImageCropper;

  static const double cardAspectRatio = kCardPhotoWidth / kCardPhotoHeight;

  @override
  State<ImageCropPage> createState() => _ImageCropPageState();
}

class _ImageCropPageState extends State<ImageCropPage> {
  final CropController _cropController = CropController();

  ImageCropMode _mode = ImageCropMode.fullImage;
  bool _saving = false;
  CropStatus _cropStatus = CropStatus.nothing;

  bool get _canSave {
    if (_saving) {
      return false;
    }
    if (_mode == ImageCropMode.fixedCrop && _cropStatus != CropStatus.ready) {
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_canSave) {
      return;
    }

    if (_mode == ImageCropMode.fullImage) {
      Navigator.of(context).pop(
        ImageCropPageResult(bytes: widget.imageBytes),
      );
      return;
    }

    setState(() => _saving = true);
    _cropController.crop();
  }

  void _onCropped(CropResult result) {
    if (!mounted) {
      return;
    }

    switch (result) {
      case CropSuccess(:final croppedImage):
        Navigator.of(context).pop(
          ImageCropPageResult(bytes: croppedImage),
        );
      case CropFailure():
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not crop image. Please try again.'),
          ),
        );
    }
  }

  void _setMode(ImageCropMode mode) {
    if (_mode == mode || _saving) {
      return;
    }
    setState(() {
      _mode = mode;
      if (mode == ImageCropMode.fullImage) {
        _cropStatus = CropStatus.nothing;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColours.dark,
        foregroundColor: AppColours.white,
        title: const Text('Crop Image'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColours.white,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildEditor()),
          _buildModeToggle(),
          _buildHint(),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColours.white,
                side: const BorderSide(color: AppColours.white),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              key: const Key('image_crop_save'),
              onPressed: _canSave ? () => _save() : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColours.white,
                foregroundColor: AppColours.dark,
              ),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    if (_mode == ImageCropMode.fullImage) {
      return Center(
        key: const Key('image_crop_full_preview'),
        child: Image.memory(
          widget.imageBytes,
          fit: BoxFit.contain,
        ),
      );
    }

    return Crop(
      image: widget.imageBytes,
      controller: _cropController,
      aspectRatio: ImageCropPage.cardAspectRatio,
      interactive: true,
      fixCropRect: true,
      initialRectBuilder: InitialRectBuilder.withBuilder(_initialCropRect),
      overlayBuilder: (context, rect) => CustomPaint(
        painter: _DottedCropGridPainter(),
        size: Size(rect.width, rect.height),
      ),
      cornerDotBuilder: (_, _) => const SizedBox.shrink(),
      maskColor: Colors.black.withValues(alpha: 0.55),
      baseColor: Colors.black,
      onCropped: _onCropped,
      onStatusChanged: (status) {
        if (_cropStatus != status) {
          setState(() => _cropStatus = status);
        }
      },
      progressIndicator: const Center(
        child: CircularProgressIndicator(color: AppColours.white),
      ),
      imageCropper: widget.debugImageCropper ?? defaultImageCropper,
    );
  }

  Widget _buildModeToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SegmentedButton<ImageCropMode>(
        segments: const [
          ButtonSegment(
            value: ImageCropMode.fullImage,
            label: Text('Full image'),
          ),
          ButtonSegment(
            value: ImageCropMode.fixedCrop,
            label: Text('Crop 3:4'),
          ),
        ],
        selected: {_mode},
        onSelectionChanged: (selection) => _setMode(selection.first),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColours.white;
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColours.dark;
            }
            return AppColours.white;
          }),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColours.white),
          ),
        ),
      ),
    );
  }

  Widget _buildHint() {
    final text = _mode == ImageCropMode.fullImage
        ? 'The entire image will be saved.'
        : 'Drag to move the image. Pinch or scroll to zoom.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColours.white,
          fontSize: 13,
        ),
      ),
    );
  }

  Rect _initialCropRect(Rect viewportRect, Rect imageRect) {
    const aspectRatio = ImageCropPage.cardAspectRatio;
    final maxWidth = viewportRect.width;
    final maxHeight = viewportRect.height;

    late double width;
    late double height;
    if (maxWidth / maxHeight > aspectRatio) {
      height = maxHeight;
      width = height * aspectRatio;
    } else {
      width = maxWidth;
      height = width / aspectRatio;
    }

    final left = viewportRect.left + (maxWidth - width) / 2;
    final top = viewportRect.top + (maxHeight - height) / 2;
    return Rect.fromLTWH(left, top, width, height);
  }
}

class _DottedCropGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColours.white.withValues(alpha: 0.85)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;

    void drawDashedLine(Offset start, Offset end) {
      final distance = (end - start).distance;
      if (distance == 0) {
        return;
      }
      final direction = (end - start) / distance;
      var drawn = 0.0;
      while (drawn < distance) {
        final next = drawn + dashWidth;
        canvas.drawLine(
          start + direction * drawn,
          start + direction * (next > distance ? distance : next),
          paint,
        );
        drawn += dashWidth + dashSpace;
      }
    }

    for (var index = 1; index <= 2; index++) {
      final x = size.width * index / 3;
      drawDashedLine(Offset(x, 0), Offset(x, size.height));
      final y = size.height * index / 3;
      drawDashedLine(Offset(0, y), Offset(size.width, y));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
