import 'dart:math' as math;

import 'package:flutter/material.dart';

const double kPhoneReferenceWidth = 390;
const double kCardHorizontalPadding = 20;

double cardPageWidth(BuildContext context) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  return math.min(
    screenWidth - kCardHorizontalPadding * 2,
    kPhoneReferenceWidth - kCardHorizontalPadding * 2,
  );
}

double cardMaxContentWidth(BuildContext context) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  return math.min(screenWidth, kPhoneReferenceWidth);
}

Widget centerPhoneWidth({required Widget child}) {
  return Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: kPhoneReferenceWidth),
      child: child,
    ),
  );
}
