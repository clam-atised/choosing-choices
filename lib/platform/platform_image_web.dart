import 'package:flutter/material.dart';

import '../theme/app_colours.dart';

Widget buildPlatformImage({
  required String path,
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  Widget? errorWidget,
}) {
  if (path.startsWith('assets/')) {
    return Image.asset(
      path,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, _, _) =>
          errorWidget ?? ColoredBox(color: AppColours.light),
    );
  }

  return Image.network(
    path,
    fit: fit,
    width: width,
    height: height,
    errorBuilder: (_, _, _) =>
        errorWidget ?? ColoredBox(color: AppColours.light),
  );
}
