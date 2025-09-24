import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/functions.dart';


/// A wheel whose selected item is fully opaque and every other item is faded out.
class WheelPicker extends StatefulWidget {
  /// Total number of items in the wheel.
  final int childCount;
  /// Builder called for every visible item. The second parameter is true when the item is currently selected.
  final Widget Function(int index) child;
  /// Callback fired whenever the wheel settles on a new index.
  final ValueChanged<int>? onSelectedItemChanged;
  /// External controller if you need to read or drive the scroll position (must be a FixedExtentScrollController).
  final ScrollController? controller;
  /// Height of each item in logical pixels. This is the fixed extent passed to ListWheelScrollView.
  final double itemExtent;
  /// 3-D perspective factor used by ListWheelScrollView. Smaller values = deeper vanishing point.
  final double perspective;
  /// Ratio of the wheel’s diameter to its visible height. Larger values = flatter wheel.
  final double diameterRatio;
  /// If supplied, the entire wheel is forced to this height via SizedBox. If omitted, the wheel 
  /// expands to the constraints given by its parent.
  final double? wheelHeight;
  /// If supplied, the entire wheel is forced to this width via SizedBox. If omitted, the wheel 
  /// expands to the constraints given by its parent.
  final double? wheelWidth;
  /// The initial index to show in the wheel. Ignored if the controller already has an initial item.
  final int initialIndex;
  /// Optional function to provide a text style based on whether the item is selected.
  /// If it is provided, it overrides selectedItemColor and unselectedItemColor properties.
  final TextStyle Function(bool isSelected)? textStyle;
  /// Color of the selected item. If null, defaults to theme's primaryColor.
  /// Ignored if textStyle is provided.
  /// If themeAware is true, this color is white in dark mode and primaryColor in light mode.
  /// If themeAware is false, this color is always primaryColor.
  final Color? selectedItemColor;
  /// Color of unselected items. If null, defaults to theme's hintColor.
  /// Ignored if textStyle is provided.
  /// If themeAware is true, this color is white in dark mode and black in light mode.
  /// If themeAware is false, this color is always hintColor.
  final Color? unselectedItemColor;
  /// If true (the default), selectedItemColor and unselectedItemColor adapt to dark/light mode.
  final bool themeAware;
  /* -------------------------------------------------------------------------------------- */
  const WheelPicker({
    super.key,
    required this.child,
    required this.childCount,
    this.onSelectedItemChanged,
    this.controller,
    this.itemExtent = 34,
    this.perspective = 0.005,
    this.diameterRatio = 1.2, 
    this.wheelHeight, 
    this.wheelWidth,
    this.initialIndex = 0, 
    this.selectedItemColor, 
    this.unselectedItemColor, 
    this.themeAware = true, 
    this.textStyle, 
  });
  /* -------------------------------------------------------------------------------------- */
  @override
  State<WheelPicker> createState() => _WheelPickerState();
}

/* ============================================================================================= */

class _WheelPickerState extends State<WheelPicker> {
  late int _centerIndex;
  /* -------------------------------------------------------------------------------------- */
  @override
  void initState() {
    super.initState();
    _centerIndex = widget.initialIndex; // start with provided index
    // sync with controller if it already has an initial item
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = widget.controller;
      if (ctrl is FixedExtentScrollController) {
        try {
          final i = ctrl.selectedItem;
          if (i != _centerIndex) setState(() => _centerIndex = i);
        } catch (_) {
          // When a controller is temporarily attached to multiple views,
          // reading selectedItem can throw. Fall back safely.
        }
      }
    });
  }
  /* -------------------------------------------------------------------------------------- */
  @override
  void didUpdateWidget(covariant WheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When the external controller or initialIndex changes (e.g., after dynamic wheel recreation),
    // resync the selected center index so selected text style is immediately correct.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctrl = widget.controller;
      if (ctrl is FixedExtentScrollController) {
        try {
          final i = ctrl.selectedItem;
          if (i != _centerIndex) {
            setState(() => _centerIndex = i);
          }
        } catch (_) {
          // If controller was momentarily attached to multiple views,
          // ignore and keep current center index.
        }
      } else if (oldWidget.initialIndex != widget.initialIndex) {
        if (_centerIndex != widget.initialIndex) {
          setState(() => _centerIndex = widget.initialIndex);
        }
      }
    });
  }
  /* -------------------------------------------------------------------------------------- */
  void _handleChanged(int index) {
    setState(() => _centerIndex = index);
    widget.onSelectedItemChanged?.call(index);
  }
  /* -------------------------------------------------------------------------------------- */
  @override
  Widget build(BuildContext context) {
    return widget.wheelHeight != null || widget.wheelWidth != null
      ? SizedBox(
        height: widget.wheelHeight, 
        width: widget.wheelWidth,
        child: _buildWheel(),
      )
      : _buildWheel();
  }
  /* -------------------------------------------------------------------------------------- */
  Widget _buildWheel() {
    final theme = Theme.of(context);
    final dark = isDarkModeInUse(context);
    final selectedColor = widget.selectedItemColor ?? (
      widget.themeAware
        ? (dark ? Colors.white : theme.primaryColor)
        : theme.primaryColor
    );
    final unselectedColor = widget.unselectedItemColor ?? (
      widget.themeAware
        ? (dark ? Colors.white : Colors.black)
        : theme.hintColor
    );

    return ListWheelScrollView.useDelegate(
      controller: widget.controller,
      itemExtent: widget.itemExtent,
      perspective: widget.perspective,
      diameterRatio: widget.diameterRatio,
      onSelectedItemChanged: _handleChanged,
      physics: const FixedExtentScrollPhysics(),
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: widget.childCount,
        builder: (context, index) {
          // Prefer controller's selectedItem when available to ensure the
          // selected styling is correct immediately after dynamic recreation
          // or programmatic position updates that may not trigger the callback yet.
          final ctrl = widget.controller;
          int effectiveCenterIndex = _centerIndex;
          if (ctrl is FixedExtentScrollController && ctrl.hasClients) {
            try {
              effectiveCenterIndex = ctrl.selectedItem;
            } catch (_) {
              // If multiple attachments occurred within this frame, fallback safely.
              effectiveCenterIndex = _centerIndex;
            }
          }
          final selected = index == effectiveCenterIndex;

          return AnimatedOpacity(
            opacity: selected ? 1.0 : 0.15,
            duration: const Duration(milliseconds: 200),
            child: DefaultTextStyle(
              style: widget.textStyle?.call(selected) ?? GoogleFonts.roboto(
                color: selected ? selectedColor : unselectedColor,
                fontSize: 26,
                fontWeight: selected ? FontWeight.w400 : FontWeight.w300,
              ),
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              child: widget.child(index),
            ),
          );
        },
      ),
    );
  }
}
