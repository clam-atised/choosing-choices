import 'package:flutter/material.dart';

import '../data/folders_repository.dart';
import '../models/choice_card.dart';
import '../models/folder_search_state.dart';
import '../services/card_search_service.dart';
import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';
import '../utils/card_date_utils.dart';
import '../utils/detail_field_formatters.dart';
import 'choices_dialog_shell.dart';
import 'selection_dropdown.dart';

Future<FolderSearchState?> showFolderSearchDialog(
  BuildContext context, {
  required String folderId,
  String? initialCategoryId,
  FolderSearchState? initialState,
}) {
  return showChoicesDialog<FolderSearchState>(
    context: context,
    scrollable: false,
    child: FolderSearchDialog(
      folderId: folderId,
      initialCategoryId: initialCategoryId,
      initialState: initialState,
    ),
  );
}

class FolderSearchDialog extends StatefulWidget {
  const FolderSearchDialog({
    super.key,
    required this.folderId,
    this.initialCategoryId,
    this.initialState,
  });

  final String folderId;
  final String? initialCategoryId;
  final FolderSearchState? initialState;

  @override
  State<FolderSearchDialog> createState() => _FolderSearchDialogState();
}

class _FolderSearchDialogState extends State<FolderSearchDialog> {
  final FoldersRepository _foldersRepository = FoldersRepository.instance;
  final CardSearchService _searchService = CardSearchService.instance;
  final TextEditingController _folderQueryController = TextEditingController();
  final Map<String, String> _detailQueries = {};
  final Map<String, bool> _dropdownExpanded = {};

  String? _selectedCategoryName;
  bool _isCategoryDropdownExpanded = false;
  bool _initialCategoryApplied = false;
  List<DetailSearchField> _detailFields = [];

  @override
  void initState() {
    super.initState();
    final initialState = widget.initialState;
    if (initialState != null) {
      _folderQueryController.text = initialState.folderQuery ?? '';
      _detailQueries.addAll(initialState.detailQueries);
    }
    _applyInitialCategory();
    _syncDetailFields();
  }

  @override
  void dispose() {
    _folderQueryController.dispose();
    super.dispose();
  }

  void _applyInitialCategory() {
    if (_initialCategoryApplied) {
      return;
    }

    final folder = _foldersRepository.folderById(widget.folderId);
    if (folder == null || folder.items.isEmpty) {
      return;
    }

    final initialState = widget.initialState;
    final initialCategoryId =
        initialState?.selectedCategoryId ?? widget.initialCategoryId;
    final item = initialCategoryId == null
        ? folder.items.first
        : folder.items.firstWhere(
            (entry) => entry.id == initialCategoryId,
            orElse: () => folder.items.first,
          );

    _selectedCategoryName = item.name;
    _initialCategoryApplied = true;
  }

  String? get _selectedCategoryId {
    final folder = _foldersRepository.folderById(widget.folderId);
    if (folder == null || _selectedCategoryName == null) {
      return null;
    }

    for (final item in folder.items) {
      if (item.name == _selectedCategoryName) {
        return item.id;
      }
    }
    return null;
  }

  void _syncDetailFields() {
    final categoryId = _selectedCategoryId;
    if (categoryId == null) {
      _detailFields = [];
      return;
    }

    final fields = _searchService.detailSearchFieldsForCategory(
      widget.folderId,
      categoryId,
    );
    final labels = fields.map((field) => field.label).toSet();
    _detailQueries.removeWhere((label, _) => !labels.contains(label));
    _dropdownExpanded.removeWhere((label, _) => !labels.contains(label));
    _detailFields = fields;
  }

  FolderSearchState _buildState() {
    return FolderSearchState(
      folderQuery: _folderQueryController.text.trim().isEmpty
          ? null
          : _folderQueryController.text.trim(),
      selectedCategoryId: _selectedCategoryId,
      detailQueries: {
        for (final entry in _detailQueries.entries)
          if (entry.value.trim().isNotEmpty) entry.key: entry.value.trim(),
      },
    );
  }

  void _onSearch() {
    Navigator.of(context).pop(_buildState());
  }

  void _onClear() {
    Navigator.of(context).pop(FolderSearchState.empty);
  }

  void _setDetailQuery(String label, String? value) {
    setState(() {
      if (value == null || value.trim().isEmpty) {
        _detailQueries.remove(label);
      } else {
        _detailQueries[label] = value.trim();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _foldersRepository,
      builder: (context, _) {
        final folder = _foldersRepository.folderById(widget.folderId);
        final categoryNames =
            folder?.items.map((item) => item.name).toList() ?? const <String>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SearchField(controller: _folderQueryController),
                    const SizedBox(height: 12),
                    SelectionDropdown(
                      options: categoryNames,
                      selectedValue: _selectedCategoryName,
                      placeholder: 'Category',
                      isExpanded: _isCategoryDropdownExpanded,
                      expandInPlace: true,
                      onToggle: () {
                        if (categoryNames.isEmpty) {
                          return;
                        }
                        setState(() {
                          _isCategoryDropdownExpanded =
                              !_isCategoryDropdownExpanded;
                          if (_isCategoryDropdownExpanded) {
                            _dropdownExpanded.updateAll((_, _) => false);
                          }
                        });
                      },
                      onSelect: (name) {
                        setState(() {
                          _selectedCategoryName = name;
                          _isCategoryDropdownExpanded = false;
                          _syncDetailFields();
                        });
                      },
                    ),
                    if (_detailFields.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Details:',
                        style: AppTextStyles.alice(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      for (final field in _detailFields) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DetailSearchControl(
                            field: field,
                            selectedValue: _detailQueries[field.label],
                            isDropdownExpanded:
                                _dropdownExpanded[field.label] ?? false,
                            onDropdownToggle: () {
                              setState(() {
                                final currentlyExpanded =
                                    _dropdownExpanded[field.label] ?? false;
                                _isCategoryDropdownExpanded = false;
                                _dropdownExpanded.updateAll((_, _) => false);
                                _dropdownExpanded[field.label] =
                                    !currentlyExpanded;
                              });
                            },
                            onChanged: (value) {
                              setState(() {
                                _dropdownExpanded[field.label] = false;
                              });
                              _setDetailQuery(field.label, value);
                            },
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _onClear,
                  child: Text(
                    'Clear',
                    style: AppTextStyles.alice(fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: _onSearch,
                  child: Text(
                    'Search',
                    style: AppTextStyles.alice(fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _DetailSearchControl extends StatelessWidget {
  const _DetailSearchControl({
    required this.field,
    required this.selectedValue,
    required this.isDropdownExpanded,
    required this.onDropdownToggle,
    required this.onChanged,
  });

  final DetailSearchField field;
  final String? selectedValue;
  final bool isDropdownExpanded;
  final VoidCallback onDropdownToggle;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${normalizeDetailLabel(field.label)}:',
          style: AppTextStyles.alice(fontSize: 16),
        ),
        const SizedBox(height: 8),
        switch (field.type) {
          DetailFieldType.yesNo => _YesNoSearchControl(
              selectedValue: selectedValue,
              onChanged: onChanged,
            ),
          DetailFieldType.text || DetailFieldType.dropdown => SelectionDropdown(
              options: field.options,
              selectedValue: selectedValue,
              placeholder: field.label,
              isExpanded: isDropdownExpanded,
              expandInPlace: true,
              onToggle: onDropdownToggle,
              onSelect: onChanged,
            ),
          DetailFieldType.time => _TimeSearchControl(
              selectedValue: selectedValue,
              onChanged: onChanged,
            ),
          DetailFieldType.days => _DaysSearchControl(
              selectedValue: selectedValue,
              onChanged: onChanged,
            ),
          DetailFieldType.date => _DateSearchControl(
              selectedValue: selectedValue,
              onChanged: onChanged,
            ),
        },
      ],
    );
  }
}

class _YesNoSearchControl extends StatelessWidget {
  const _YesNoSearchControl({
    required this.selectedValue,
    required this.onChanged,
  });

  final String? selectedValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = <bool>{};
    if (selectedValue == 'Yes') {
      selected.add(true);
    } else if (selectedValue == 'No') {
      selected.add(false);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<bool>(
        emptySelectionAllowed: true,
        multiSelectionEnabled: false,
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColours.dark),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColours.dark.withValues(alpha: 0.12);
            }
            return AppColours.light;
          }),
          side: WidgetStateProperty.all(
            BorderSide(color: AppColours.dark),
          ),
        ),
        segments: [
          ButtonSegment(
            value: false,
            label: Text(
              'No',
              style: AppTextStyles.alice(
                fontSize: 14,
                color: AppColours.dark,
              ),
            ),
          ),
          ButtonSegment(
            value: true,
            label: Text(
              'Yes',
              style: AppTextStyles.alice(
                fontSize: 14,
                color: AppColours.dark,
              ),
            ),
          ),
        ],
        selected: selected,
        onSelectionChanged: (selection) {
          if (selection.isEmpty) {
            onChanged(null);
            return;
          }
          onChanged(selection.first ? 'Yes' : 'No');
        },
      ),
    );
  }
}

class _TimeSearchControl extends StatelessWidget {
  const _TimeSearchControl({
    required this.selectedValue,
    required this.onChanged,
  });

  final String? selectedValue;
  final ValueChanged<String?> onChanged;

  String? get _from {
    final value = selectedValue?.trim() ?? '';
    if (value.isEmpty) {
      return null;
    }
    final parts = value.split(' – ');
    return parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : null;
  }

  String? get _to {
    final value = selectedValue?.trim() ?? '';
    if (value.isEmpty) {
      return null;
    }
    final parts = value.split(' – ');
    return parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
  }

  Future<void> _pickTime(
    BuildContext context, {
    required bool isFrom,
  }) async {
    final existing = isFrom ? _from : _to;
    final initial = _parseTime(existing) ?? TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) {
      return;
    }

    final formatted = _formatTime(picked);
    final from = isFrom ? formatted : _from;
    final to = isFrom ? _to : formatted;
    final display = detailFieldDisplayValue(
      CardDetailField(
        id: 'search_time',
        label: 'Time',
        type: DetailFieldType.time,
        timeFrom: from,
        timeTo: to,
      ),
    );
    onChanged(display.isEmpty ? null : display);
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null || !value.contains(':')) {
      return null;
    }
    final parts = value.split(':');
    if (parts.length != 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColours.dark,
              side: BorderSide(color: AppColours.dark),
            ),
            onPressed: () => _pickTime(context, isFrom: true),
            child: Text(
              _from ?? 'From',
              style: AppTextStyles.alice(
                fontSize: 14,
                color: AppColours.dark,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '–',
            style: AppTextStyles.alice(
              fontSize: 16,
              color: AppColours.dark,
            ),
          ),
        ),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColours.dark,
              side: BorderSide(color: AppColours.dark),
            ),
            onPressed: () => _pickTime(context, isFrom: false),
            child: Text(
              _to ?? 'To',
              style: AppTextStyles.alice(
                fontSize: 14,
                color: AppColours.dark,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DaysSearchControl extends StatelessWidget {
  const _DaysSearchControl({
    required this.selectedValue,
    required this.onChanged,
  });

  final String? selectedValue;
  final ValueChanged<String?> onChanged;

  List<bool> get _weekDays {
    final days = List<bool>.filled(7, false);
    final value = selectedValue?.trim() ?? '';
    if (value.isEmpty) {
      return days;
    }
    final selectedLabels = value.split(', ').map((part) => part.trim()).toSet();
    for (var index = 0; index < 7; index++) {
      days[index] = selectedLabels.contains(kWeekDayLabels[index]);
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = _weekDays;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (var index = 0; index < 7; index++)
          FilterChip(
            label: Text(
              kWeekDayLabels[index],
              style: AppTextStyles.alice(
                fontSize: 12,
                color: AppColours.dark,
              ),
            ),
            selected: weekDays[index],
            selectedColor: AppColours.dark.withValues(alpha: 0.2),
            checkmarkColor: AppColours.dark,
            backgroundColor: AppColours.light,
            side: BorderSide(color: AppColours.dark),
            onSelected: (selected) {
              final days = [...weekDays];
              days[index] = selected;
              final display = detailFieldDisplayValue(
                CardDetailField(
                  id: 'search_days',
                  label: 'Days',
                  type: DetailFieldType.days,
                  weekDays: days,
                ),
              );
              onChanged(display.isEmpty ? null : display);
            },
          ),
      ],
    );
  }
}

class _DateSearchControl extends StatefulWidget {
  const _DateSearchControl({
    required this.selectedValue,
    required this.onChanged,
  });

  final String? selectedValue;
  final ValueChanged<String?> onChanged;

  @override
  State<_DateSearchControl> createState() => _DateSearchControlState();
}

class _DateSearchControlState extends State<_DateSearchControl> {
  String? _fromIso;
  String? _toIso;

  @override
  void initState() {
    super.initState();
    _syncFromSelected(widget.selectedValue);
  }

  @override
  void didUpdateWidget(covariant _DateSearchControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedValue != widget.selectedValue) {
      _syncFromSelected(widget.selectedValue);
    }
  }

  void _syncFromSelected(String? selected) {
    if (selected == null || selected.trim().isEmpty) {
      _fromIso = null;
      _toIso = null;
      return;
    }
    // Best-effort: keep ISO from last picks; when restored from display only,
    // leave buttons showing From/To until user picks again.
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = parseIsoDate(isFrom ? _fromIso : _toIso) ??
        parseIsoDate(_fromIso) ??
        DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) {
      return;
    }

    final formatted = formatIsoDate(picked);
    setState(() {
      if (isFrom) {
        _fromIso = formatted;
        final to = parseIsoDate(_toIso);
        if (to != null && to.isBefore(dateOnly(picked))) {
          _toIso = formatted;
        }
      } else {
        _toIso = formatted;
        final from = parseIsoDate(_fromIso);
        if (from != null && dateOnly(picked).isBefore(from)) {
          _fromIso = formatted;
        } else {
          _fromIso ??= formatted;
        }
      }
    });

    final display = detailFieldDisplayValue(
      CardDetailField(
        id: 'search_date',
        label: 'Date',
        type: DetailFieldType.date,
        dateFrom: _fromIso,
        dateTo: _toIso,
      ),
    );
    widget.onChanged(display.isEmpty ? null : display);
  }

  @override
  Widget build(BuildContext context) {
    final fromLabel = _fromIso == null
        ? 'From'
        : detailFieldDisplayValue(
            CardDetailField(
              id: 'search_date_from',
              label: 'Date',
              type: DetailFieldType.date,
              dateFrom: _fromIso,
              dateTo: _fromIso,
            ),
          );
    final toLabel = _toIso == null
        ? 'To'
        : detailFieldDisplayValue(
            CardDetailField(
              id: 'search_date_to',
              label: 'Date',
              type: DetailFieldType.date,
              dateFrom: _toIso,
              dateTo: _toIso,
            ),
          );

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColours.dark,
              side: BorderSide(color: AppColours.dark),
            ),
            onPressed: () => _pickDate(isFrom: true),
            child: Text(
              fromLabel,
              style: AppTextStyles.alice(
                fontSize: 14,
                color: AppColours.dark,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '–',
            style: AppTextStyles.alice(
              fontSize: 16,
              color: AppColours.dark,
            ),
          ),
        ),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColours.dark,
              side: BorderSide(color: AppColours.dark),
            ),
            onPressed: () => _pickDate(isFrom: false),
            child: Text(
              toLabel,
              style: AppTextStyles.alice(
                fontSize: 14,
                color: AppColours.dark,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColours.dark),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTextStyles.alice(fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: AppTextStyles.alice(
                  fontSize: 18,
                  color: AppColours.dark.withValues(alpha: 0.6),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          Icon(Icons.search, color: AppColours.dark, size: 20),
        ],
      ),
    );
  }
}
