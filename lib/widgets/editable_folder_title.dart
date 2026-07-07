import 'package:flutter/material.dart';

import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';

class EditableFolderTitle extends StatefulWidget {
  const EditableFolderTitle({super.key});

  @override
  State<EditableFolderTitle> createState() => _EditableFolderTitleState();
}

class _EditableFolderTitleState extends State<EditableFolderTitle> {
  final TextEditingController _controller =
      TextEditingController(text: 'Folder name');
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.edit_outlined, color: AppColours.dark, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: AppTextStyles.alice(fontSize: 18),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
