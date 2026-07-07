import 'package:flutter/material.dart';

import '../data/folders_repository.dart';
import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';
import '../theme/layout_constants.dart';
import '../widgets/category_card_carousel.dart';
import '../widgets/choices_drawer.dart';
import '../widgets/shared_app_bar.dart';
import 'category_content_screen.dart';

class FolderContentScreen extends StatefulWidget {
  const FolderContentScreen({
    super.key,
    required this.folderId,
  });

  final String folderId;

  @override
  State<FolderContentScreen> createState() => _FolderContentScreenState();
}

class _FolderContentScreenState extends State<FolderContentScreen> {
  String? _expandedItemId;

  @override
  void initState() {
    super.initState();
    FoldersRepository.instance.addListener(_onFoldersChanged);
    _syncExpandedItem();
  }

  @override
  void dispose() {
    FoldersRepository.instance.removeListener(_onFoldersChanged);
    super.dispose();
  }

  void _onFoldersChanged() {
    _syncExpandedItem();
  }

  void _syncExpandedItem() {
    final folder = FoldersRepository.instance.folderById(widget.folderId);
    if (folder == null) {
      return;
    }

    if (_expandedItemId != null &&
        !folder.items.any((item) => item.id == _expandedItemId)) {
      final nextExpandedId =
          folder.items.isNotEmpty ? folder.items.first.id : null;
      if (nextExpandedId != _expandedItemId) {
        setState(() => _expandedItemId = nextExpandedId);
      }
    }
  }

  void _toggleExpanded(String itemId) {
    setState(() {
      _expandedItemId = _expandedItemId == itemId ? null : itemId;
    });
  }

  void _openCategory(BuildContext context, String itemId) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => CategoryContentScreen(
          folderId: widget.folderId,
          itemId: itemId,
          openAddCardOnMount: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FoldersRepository.instance,
      builder: (context, _) {
        final folder = FoldersRepository.instance.folderById(widget.folderId);
        if (folder == null) {
          return const Scaffold(
            body: Center(child: Text('Folder not found')),
          );
        }

        return Scaffold(
          backgroundColor: AppColours.dark,
          drawer: const ChoicesDrawer(),
          appBar: SharedAppBar(title: folder.name),
          body: centerPhoneWidth(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final item in folder.items) ...[
                    _CategorySectionHeader(
                      name: item.name,
                      isExpanded: _expandedItemId == item.id,
                      onToggle: () => _toggleExpanded(item.id),
                      onNavigate: () => _openCategory(context, item.id),
                    ),
                    if (_expandedItemId == item.id)
                      Expanded(
                        child: CategoryCardCarousel(
                          folderId: widget.folderId,
                          categoryItemId: item.id,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategorySectionHeader extends StatelessWidget {
  const _CategorySectionHeader({
    required this.name,
    required this.isExpanded,
    required this.onToggle,
    required this.onNavigate,
  });

  final String name;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kCardHorizontalPadding),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(right: 4, top: 4, bottom: 4),
              child: Icon(
                isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                color: AppColours.white,
                size: 28,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onNavigate,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  name,
                  style: AppTextStyles.alice(
                    fontSize: 20,
                    color: AppColours.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
