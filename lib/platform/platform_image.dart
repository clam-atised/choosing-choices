import 'package:flutter/material.dart';

import 'platform_image_io.dart'
    if (dart.library.html) 'platform_image_web.dart' as impl;

class PlatformImage extends StatelessWidget {
  const PlatformImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorWidget,
  });

  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    return impl.buildPlatformImage(
      path: path,
      fit: fit,
      width: width,
      height: height,
      errorWidget: errorWidget,
    );
  }
}

/// Shows [path] sized for success, or [SizedBox.shrink] if load fails.
class CollapsiblePlatformImage extends StatelessWidget {
  const CollapsiblePlatformImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.aspectRatio,
    this.borderRadius,
    this.leadingSpacing = 0,
    this.bottomSpacing = 0,
  });

  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double? aspectRatio;
  final BorderRadius? borderRadius;
  final double leadingSpacing;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    return impl.buildCollapsiblePlatformImage(
      path: path,
      fit: fit,
      width: width,
      height: height,
      aspectRatio: aspectRatio,
      borderRadius: borderRadius,
      leadingSpacing: leadingSpacing,
      bottomSpacing: bottomSpacing,
    );
  }
}
