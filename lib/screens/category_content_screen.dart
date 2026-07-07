import 'package:flutter/material.dart';

import '../data/folders_repository.dart';
import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';
import '../theme/layout_constants.dart';
import '../widgets/add_card_dialog.dart';
import '../widgets/category_card_carousel.dart';
import '../widgets/choices_drawer.dart';
import '../widgets/shared_app_bar.dart';

class CategoryContentScreen extends StatefulWidget {
  const CategoryContentScreen({
    super.key,
    required this.folderId,
    required this.itemId,
    this.openAddCardOnMount = false,
  });

  final String folderId;
  final String itemId;
  final bool openAddCardOnMount;

  @override
  State<CategoryContentScreen> createState() => _CategoryContentScreenState();
}

class _CategoryContentScreenState extends State<CategoryContentScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.openAddCardOnMount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        showAddCardDialog(
          context,
          folderId: widget.folderId,
          itemId: widget.itemId,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FoldersRepository.instance,
      builder: (context, _) {
        final folder = FoldersRepository.instance.folderById(widget.folderId);
        final item = FoldersRepository.instance.itemById(
          widget.folderId,
          widget.itemId,
        );

        if (folder == null || item == null) {
          return const Scaffold(
            body: Center(child: Text('Category not found')),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kCardHorizontalPadding,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.arrow_drop_down,
                          color: AppColours.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.name,
                          style: AppTextStyles.alice(
                            fontSize: 20,
                            color: AppColours.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: CategoryCardCarousel(
                      folderId: widget.folderId,
                      categoryItemId: widget.itemId,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
