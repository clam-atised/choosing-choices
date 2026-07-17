import 'dart:io';

import 'package:flutter/material.dart';

Widget buildPlatformImage({
  required String path,
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  Widget? errorWidget,
}) {
  final fallback = errorWidget ?? const SizedBox.shrink();

  if (path.startsWith('assets/')) {
    return Image.asset(
      path,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, _, _) => fallback,
    );
  }

  return Image.file(
    File(path),
    fit: fit,
    width: width,
    height: height,
    errorBuilder: (_, _, _) => fallback,
  );
}

Widget buildCollapsiblePlatformImage({
  required String path,
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  double? aspectRatio,
  BorderRadius? borderRadius,
  double leadingSpacing = 0,
  double bottomSpacing = 0,
}) {
  Widget wrapSuccess(Widget child) {
    Widget result = child;
    if (aspectRatio != null) {
      result = AspectRatio(aspectRatio: aspectRatio, child: result);
    } else if (width != null || height != null) {
      result = SizedBox(width: width, height: height, child: result);
    }
    if (borderRadius != null) {
      result = ClipRRect(borderRadius: borderRadius, child: result);
    }
    if (leadingSpacing > 0 || bottomSpacing > 0) {
      result = Padding(
        padding: EdgeInsets.only(
          left: leadingSpacing,
          bottom: bottomSpacing,
        ),
        child: result,
      );
    }
    return result;
  }

  Widget frameBuilder(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    if (frame == null && !wasSynchronouslyLoaded) {
      return const SizedBox.shrink();
    }
    return wrapSuccess(child);
  }

  const error = SizedBox.shrink();
  final imageWidth = aspectRatio == null ? width : null;
  final imageHeight = aspectRatio == null ? height : null;

  if (path.startsWith('assets/')) {
    return Image.asset(
      path,
      fit: fit,
      width: imageWidth,
      height: imageHeight,
      frameBuilder: frameBuilder,
      errorBuilder: (_, _, _) => error,
    );
  }

  return Image.file(
    File(path),
    fit: fit,
    width: imageWidth,
    height: imageHeight,
    frameBuilder: frameBuilder,
    errorBuilder: (_, _, _) => error,
  );
}
