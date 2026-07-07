import 'package:flutter/material.dart';

import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';

class DialogTitleField extends StatefulWidget {
  const DialogTitleField({
    super.key,
    required this.initialValue,
    required this.onSubmitted,
  });

  final String initialValue;
  final ValueChanged<String> onSubmitted;

  @override
  State<DialogTitleField> createState() => _DialogTitleFieldState();
}

class _DialogTitleFieldState extends State<DialogTitleField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(DialogTitleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColours.dark),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: AppTextStyles.alice(fontSize: 18),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: widget.onSubmitted,
            ),
          ),
          const Icon(Icons.edit_outlined, color: AppColours.dark, size: 18),
        ],
      ),
    );
  }
}
