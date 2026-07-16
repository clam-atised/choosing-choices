import 'package:flutter/material.dart';

class AppColours extends ChangeNotifier {
  AppColours._();

  static final AppColours instance = AppColours._();

  /// Pastel Red defaults (also used when a template field is null).
  static const Color defaultDark = Color(0xFFFF8585);
  static const Color defaultLight = Color(0xFFFFEDEF);
  static const Color defaultShadow = Color(0xFFFF3131);

  static const Color white = Color(0xFFFFFFFF);
  static const Color stamp = Color(0xFF45E500);

  Color _dark = defaultDark;
  Color _light = defaultLight;
  Color _shadow = defaultShadow;

  static Color get dark => instance._dark;
  static Color get light => instance._light;
  static Color get shadow => instance._shadow;

  void apply({
    required Color dark,
    required Color light,
    required Color shadow,
  }) {
    if (_dark == dark && _light == light && _shadow == shadow) {
      return;
    }
    _dark = dark;
    _light = light;
    _shadow = shadow;
    notifyListeners();
  }
}
