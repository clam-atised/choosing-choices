import 'package:flutter/material.dart';

class ColourTemplate {
  const ColourTemplate({
    required this.id,
    required this.name,
    this.dark,
    this.light,
    this.shadow,
  });

  final String id;
  final String name;
  final Color? dark;
  final Color? light;
  final Color? shadow;

  factory ColourTemplate.fromJson(Map<String, dynamic> json) {
    return ColourTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      dark: _parseColor(json['dark']),
      light: _parseColor(json['light']),
      shadow: _parseColor(json['shadow']),
    );
  }

  static Color? _parseColor(dynamic value) {
    if (value == null) {
      return null;
    }
    final hex = value as String;
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }
}
