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
  late final FocusNode _focusNode;
  late String _lastCommitted;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _lastCommitted = widget.initialValue.trim();
    _focusNode = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(DialogTitleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue;
      _lastCommitted = widget.initialValue.trim();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _commitIfChanged();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _commitIfChanged();
    }
  }

  void _commitIfChanged() {
    final value = _controller.text.trim();
    if (value.isEmpty || value == _lastCommitted) {
      return;
    }
    _lastCommitted = value;
    widget.onSubmitted(value);
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
              focusNode: _focusNode,
              style: AppTextStyles.alice(fontSize: 18),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              textInputAction: TextInputAction.done,
              onEditingComplete: _commitIfChanged,
              onSubmitted: (_) => _commitIfChanged(),
            ),
          ),
          Icon(Icons.edit_outlined, color: AppColours.dark, size: 18),
        ],
      ),
    );
  }
}
