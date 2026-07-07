import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/colour_template.dart';
import '../theme/app_colours.dart';

class ColourTemplatesRepository {
  ColourTemplatesRepository._();

  static final ColourTemplatesRepository instance =
      ColourTemplatesRepository._();

  List<ColourTemplate>? _templates;

  Future<List<ColourTemplate>> loadTemplates() async {
    if (_templates != null) {
      return _templates!;
    }

    final jsonString =
        await rootBundle.loadString('assets/colours/colour_templates.json');
    final data = json.decode(jsonString) as Map<String, dynamic>;
    final templatesJson = data['templates'] as List<dynamic>;

    _templates = templatesJson
        .map((item) => ColourTemplate.fromJson(item as Map<String, dynamic>))
        .toList();

    return _templates!;
  }

  Future<Color> activeDarkColour() async {
    final templates = await loadTemplates();
    final active = templates.firstWhere(
      (template) => template.dark != null,
      orElse: () => templates.first,
    );
    return active.dark ?? AppColours.dark;
  }
}
