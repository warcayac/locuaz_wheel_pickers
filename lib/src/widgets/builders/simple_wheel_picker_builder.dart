import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/functions.dart';
import '../../models/wheel_config.dart';
import '../core/wheel_picker.dart';


/// Generic iOS-style wheel picker that can be configured for any purpose
/// 
/// This is a static implementation that creates all wheels at once and maintains
/// their state throughout the widget lifecycle. For dynamic wheel recreation
/// capabilities, use SelectiveWheelPickerBuilder from the dynamic approach.
class SimpleWheelPickerBuilder extends StatefulWidget {
  final List<WheelConfig> wheels;
  final ValueChanged<List<int>>? onChanged;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final bool themeAware;
  final Color? barColor;
  final TextStyle Function(bool isSelected)? textStyle;
  final double wheelHeight;
  final double barHeight;
  final double barRadius;
  final EdgeInsets barMargin;
  /* -------------------------------------------------------------------------------------- */  
  const SimpleWheelPickerBuilder({
    super.key,
    required this.wheels,
    this.onChanged,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.themeAware = true,
    this.barColor,
    this.textStyle,
    this.wheelHeight = 220,
    this.barHeight = 40,
    this.barRadius = 8,
    this.barMargin = const EdgeInsets.symmetric(horizontal: 8),
  });
  /* -------------------------------------------------------------------------------------- */  
  @override
  State<SimpleWheelPickerBuilder> createState() => _SimpleWheelPickerBuilderState();
}

/* ============================================================================================= */

class _SimpleWheelPickerBuilderState extends State<SimpleWheelPickerBuilder> {
  late List<FixedExtentScrollController> _controllers;
  late List<int> _selectedIndices;
  /* -------------------------------------------------------------------------------------- */  
  @override
  void initState() {
    super.initState();
    
    _selectedIndices = widget.wheels.map((w) => w.initialIndex).toList();
    _controllers = widget.wheels
      .map((w) => FixedExtentScrollController(initialItem: w.initialIndex))
      .toList();
  }
  /* -------------------------------------------------------------------------------------- */    
  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
  /* -------------------------------------------------------------------------------------- */    
  void _handleWheelChange(int wheelIndex, int selectedIndex) {
    setState(() {
      _selectedIndices[wheelIndex] = selectedIndex;
    });

    // Defer external callbacks to post-frame to avoid setState during build in consumers.
    final selectedSnapshot = selectedIndex;
    final indicesSnapshot = List<int>.from(_selectedIndices);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Call individual wheel callback
      widget.wheels[wheelIndex].onChanged?.call(selectedSnapshot);
      // Call global callback
      widget.onChanged?.call(indicesSnapshot);
    });
  }
  /* -------------------------------------------------------------------------------------- */    
  @override
  Widget build(BuildContext context) {
    final dark = isDarkModeInUse(context);
    
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: _buildWheelsWithSeparators(),
        ),
        // Selection bar
        IgnorePointer(
          child: Container(
            height: widget.barHeight,
            margin: widget.barMargin,
            decoration: BoxDecoration(
              color: (widget.barColor ?? (dark ? Colors.white : Colors.grey)).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(widget.barRadius),
            ),
          ),
        ),
      ],
    );
  }
  /* -------------------------------------------------------------------------------------- */    
  List<Widget> _buildWheelsWithSeparators() {
    final widgets = <Widget>[];
    
    for (int i = 0; i < widget.wheels.length; i++) {
      final wheel = widget.wheels[i];
      
      // Add leading separator if exists
      if (wheel.leadingSeparator != null) {
        widgets.add(wheel.leadingSeparator!);
      }
      
      // Add wheel
      widgets.add(_buildWheel(i));
      
      // Add trailing separator if exists
      if (wheel.trailingSeparator != null) {
        widgets.add(wheel.trailingSeparator!);
      }
    }
    
    return widgets;
  }
  /* -------------------------------------------------------------------------------------- */    
  Widget _buildWheel(int index) {
    final config = widget.wheels[index];
    
    return WheelPicker(
      controller: _controllers[index],
      wheelHeight: widget.wheelHeight,
      wheelWidth: config.width,
      childCount: config.itemCount,
      initialIndex: config.initialIndex,
      selectedItemColor: widget.selectedItemColor,
      unselectedItemColor: widget.unselectedItemColor,
      themeAware: widget.themeAware,
      textStyle: widget.textStyle,
      onSelectedItemChanged: (selectedIndex) {
        HapticFeedback.selectionClick();
        _handleWheelChange(index, selectedIndex);
      },
      child: (itemIndex) => Center(
        child: Text(config.formatter(itemIndex)),
      ),
    );
  }
}
