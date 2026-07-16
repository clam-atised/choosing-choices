import 'package:flutter/material.dart';

import '../theme/app_colours.dart';
import '../theme/app_text_styles.dart';

class SelectionDropdown extends StatefulWidget {
  const SelectionDropdown({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.placeholder,
    required this.isExpanded,
    required this.onToggle,
    required this.onSelect,
    this.expandInPlace = false,
  });

  final List<String> options;
  final String? selectedValue;
  final String placeholder;
  final bool isExpanded;
  final VoidCallback onToggle;
  final ValueChanged<String> onSelect;

  /// When true, expanded options grow the parent instead of overlaying.
  final bool expandInPlace;

  @override
  State<SelectionDropdown> createState() => _SelectionDropdownState();
}

class _SelectionDropdownState extends State<SelectionDropdown> {
  final LayerLink _layerLink = LayerLink();
  final OverlayPortalController _overlayController = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncOverlay());
  }

  @override
  void didUpdateWidget(covariant SelectionDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncOverlay());
  }

  @override
  void dispose() {
    if (_overlayController.isShowing) {
      _overlayController.hide();
    }
    super.dispose();
  }

  void _syncOverlay() {
    if (!mounted) {
      return;
    }

    final shouldShow =
        !widget.expandInPlace && widget.isExpanded && widget.options.isNotEmpty;
    if (shouldShow && !_overlayController.isShowing) {
      _overlayController.show();
    } else if (!shouldShow && _overlayController.isShowing) {
      _overlayController.hide();
    }
  }

  Widget _buildOptionsList({required bool shrinkWrap}) {
    final list = Material(
      color: AppColours.light,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(12),
        ),
        side: BorderSide(color: AppColours.dark),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final option in widget.options)
            InkWell(
              onTap: () => widget.onSelect(option),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(
                  option,
                  style: AppTextStyles.alice(
                    fontSize: 18,
                    color: AppColours.dark,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (!shrinkWrap) {
      return list;
    }

    // Overlay gives tight full-screen constraints; wrap so the menu only
    // sizes to the longest option and the last listed type.
    return Align(
      alignment: Alignment.topLeft,
      widthFactor: 1.0,
      heightFactor: 1.0,
      child: IntrinsicWidth(child: list),
    );
  }

  Widget _buildHeader({required bool isExpanded, required bool hasItems}) {
    final displayText = widget.selectedValue ?? widget.placeholder;

    return Material(
      color: AppColours.light,
      elevation: isExpanded ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: const Radius.circular(12),
          bottom: Radius.circular(isExpanded ? 0 : 12),
        ),
        side: BorderSide(color: AppColours.dark),
      ),
      child: InkWell(
        borderRadius: BorderRadius.vertical(
          top: const Radius.circular(12),
          bottom: Radius.circular(isExpanded ? 0 : 12),
        ),
        onTap: hasItems ? widget.onToggle : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  displayText,
                  style: AppTextStyles.alice(
                    fontSize: 18,
                    color: AppColours.dark,
                  ),
                ),
              ),
              Icon(
                isExpanded ? Icons.arrow_drop_down : Icons.play_arrow,
                color: AppColours.dark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasItems = widget.options.isNotEmpty;
    final isExpanded = widget.isExpanded && hasItems;
    final header = _buildHeader(isExpanded: isExpanded, hasItems: hasItems);

    if (widget.expandInPlace) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (isExpanded) _buildOptionsList(shrinkWrap: false),
        ],
      );
    }

    return OverlayPortal(
      controller: _overlayController,
      overlayChildBuilder: (context) {
        return CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, -1),
          child: _buildOptionsList(shrinkWrap: true),
        );
      },
      child: CompositedTransformTarget(
        link: _layerLink,
        child: header,
      ),
    );
  }
}
