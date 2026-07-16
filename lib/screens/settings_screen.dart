import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/colour_templates_repository.dart';
import '../data/folders_repository.dart';
import '../models/backup_diff.dart';
import '../screens/category_item_changes_screen.dart';
import '../services/backup_service.dart';
import '../theme/app_colours.dart';
import '../widgets/backup_conflict_dialog.dart';
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
  int _backupDropdownKey = 0;

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
    final repository = ColourTemplatesRepository.instance;
    final templates = await repository.loadTemplates();
    if (!mounted) {
      return;
    }
    setState(() {
      _colourTemplateNames = templates.map((template) => template.name).toList();
      _selectedColourTemplate =
          repository.selectedTemplateName ?? templates.first.name;
    });
  }

  Future<void> _onColourTemplateSelected(String value) async {
    setState(() => _selectedColourTemplate = value);
    await ColourTemplatesRepository.instance.selectTemplateByName(value);
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

  Future<void> _onBackupOptionSelected(String value) async {
    setState(() => _backupDropdownKey++);

    if (kIsWeb) {
      _showMessage('Backup and load are not available on web.');
      return;
    }

    if (value == 'Backup data') {
      await _backupData();
    } else if (value == 'Load data') {
      await _loadData();
    }
  }

  Future<void> _backupData() async {
    try {
      final fileName = await BackupService.instance.exportBackup();
      if (!mounted) return;
      if (fileName != null) {
        _showMessage('Backup saved: $fileName');
      }
    } on BackupException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Failed to create backup');
    }
  }

  Future<void> _loadData() async {
    try {
      final backup = await BackupService.instance.pickAndImportBackup();
      if (backup == null || !mounted) return;

      final diff = BackupService.instance.diffAgainstDevice(backup: backup);
      var mode = BackupMergeMode.replace;

      if (diff.hasConflicts) {
        final chosen = await showBackupConflictDialog(
          context: context,
          diff: diff,
        );
        if (chosen == null || !mounted) return;
        mode = chosen;
      }

      await BackupService.instance.mergeBackup(backup: backup, mode: mode);
      if (!mounted) return;

      setState(() {
        _selectedColourTemplate =
            ColourTemplatesRepository.instance.selectedTemplateName ??
                _selectedColourTemplate;
      });
      _showMessage('Data loaded');
    } on BackupException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Failed to load data');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _foldersRepository,
        AppColours.instance,
      ]),
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
                    onChanged: _onColourTemplateSelected,
                  ),
                ),
                if (!kIsWeb) ...[
                  const SizedBox(height: 24),
                  SettingsSection(
                    title: 'Backup & Load',
                    child: SettingsDropdown(
                      key: ValueKey(_backupDropdownKey),
                      items: const ['Backup data', 'Load data'],
                      placeholder: 'Choose…',
                      onChanged: _onBackupOptionSelected,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
