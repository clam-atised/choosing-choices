import 'package:flutter/material.dart';

import '../data/folders_repository.dart';
import '../models/category_item.dart';
import '../theme/app_colours.dart';
import '../widgets/category_info_tutorial_dialog.dart';
import '../widgets/category_tree_view.dart';
import '../widgets/choices_drawer.dart';
import '../widgets/shared_app_bar.dart';

class CategoryFilter {
  const CategoryFilter.all() : folderId = null;

  const CategoryFilter.folder(this.folderId);

  final String? folderId;

  bool get isAll => folderId == null;
}

class CategoryItemChangesScreen extends StatefulWidget {
  const CategoryItemChangesScreen({
    super.key,
    required this.filter,
  });

  final CategoryFilter filter;

  @override
  State<CategoryItemChangesScreen> createState() =>
      _CategoryItemChangesScreenState();
}

class _CategoryItemChangesScreenState extends State<CategoryItemChangesScreen> {
  final FoldersRepository _repository = FoldersRepository.instance;

  List<Folder> get _visibleFolders {
    if (widget.filter.isAll) {
      return _repository.folders;
    }

    final folder = _repository.folderById(widget.filter.folderId!);
    if (folder == null) {
      return const [];
    }

    return [folder];
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    await _repository.reorderFolders(oldIndex, newIndex);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _repository,
        AppColours.instance,
      ]),
      builder: (context, _) {
        final folders = _visibleFolders;
        final enableReorder = widget.filter.isAll && folders.length > 1;

        return Scaffold(
          backgroundColor: AppColours.dark,
          drawer: const ChoicesDrawer(),
          appBar: SharedAppBar(
            title: 'Category & Item Changes',
            showInfoButton: true,
            onInfoPressed: () => showCategoryInfoTutorial(context),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: CategoryTreeView(
              folders: folders,
              enableReorder: enableReorder,
              onReorder: enableReorder ? _onReorder : null,
            ),
          ),
        );
      },
    );
  }
}
