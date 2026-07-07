import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colours.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle alice({
    double fontSize = 16,
    Color color = AppColours.dark,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return GoogleFonts.alice(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
    );
  }

  static TextStyle sourceSans({
    double fontSize = 12,
    Color color = AppColours.dark,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return GoogleFonts.sourceSans3(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
    );
  }
}
