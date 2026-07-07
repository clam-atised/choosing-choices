import 'package:flutter/material.dart';

import '../data/colour_templates_repository.dart';
import '../data/folders_repository.dart';
import '../screens/category_item_changes_screen.dart';
import '../theme/app_colours.dart';
import '../widgets/choices_drawer.dart';
import '../widgets/settings_dropdown.dart';
import '../widgets/settings_section.dart';
import '../widgets/shared_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FoldersRepository _foldersRepository = FoldersRepository.instance;

  List<String> _colourTemplateNames = const [];
  String? _selectedColourTemplate;
  String? _selectedCategoryOption;

  List<String> get _categoryDropdownItems => [
        'All',
        ..._foldersRepository.folderNames,
      ];

  @override
  void initState() {
    super.initState();
    _foldersRepository.addListener(_onFoldersChanged);
    _syncCategorySelection();
    _loadColourTemplates();
  }

  @override
  void dispose() {
    _foldersRepository.removeListener(_onFoldersChanged);
    super.dispose();
  }

  void _onFoldersChanged() {
    setState(_syncCategorySelection);
  }

  void _syncCategorySelection() {
    final folderNames = _foldersRepository.folderNames;
    if (_selectedCategoryOption != null &&
        _categoryDropdownItems.contains(_selectedCategoryOption)) {
      return;
    }

    _selectedCategoryOption =
        folderNames.isNotEmpty ? folderNames.first : 'All';
  }

  Future<void> _loadColourTemplates() async {
    final templates =
        await ColourTemplatesRepository.instance.loadTemplates();
    if (!mounted) {
      return;
    }
    setState(() {
      _colourTemplateNames = templates.map((template) => template.name).toList();
      _selectedColourTemplate = templates.first.name;
    });
  }

  void _onCategoryOptionSelected(String value) {
    setState(() => _selectedCategoryOption = value);

    final filter = value == 'All'
        ? const CategoryFilter.all()
        : CategoryFilter.folder(
            _foldersRepository.folderByName(value)!.id,
          );

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => CategoryItemChangesScreen(filter: filter),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _foldersRepository,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColours.dark,
          drawer: const ChoicesDrawer(),
          appBar: const SharedAppBar(title: 'Settings'),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsSection(
                  title: 'Category & Item Changes',
                  child: SettingsDropdown(
                    items: _categoryDropdownItems,
                    selectedValue: _selectedCategoryOption,
                    trailingIcon: Icons.play_arrow,
                    onChanged: _onCategoryOptionSelected,
                  ),
                ),
                const SizedBox(height: 24),
                SettingsSection(
                  title: 'Colour Template',
                  child: SettingsDropdown(
                    items: _colourTemplateNames,
                    selectedValue: _selectedColourTemplate,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
