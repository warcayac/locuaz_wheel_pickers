import 'package:flutter/material.dart';

import '../builders/simple_wheel_picker_builder.dart';
import '../../helpers/wheel_separators.dart';
import '../../models/wheel_config.dart';


class TimeOfDay {
  final int hour; // always 0-23
  final int minute;
  final int second;
  final bool is24Hour;
  /* -------------------------------------------------------------------------------------- */
  const TimeOfDay({
    required this.hour,
    required this.minute,
    required this.second,
    required this.is24Hour,
  });
  /* -------------------------------------------------------------------------------------- */
  int get displayHour => is24Hour ? hour : (hour == 0 || hour == 12 ? 12 : hour % 12);
  /* -------------------------------------------------------------------------------------- */
  bool get isAm => hour < 12;
}

/* ============================================================================================= */

class WTimePicker extends StatefulWidget {
  final bool use24Hour;
  final bool showSeconds;
  final TimeOfDay initialTime;
  final ValueChanged<TimeOfDay>? onChanged;
  final bool showSeparator;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final bool themeAware;
  final Color? barColor;
  final TextStyle Function(bool isSelected)? textStyle;
  /* -------------------------------------------------------------------------------------- */
  WTimePicker({
    super.key,
    this.use24Hour = true,
    this.showSeconds = true,
    TimeOfDay? initialTime,
    this.onChanged,
    this.showSeparator = false,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.themeAware = true,
    this.barColor,
    this.textStyle,
  }) : initialTime = initialTime ??
    TimeOfDay(
      hour: DateTime.now().hour,
      minute: DateTime.now().minute,
      second: DateTime.now().second,
      is24Hour: use24Hour,
    );
  /* -------------------------------------------------------------------------------------- */
  @override
  State<WTimePicker> createState() => _WTimePickerState();
}

/* ============================================================================================= */

class _WTimePickerState extends State<WTimePicker> {
  late int _hour;
  late int _minute;
  late int _second;
  late bool _isAm;
  /* -------------------------------------------------------------------------------------- */
  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hour;
    _minute = widget.initialTime.minute;
    _second = widget.initialTime.second;
    _isAm = widget.initialTime.isAm;
  }
  /* -------------------------------------------------------------------------------------- */
  void _handleTimeChange(List<int> indices) {
    // Guard in case this callback fires post-frame after disposal.
    if (!mounted) return;

    if (widget.use24Hour) {
      _hour = indices[0];
      _minute = indices[1];
      if (widget.showSeconds && indices.length > 2) {
        _second = indices[2];
      }
    } else {
      // 12-hour format
      final hourIndex = indices[0];
      _minute = indices[1];

      int nextIndex = 2;
      if (widget.showSeconds) {
        _second = indices[nextIndex];
        nextIndex++;
      }

      // AM/PM is last
      _isAm = indices[nextIndex] == 0;

      // Calculate hour based on displayed hour and AM/PM
      final displayedHour = hourIndex + 1; // 1-12
      final flag = _isAm ? 0 : 12;
      _hour = displayedHour == 12 ? flag : displayedHour + flag;
    }

    widget.onChanged?.call(
      TimeOfDay(
        hour: _hour,
        minute: _minute,
        second: _second,
        is24Hour: widget.use24Hour,
      ),
    );
  }
  /* -------------------------------------------------------------------------------------- */
  List<WheelConfig> _buildWheelConfigs() {
    final configs = <WheelConfig>[];
    final separator = WheelSeparators(
      textColor: widget.selectedItemColor,
      textStyle: widget.textStyle?.call(true),
    );

    // Hour wheel
    configs.add(
      WheelConfig(
        itemCount: widget.use24Hour ? 24 : 12,
        initialIndex: widget.use24Hour
          ? _hour
          : (_hour == 0 ? 11 : (_hour > 12 ? _hour - 13 : _hour - 1)),
        formatter: widget.use24Hour
          ? (i) => i.toString().padLeft(2, '0')
          : (i) => (i + 1).toString(),
        trailingSeparator: widget.showSeparator ? separator.colon() : null,
      ),
    );

    // Minute wheel
    configs.add(
      WheelConfig(
        itemCount: 60,
        initialIndex: _minute,
        formatter: (i) => i.toString().padLeft(2, '0'),
        trailingSeparator: widget.showSeconds && widget.showSeparator
          ? separator.colon()
          : null,
      ),
    );

    // Second wheel (optional)
    if (widget.showSeconds) {
      configs.add(
        WheelConfig(
          itemCount: 60,
          initialIndex: _second,
          formatter: (i) => i.toString().padLeft(2, '0'),
        ),
      );
    }

    // AM/PM wheel (for 12-hour format)
    if (!widget.use24Hour) {
      configs.add(
        WheelConfig(
          itemCount: 2,
          initialIndex: _isAm ? 0 : 1,
          formatter: (i) => i == 0 ? 'AM' : 'PM',
        ),
      );
    }

    return configs;
  }
  /* -------------------------------------------------------------------------------------- */
  @override
  Widget build(BuildContext context) {
    return SimpleWheelPickerBuilder(
      wheels: _buildWheelConfigs(),
      onChanged: _handleTimeChange,
      selectedItemColor: widget.selectedItemColor,
      unselectedItemColor: widget.unselectedItemColor,
      themeAware: widget.themeAware,
      barColor: widget.barColor,
      textStyle: widget.textStyle,
    );
  }
}
