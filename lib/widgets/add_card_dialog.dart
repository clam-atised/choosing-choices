import 'package:flutter/material.dart';

import '../data/cards_repository.dart';
import '../data/folders_repository.dart';
import '../models/category_detail_definition.dart';
import '../models/choice_card.dart';
import '../platform/platform_image.dart';
import '../services/category_schema_service.dart';
import '../services/image_storage_service.dart';
import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';
import '../utils/card_date_utils.dart';
import 'bordered_dialog_field.dart';
import 'choices_dialog_shell.dart';
import 'dashed_border.dart';
import 'detail_setup_row.dart';
import 'detail_value_row.dart';
import 'selection_dropdown.dart';

Future<void> showAddCardDialog(
  BuildContext context, {
  required String folderId,
  String? initialItemId,
  ChoiceCard? existingCard,
}) {
  return showChoicesDialog<void>(
    context: context,
    child: AddCardDialog(
      folderId: folderId,
      initialItemId: initialItemId,
      existingCard: existingCard,
    ),
  );
}

class AddCardDialog extends StatefulWidget {
  const AddCardDialog({
    super.key,
    required this.folderId,
    this.initialItemId,
    this.existingCard,
  });

  final String folderId;
  final String? initialItemId;
  final ChoiceCard? existingCard;

  bool get isEditing => existingCard != null;

  @override
  State<AddCardDialog> createState() => _AddCardDialogState();
}

class _AddCardDialogState extends State<AddCardDialog> {
  static const double _photoColumnWidth = 130;
  static const double _contentMinHeight = 280;

  final FoldersRepository _foldersRepository = FoldersRepository.instance;
  final CategorySchemaService _schemaService = CategorySchemaService.instance;

  late final TextEditingController _titleController;
  final List<CardDetailField> _details = [];
  String? _imagePath;
  String? _selectedCategoryName;
  String? _selectedItemId;
  bool _isCategoryDropdownExpanded = false;
  bool _initialCategoryApplied = false;
  bool? _isSetupMode;
  bool _schemaLoaded = false;

  @override
  void initState() {
    super.initState();
    final existingCard = widget.existingCard;
    _titleController = TextEditingController(text: existingCard?.title ?? '');
    if (existingCard != null) {
      _details.addAll(
        existingCard.details.map(
          (detail) => detail.copyWith(
            dropdownOptions: [...detail.dropdownOptions],
            weekDays: [...detail.weekDays],
          ),
        ),
      );
    }
    _imagePath = existingCard?.imagePath;
    _selectedItemId = existingCard?.categoryItemId ?? widget.initialItemId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategorySchema());
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  bool get _canSaveCard {
    if (_titleController.text.trim().isEmpty) {
      return false;
    }
    if (widget.isEditing) {
      return true;
    }
    return _selectedItemId != null;
  }

  bool get _showSetupMode => !widget.isEditing && (_isSetupMode ?? true);

  void _applyInitialCategory(List<String> categoryNames) {
    if (_initialCategoryApplied || widget.isEditing) {
      return;
    }

    final folder = _foldersRepository.folderById(widget.folderId);
    if (folder == null || folder.items.isEmpty) {
      return;
    }

    final initialItem = _selectedItemId != null
        ? folder.items
            .where((item) => item.id == _selectedItemId)
            .cast<dynamic>()
            .firstOrNull
        : null;
    final item = initialItem ?? folder.items.first;
    _selectedItemId = item.id;
    _selectedCategoryName = item.name;
    _initialCategoryApplied = true;
  }

  void _syncSelectedCategory(List<String> categoryNames) {
    if (categoryNames.isEmpty) {
      _selectedCategoryName = null;
      _selectedItemId = null;
      return;
    }

    if (_selectedCategoryName != null &&
        categoryNames.contains(_selectedCategoryName)) {
      return;
    }

    final folder = _foldersRepository.folderById(widget.folderId);
    if (folder == null || folder.items.isEmpty) {
      return;
    }

    final item = folder.items.first;
    _selectedCategoryName = item.name;
    _selectedItemId = item.id;
  }

  Future<void> _loadCategorySchema() async {
    if (widget.isEditing) {
      final existing = widget.existingCard!;
      final definitions = await _schemaService.ensureSchemaForCategory(
        folderId: widget.folderId,
        categoryId: existing.categoryItemId,
      );
      if (!mounted) {
        return;
      }

      final synced = _schemaService.syncCardDetailsToSchema(
        existing,
        definitions,
      );
      setState(() {
        _schemaLoaded = true;
        _details
          ..clear()
          ..addAll(
            synced.details.map(
              (detail) => detail.copyWith(
                dropdownOptions: [...detail.dropdownOptions],
                weekDays: [...detail.weekDays],
              ),
            ),
          );
      });
      return;
    }

    if (_selectedItemId == null) {
      return;
    }

    final categoryId = _selectedItemId!;
    final isSetup = _schemaService.isCategorySetupMode(
      widget.folderId,
      categoryId,
    );

    if (isSetup) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSetupMode = true;
        _schemaLoaded = true;
        if (_details.isNotEmpty) {
          _details.clear();
        }
      });
      return;
    }

    final definitions = await _schemaService.ensureSchemaForCategory(
      folderId: widget.folderId,
      categoryId: categoryId,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _isSetupMode = false;
      _schemaLoaded = true;
      _details
        ..clear()
        ..addAll(_schemaService.emptyDetailsFromDefinitions(definitions));
    });
  }

  Future<void> _onCategoryChanged(String itemId, String itemName) async {
    setState(() {
      _selectedItemId = itemId;
      _selectedCategoryName = itemName;
      _isCategoryDropdownExpanded = false;
      _schemaLoaded = false;
      _details.clear();
    });
    await _loadCategorySchema();
  }

  void _addDetail() {
    setState(() {
      _details.add(
        CardDetailField(
          id: 'detail_${DateTime.now().microsecondsSinceEpoch}',
          label: '',
          type: DetailFieldType.text,
        ),
      );
    });
  }

  Future<void> _pickPhoto() async {
    final path = await ImageStorageService.instance.pickAndSaveImage(context);
    if (path != null && mounted) {
      setState(() => _imagePath = path);
    }
  }

  List<CardDetailField> _validDetails() {
    return _details.where((detail) => detail.label.trim().isNotEmpty).toList();
  }

  List<CategoryDetailDefinition> _buildDefinitions(List<CardDetailField> details) {
    return [
      for (final detail in details)
        CategoryDetailDefinition.fromCardDetail(detail),
    ];
  }

  Future<void> _persistDropdownOptions(List<CardDetailField> details) async {
    final categoryId = widget.isEditing
        ? widget.existingCard!.categoryItemId
        : _selectedItemId;
    if (categoryId == null) {
      return;
    }

    final item = _foldersRepository.itemById(widget.folderId, categoryId);
    if (item == null || item.detailDefinitions.isEmpty) {
      return;
    }

    final merged = _schemaService.mergeDropdownOptions(
      definitions: item.detailDefinitions,
      details: details,
    );
    await _foldersRepository.updateItemDetailDefinitions(
      widget.folderId,
      categoryId,
      merged,
    );
  }

  Future<void> _saveCard() async {
    if (!_canSaveCard) {
      return;
    }

    final details = _validDetails();

    if (widget.isEditing) {
      await _persistDropdownOptions(details);
      final previous = widget.existingCard!;
      var updated = previous.copyWith(
        title: _titleController.text.trim(),
        details: details,
        imagePath: _imagePath,
      );
      if (shouldReactivateOnDateUpdate(previous: previous, updated: updated)) {
        updated = updated.copyWith(isStamped: false);
      }
      await CardsRepository.instance.updateCard(updated);
    } else if (_showSetupMode) {
      final definitions = _buildDefinitions(details);
      await _foldersRepository.updateItemDetailDefinitions(
        widget.folderId,
        _selectedItemId!,
        definitions,
      );
      await CardsRepository.instance.addCard(
        ChoiceCard(
          id: 'card_${DateTime.now().microsecondsSinceEpoch}',
          folderId: widget.folderId,
          categoryItemId: _selectedItemId!,
          title: _titleController.text.trim(),
          details: details,
          imagePath: _imagePath,
        ),
      );
    } else {
      await _persistDropdownOptions(details);
      await CardsRepository.instance.addCard(
        ChoiceCard(
          id: 'card_${DateTime.now().microsecondsSinceEpoch}',
          folderId: widget.folderId,
          categoryItemId: _selectedItemId!,
          title: _titleController.text.trim(),
          details: details,
          imagePath: _imagePath,
        ),
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildAddDetailButton() {
    return InkWell(
      onTap: _addDetail,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColours.dark,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: AppColours.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Add detail',
              style: AppTextStyles.alice(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveCheckButton() {
    return Material(
      color: AppColours.dark,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _canSaveCard ? _saveCard : null,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    Icons.check,
                    key: const Key('add_card_save_check'),
            color: _canSaveCard
                ? AppColours.white
                : AppColours.white.withValues(alpha: 0.4),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColours.dark,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add,
              color: AppColours.white,
              size: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add photo',
            textAlign: TextAlign.center,
            style: AppTextStyles.alice(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPicker({required bool fullWidth}) {
    final width = fullWidth ? double.infinity : _photoColumnWidth;
    final minHeight = fullWidth ? 160.0 : _contentMinHeight;

    return GestureDetector(
      key: const Key('add_card_photo_picker'),
      onTap: _pickPhoto,
      child: DashedBorder(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: minHeight,
            minWidth: fullWidth ? double.infinity : _photoColumnWidth,
          ),
          child: SizedBox(
            width: width,
            child: _imagePath == null
                ? _buildPhotoEmptyState()
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: PlatformImage(
                      path: _imagePath!,
                      width: fullWidth ? double.infinity : _photoColumnWidth,
                      fit: BoxFit.cover,
                      errorWidget: SizedBox(
                        width: width,
                        height: minHeight,
                        child: _buildPhotoEmptyState(),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSetupCreateLayout() {
    return ListenableBuilder(
      listenable: _foldersRepository,
      builder: (context, _) {
        final folder = _foldersRepository.folderById(widget.folderId);
        final categoryNames = folder?.items.map((item) => item.name).toList() ??
            const <String>[];
        _applyInitialCategory(categoryNames);
        _syncSelectedCategory(categoryNames);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BorderedDialogField(
              controller: _titleController,
              hintText: 'Title',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < _details.length; index++)
              DetailSetupRow(
                field: _details[index],
                onChanged: (updated) {
                  setState(() => _details[index] = updated);
                },
              ),
            _buildAddDetailButton(),
            const SizedBox(height: 12),
            _buildPhotoPicker(fullWidth: true),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'in:',
                style: AppTextStyles.alice(fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
            SelectionDropdown(
              options: categoryNames,
              selectedValue: _selectedCategoryName,
              placeholder: 'Category',
              isExpanded: _isCategoryDropdownExpanded,
              onToggle: () {
                if (categoryNames.isEmpty) {
                  return;
                }
                setState(
                  () => _isCategoryDropdownExpanded = !_isCategoryDropdownExpanded,
                );
              },
              onSelect: (name) {
                final folderItems = folder?.items ?? const [];
                final item = folderItems.firstWhere(
                  (entry) => entry.name == name,
                );
                _onCategoryChanged(item.id, name);
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _canSaveCard ? _saveCard : null,
                child: Text(
                  'Create',
                  style: AppTextStyles.alice(
                    fontSize: 16,
                    color: _canSaveCard
                        ? AppColours.dark
                        : AppColours.dark.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHorizontalCreateLayout(BuildContext context) {
    final detailsMaxHeight = MediaQuery.sizeOf(context).height * 0.32;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: BorderedDialogField(
                controller: _titleController,
                hintText: 'Title',
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            _buildSaveCheckButton(),
          ],
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: detailsMaxHeight,
                    minHeight: 80,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (var index = 0; index < _details.length; index++)
                          DetailValueRow(
                            field: _details[index],
                            onChanged: (updated) {
                              setState(() => _details[index] = updated);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: _photoColumnWidth,
                child: _buildPhotoPicker(fullWidth: false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditLayout(BuildContext context) {
    final detailsMaxHeight = MediaQuery.sizeOf(context).height * 0.28;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BorderedDialogField(
          controller: _titleController,
          hintText: 'Title',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: detailsMaxHeight,
                        minHeight: 80,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            for (var index = 0; index < _details.length; index++)
                              DetailValueRow(
                                field: _details[index],
                                onChanged: (updated) {
                                  setState(() => _details[index] = updated);
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: _canSaveCard ? _saveCard : null,
                        child: Text(
                          'Save Card',
                          style: AppTextStyles.alice(
                            fontSize: 16,
                            color: _canSaveCard
                                ? AppColours.dark
                                : AppColours.dark.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: _photoColumnWidth,
                child: _buildPhotoPicker(fullWidth: false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing) {
      return _buildEditLayout(context);
    }

    if (!_schemaLoaded) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_showSetupMode) {
      return _buildSetupCreateLayout();
    }
    return _buildHorizontalCreateLayout(context);
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) {
      return null;
    }
    return iterator.current;
  }
}
