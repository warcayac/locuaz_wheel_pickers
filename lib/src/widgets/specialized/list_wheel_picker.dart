import 'package:flutter/material.dart';

import '../builders/simple_wheel_picker_builder.dart';
import '../../models/wheel_config.dart';


class WListPicker extends StatelessWidget {
  final List<String> items;
  final int initialIndex;
  final ValueChanged<int>? onChanged;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final bool themeAware;
  final Color? barColor;
  /* -------------------------------------------------------------------------------------- */  
  const WListPicker({
    super.key,
    required this.items,
    this.initialIndex = 0,
    this.onChanged,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.themeAware = true,
    this.barColor,
  });
  /* -------------------------------------------------------------------------------------- */  
  @override
  Widget build(BuildContext context) {
    return SimpleWheelPickerBuilder(
      wheels: [
        WheelConfig(
          itemCount: items.length,
          initialIndex: initialIndex,
          formatter: (i) => items[i],
          width: 150,
        ),
      ],
      onChanged: (indices) => onChanged?.call(indices[0]),
      selectedItemColor: selectedItemColor,
      unselectedItemColor: unselectedItemColor,
      themeAware: themeAware,
      barColor: barColor,
    );
  }
}