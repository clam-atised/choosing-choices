import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/colour_template.dart';
import '../theme/app_colours.dart';

class ColourTemplatesRepository {
  ColourTemplatesRepository._();

  static final ColourTemplatesRepository instance =
      ColourTemplatesRepository._();

  List<ColourTemplate>? _templates;
  String? _selectedTemplateName;

  String? get selectedTemplateName => _selectedTemplateName;

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

    _selectedTemplateName ??=
        _templates!.isNotEmpty ? _templates!.first.name : null;

    return _templates!;
  }

  Future<void> selectTemplateByName(String name) async {
    final templates = await loadTemplates();
    final template = templates.firstWhere(
      (item) => item.name == name,
      orElse: () => templates.first,
    );

    _selectedTemplateName = template.name;
    AppColours.instance.apply(
      dark: template.dark ?? AppColours.defaultDark,
      light: template.light ?? AppColours.defaultLight,
      shadow: template.shadow ?? AppColours.defaultShadow,
    );
  }

  Future<Color> activeDarkColour() async {
    final templates = await loadTemplates();
    final selectedName = _selectedTemplateName;
    final active = selectedName == null
        ? templates.first
        : templates.firstWhere(
            (template) => template.name == selectedName,
            orElse: () => templates.first,
          );
    return active.dark ?? AppColours.dark;
  }
}
