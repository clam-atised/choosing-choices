import 'package:flutter/material.dart';

import '../data/folders_repository.dart';
import '../models/category_detail_definition.dart';
import '../models/choice_card.dart';
import '../services/category_schema_service.dart';
import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';
import 'dashed_border.dart';
import 'selection_dropdown.dart';

class CategoryCardSchemaEditor extends StatefulWidget {
  const CategoryCardSchemaEditor({
    super.key,
    required this.folderId,
    required this.itemId,
  });

  final String folderId;
  final String itemId;

  @override
  State<CategoryCardSchemaEditor> createState() =>
      _CategoryCardSchemaEditorState();
}

class _CategoryCardSchemaEditorState extends State<CategoryCardSchemaEditor> {
  final FoldersRepository _foldersRepository = FoldersRepository.instance;
  final CategorySchemaService _schemaService = CategorySchemaService.instance;

  final TextEditingController _newLabelController = TextEditingController();
  final TextEditingController _optionAddController = TextEditingController();
  DetailFieldType _newType = DetailFieldType.text;
  bool _newTypeExpanded = false;
  String? _expandedDropdownId;

  @override
  void dispose() {
    _newLabelController.dispose();
    _optionAddController.dispose();
    super.dispose();
  }

  List<CategoryDetailDefinition> get _definitions {
    return _foldersRepository
            .itemById(widget.folderId, widget.itemId)
            ?.detailDefinitions ??
        const [];
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    final definitions = [..._definitions];
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = definitions.removeAt(oldIndex);
    definitions.insert(newIndex, item);
    await _schemaService.reorderDefinitions(
      folderId: widget.folderId,
      itemId: widget.itemId,
      definitions: definitions,
    );
  }

  Future<void> _rename(String definitionId, String label) async {
    await _schemaService.renameDefinition(
      folderId: widget.folderId,
      itemId: widget.itemId,
      definitionId: definitionId,
      label: label.trim(),
    );
  }

  Future<void> _confirmDelete(CategoryDetailDefinition definition) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColours.light,
          title: Text(
            'Delete forever?',
            style: AppTextStyles.alice(fontSize: 20),
          ),
          content: Text(
            'This removes the label and all data under it from every card in this category.',
            style: AppTextStyles.alice(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: AppTextStyles.alice(fontSize: 16)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete', style: AppTextStyles.alice(fontSize: 16)),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    await _schemaService.deleteDefinition(
      folderId: widget.folderId,
      itemId: widget.itemId,
      definitionId: definition.id,
    );
  }

  Future<void> _addOption(CategoryDetailDefinition definition) async {
    final value = _optionAddController.text.trim();
    if (value.isEmpty) {
      return;
    }
    if (definition.dropdownOptions.contains(value)) {
      _optionAddController.clear();
      return;
    }

    await _schemaService.setDropdownOptions(
      folderId: widget.folderId,
      itemId: widget.itemId,
      definitionId: definition.id,
      options: [...definition.dropdownOptions, value],
    );
    _optionAddController.clear();
  }

  Future<void> _removeOption(
    CategoryDetailDefinition definition,
    String option,
  ) async {
    await _schemaService.setDropdownOptions(
      folderId: widget.folderId,
      itemId: widget.itemId,
      definitionId: definition.id,
      options: [
        for (final existing in definition.dropdownOptions)
          if (existing != option) existing,
      ],
    );
  }

  Future<void> _addDetail() async {
    final label = _newLabelController.text.trim();
    if (label.isEmpty) {
      return;
    }

    final definition = CategoryDetailDefinition(
      id: 'detail_${DateTime.now().microsecondsSinceEpoch}',
      label: label,
      type: _newType,
      dropdownOptions: const [],
    );

    await _schemaService.addDefinition(
      folderId: widget.folderId,
      itemId: widget.itemId,
      definition: definition,
    );

    _newLabelController.clear();
    setState(() {
      _newType = DetailFieldType.text;
      _newTypeExpanded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _foldersRepository,
      builder: (context, _) {
        final definitions = _definitions;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (definitions.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'No details yet. Add one below.',
                  style: AppTextStyles.alice(
                    fontSize: 14,
                    color: AppColours.dark.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: definitions.length,
              onReorder: _onReorder,
              itemBuilder: (context, index) {
                final definition = definitions[index];
                return _SchemaDefinitionTile(
                  key: ValueKey(definition.id),
                  definition: definition,
                  index: index,
                  optionsExpanded: _expandedDropdownId == definition.id,
                  optionAddController: _optionAddController,
                  onToggleOptions: () {
                    setState(() {
                      _expandedDropdownId =
                          _expandedDropdownId == definition.id
                              ? null
                              : definition.id;
                    });
                  },
                  onLabelSubmitted: (label) => _rename(definition.id, label),
                  onDelete: () => _confirmDelete(definition),
                  onAddOption: () => _addOption(definition),
                  onRemoveOption: (option) => _removeOption(definition, option),
                );
              },
            ),
            const SizedBox(height: 8),
            _AddDetailRow(
              labelController: _newLabelController,
              type: _newType,
              typeExpanded: _newTypeExpanded,
              onTypeToggle: () {
                setState(() => _newTypeExpanded = !_newTypeExpanded);
              },
              onTypeSelected: (displayLabel) {
                setState(() {
                  _newType = DetailFieldType.fromDisplayLabel(displayLabel);
                  _newTypeExpanded = false;
                });
              },
              onAdd: _addDetail,
            ),
          ],
        );
      },
    );
  }
}

class _SchemaDefinitionTile extends StatefulWidget {
  const _SchemaDefinitionTile({
    super.key,
    required this.definition,
    required this.index,
    required this.optionsExpanded,
    required this.optionAddController,
    required this.onToggleOptions,
    required this.onLabelSubmitted,
    required this.onDelete,
    required this.onAddOption,
    required this.onRemoveOption,
  });

  final CategoryDetailDefinition definition;
  final int index;
  final bool optionsExpanded;
  final TextEditingController optionAddController;
  final VoidCallback onToggleOptions;
  final ValueChanged<String> onLabelSubmitted;
  final VoidCallback onDelete;
  final VoidCallback onAddOption;
  final ValueChanged<String> onRemoveOption;

  @override
  State<_SchemaDefinitionTile> createState() => _SchemaDefinitionTileState();
}

class _SchemaDefinitionTileState extends State<_SchemaDefinitionTile> {
  late final TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.definition.label);
  }

  @override
  void didUpdateWidget(covariant _SchemaDefinitionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.definition.label != widget.definition.label &&
        _labelController.text != widget.definition.label) {
      _labelController.text = widget.definition.label;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final definition = widget.definition;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DashedBorder(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: widget.index,
                  child: Icon(Icons.drag_handle, color: AppColours.dark),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _labelController,
                    decoration: InputDecoration(
                      hintText: 'Label',
                      hintStyle: AppTextStyles.alice(
                        fontSize: 16,
                        color: AppColours.dark.withValues(alpha: 0.6),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: AppTextStyles.alice(fontSize: 16),
                    onSubmitted: widget.onLabelSubmitted,
                    onEditingComplete: () =>
                        widget.onLabelSubmitted(_labelController.text),
                  ),
                ),
                Text(
                  definition.type.displayLabel,
                  style: AppTextStyles.alice(
                    fontSize: 14,
                    color: AppColours.dark.withValues(alpha: 0.8),
                  ),
                ),
                IconButton(
                  tooltip: 'Delete detail',
                  icon: Icon(Icons.delete_outline, color: AppColours.dark),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            if (definition.type == DetailFieldType.dropdown) ...[
              const SizedBox(height: 4),
              InkWell(
                onTap: widget.onToggleOptions,
                child: Row(
                  children: [
                    Text(
                      'Options (${definition.dropdownOptions.length})',
                      style: AppTextStyles.alice(fontSize: 14),
                    ),
                    Icon(
                      widget.optionsExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: AppColours.dark,
                    ),
                  ],
                ),
              ),
              if (widget.optionsExpanded) ...[
                const SizedBox(height: 8),
                for (final option in definition.dropdownOptions)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          style: AppTextStyles.alice(fontSize: 14),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove option',
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: AppColours.dark,
                          size: 20,
                        ),
                        onPressed: () => widget.onRemoveOption(option),
                      ),
                    ],
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.optionAddController,
                        decoration: InputDecoration(
                          hintText: 'Add data',
                          hintStyle: AppTextStyles.alice(
                            fontSize: 14,
                            color: AppColours.dark.withValues(alpha: 0.6),
                          ),
                          isDense: true,
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColours.dark),
                          ),
                        ),
                        style: AppTextStyles.alice(
                          fontSize: 14,
                          color: AppColours.dark,
                        ),
                        onSubmitted: (_) => widget.onAddOption(),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Add data',
                      icon: Icon(Icons.add, color: AppColours.dark),
                      onPressed: widget.onAddOption,
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _AddDetailRow extends StatelessWidget {
  const _AddDetailRow({
    required this.labelController,
    required this.type,
    required this.typeExpanded,
    required this.onTypeToggle,
    required this.onTypeSelected,
    required this.onAdd,
  });

  final TextEditingController labelController;
  final DetailFieldType type;
  final bool typeExpanded;
  final VoidCallback onTypeToggle;
  final ValueChanged<String> onTypeSelected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return DashedBorder(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add detail',
            style: AppTextStyles.alice(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: labelController,
                  decoration: InputDecoration(
                    hintText: 'Type detail',
                    hintStyle: AppTextStyles.alice(
                      fontSize: 16,
                      color: AppColours.dark.withValues(alpha: 0.6),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: AppTextStyles.alice(fontSize: 16),
                ),
              ),
              Container(
                width: 1,
                height: 28,
                color: AppColours.dark.withValues(alpha: 0.3),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              SizedBox(
                width: 110,
                child: SelectionDropdown(
                  options: DetailFieldType.displayLabels,
                  selectedValue: type.displayLabel,
                  placeholder: 'Type',
                  isExpanded: typeExpanded,
                  expandInPlace: true,
                  onToggle: onTypeToggle,
                  onSelect: onTypeSelected,
                ),
              ),
              IconButton(
                key: const Key('schema_add_detail_button'),
                tooltip: 'Add detail',
                icon: Icon(Icons.add_circle_outline, color: AppColours.dark),
                onPressed: onAdd,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
