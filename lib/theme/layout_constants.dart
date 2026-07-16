import 'dart:math' as math;

import 'package:flutter/material.dart';

const double kPhoneReferenceWidth = 390;
const double kCardHorizontalPadding = 20;
const double kDesktopCardWidth = 350;
const double kCardPhotoWidth = 110;
const double kCardPhotoHeight = 147;
const double kCardListMaxHeight = 200;
const double kCardListPhotoSize = 90;

bool isPhoneSize(BuildContext context) {
  return MediaQuery.sizeOf(context).width <= kPhoneReferenceWidth;
}

double cardPageWidth(BuildContext context) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  if (!isPhoneSize(context)) {
    return kDesktopCardWidth;
  }
  return math.min(
    screenWidth - kCardHorizontalPadding * 2,
    kPhoneReferenceWidth - kCardHorizontalPadding * 2,
  );
}

double cardMaxContentWidth(BuildContext context) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  if (!isPhoneSize(context)) {
    return screenWidth;
  }
  return math.min(screenWidth, kPhoneReferenceWidth);
}

Widget centerPhoneWidth({required Widget child}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth > kPhoneReferenceWidth) {
        return child;
      }

      return Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kPhoneReferenceWidth),
          child: child,
        ),
      );
    },
  );
}
