import 'package:flutter/material.dart';

import '../theme/app_colours.dart';

class DashedTreeConnector extends StatelessWidget {
  const DashedTreeConnector({
    super.key,
    required this.itemCount,
    this.itemHeight = 36,
    this.connectorWidth = 28,
  });

  final int itemCount;
  final double itemHeight;
  final double connectorWidth;

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      size: Size(connectorWidth, itemCount * itemHeight),
      painter: _DashedTreeConnectorPainter(
        itemCount: itemCount,
        itemHeight: itemHeight,
        connectorWidth: connectorWidth,
      ),
    );
  }
}

class _DashedTreeConnectorPainter extends CustomPainter {
  _DashedTreeConnectorPainter({
    required this.itemCount,
    required this.itemHeight,
    required this.connectorWidth,
  });

  final int itemCount;
  final double itemHeight;
  final double connectorWidth;

  static const double _dashLength = 4;
  static const double _dashGap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColours.white
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final verticalX = connectorWidth * 0.35;
    final verticalEnd = itemCount * itemHeight - itemHeight / 2;

    _drawDashedLine(
      canvas,
      paint,
      Offset(verticalX, 0),
      Offset(verticalX, verticalEnd),
    );

    for (var index = 0; index < itemCount; index++) {
      final y = index * itemHeight + itemHeight / 2;
      _drawDashedLine(
        canvas,
        paint,
        Offset(verticalX, y),
        Offset(connectorWidth, y),
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Paint paint, Offset start, Offset end) {
    final totalLength = (end - start).distance;
    if (totalLength == 0) {
      return;
    }

    final direction = (end - start) / totalLength;
    var distance = 0.0;

    while (distance < totalLength) {
      final dashEnd = distance + _dashLength;
      final segmentEnd = dashEnd.clamp(0.0, totalLength);
      canvas.drawLine(
        start + direction * distance,
        start + direction * segmentEnd,
        paint,
      );
      distance = dashEnd + _dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedTreeConnectorPainter oldDelegate) {
    return oldDelegate.itemCount != itemCount ||
        oldDelegate.itemHeight != itemHeight ||
        oldDelegate.connectorWidth != connectorWidth;
  }
}
