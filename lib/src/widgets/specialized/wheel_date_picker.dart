import 'package:flutter/material.dart';

import '../builders/selective_wheel_picker_builder.dart';
import '../../controllers/wheel_manager.dart';
import '../../helpers/wheel_separators.dart';
import '../../models/wheel_config.dart';
import '../../models/wheel_dependency.dart';


enum EDateFormat {
  dMy, dMMy, dMMMy, // day-month-year
  xMy, xMMy, xMMMy, // month-year
}

enum Lang { en, es }

class WDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime>? onChanged;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final bool themeAware;
  final Color? barColor;
  final EDateFormat format;
  final TextStyle Function(bool isSelected)? textStyle;
  final bool showSeparator;
  final Lang language;
  final int startYear;
  final int endYear;
  /* -------------------------------------------------------------------------------------- */
  WDatePicker({
    super.key,
    DateTime? initialDate,
    this.onChanged,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.themeAware = true,
    this.barColor,
    this.format = EDateFormat.dMMy,
    this.textStyle,
    this.showSeparator = false,
    this.language = Lang.es,
    this.startYear = 2000,
    this.endYear = 2100,
  }) : initialDate = initialDate ?? DateTime.now() {
    if (endYear <= startYear) {
      throw ArgumentError('endYear ($endYear) must be greater than startYear ($startYear)');
    }
    final y = this.initialDate.year;
    if (y < startYear || y > endYear) {
      throw ArgumentError('initialDate.year ($y) must be within [$startYear, $endYear]');
    }
  }
  /* -------------------------------------------------------------------------------------- */
  @override
  State<WDatePicker> createState() => _WDatePickerState();
}

/* ============================================================================================= */

class _WDatePickerState extends State<WDatePicker> {
  static const List<String> _monthsEn = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December',
  ];
  static const List<String> _monthsEs = [
    'Enero','Febrero','Marzo','Abril','Mayo','Junio',
    'Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre',
  ];
  /* -------------------------------------------------------------------------------------- */
  late int _day;
  late int _month;
  late int _year;
  late WheelManager _wheelManager;
  final GlobalKey _pickerKey = GlobalKey();
  /* -------------------------------------------------------------------------------------- */
  @override
  void initState() {
    super.initState();
    _day = widget.initialDate.day;
    _month = widget.initialDate.month;
    _year = widget.initialDate.year;
    _wheelManager = WheelManager();
  }
  /* -------------------------------------------------------------------------------------- */
  int _getDaysInMonth(int month, int year) => DateTime(year, month + 1, 0).day;
  /* -------------------------------------------------------------------------------------- */
  /// Validate if the current date is valid
  bool _isValidDate(int day, int month, int year) {
    if (month < 1 || month > 12) return false;
    if (day < 1) return false;

    final maxDays = _getDaysInMonth(month, year);
    return day <= maxDays;
  }
  /* -------------------------------------------------------------------------------------- */
  /// Detect if the current date is invalid (e.g., Feb 31)
  bool _isInvalidDate() {
    return !_isValidDate(_day, _month, _year);
  }
  /* -------------------------------------------------------------------------------------- */
  /// Adjust invalid date to the last valid day of the month
  int _adjustInvalidDay(int day, int month, int year) {
    final maxDays = _getDaysInMonth(month, year);
    return day > maxDays ? maxDays : day;
  }
  /* -------------------------------------------------------------------------------------- */
  bool get _isDayWheelVisible => [EDateFormat.dMy,EDateFormat.dMMy,EDateFormat.dMMMy].contains(widget.format);
  /* -------------------------------------------------------------------------------------- */
  Widget? get _separator => widget.showSeparator
    ? WheelSeparators(
        textColor: widget.selectedItemColor,
        textStyle: widget.textStyle?.call(true),
      ).slash()
    : null;
  /* -------------------------------------------------------------------------------------- */
  void _handleDateChange(List<int> indices) {
    if (!mounted) return;

    setState(() {
      // Update internal state based on wheel selections
      if (_isDayWheelVisible) {
        _day = indices[0] + 1;
        _month = indices[1] + 1;
        _year = widget.startYear + indices[2];
      } else {
        _month = indices[0] + 1;
        _year = widget.startYear + indices[1];
      }

      // Validate and adjust date if needed
      if (_isInvalidDate()) {
        _day = _adjustInvalidDay(_day, _month, _year);
      }
    });

    // Notify about the date change (already being called post-frame by the builder)
    // The dependency system will automatically handle day wheel recreation
    widget.onChanged?.call(DateTime(_year, _month, _day));
  }
  /* -------------------------------------------------------------------------------------- */
  List<WheelConfig> _buildWheelConfigs() {
    return [
      if (_isDayWheelVisible) _getDayWheel(),
      _getMonthWheel(widget.format),
      _getYearWheel(),
    ];
  }
  /* -------------------------------------------------------------------------------------- */
  WheelConfig _getDayWheel() {
    final daysInMonth = _getDaysInMonth(_month, _year);

    return WheelConfig(
      itemCount: daysInMonth,
      initialIndex: _day - 1,
      formatter: (i) => (i + 1).toString(),
      width: 50,
      trailingSeparator: _separator,
      wheelId: 'day_wheel',
      // Day wheel depends on month and year wheels
      dependency: WheelDependency(
        dependsOn: [1, 2], // Month wheel (index 1) and year wheel (index 2)
        calculateItemCount: (dependencyValues) {
          final month = dependencyValues[0] + 1; // Convert from 0-based
          final year = widget.startYear + dependencyValues[1];
          return DateTime(year, month + 1, 0).day; // Days in month
        },
        calculateInitialIndex: (dependencyValues, currentSelection) {
          final month = dependencyValues[0] + 1;
          final year = widget.startYear + dependencyValues[1];
          final maxDays = DateTime(year, month + 1, 0).day;
          return currentSelection >= maxDays ? maxDays - 1 : currentSelection;
        },
      ),
    );
  }
  /* -------------------------------------------------------------------------------------- */
  WheelConfig _getMonthWheel(EDateFormat format) {
    final months = widget.language == Lang.en ? _monthsEn : _monthsEs;
    final (String Function(int) f, double w) = switch (format) {
      EDateFormat.dMy || EDateFormat.xMy => ((i) => (i + 1).toString(), 50),
      EDateFormat.dMMy || EDateFormat.xMMy => ((i) => months[i].substring(0, 3), 70),
      EDateFormat.dMMMy || EDateFormat.xMMMy => ((i) => months[i], 140),
    };

    return WheelConfig(
      itemCount: 12,
      initialIndex: _month - 1,
      formatter: f,
      width: w,
      trailingSeparator: _separator,
      wheelId: 'month_wheel',
      // No dependency - this wheel is never recreated for smooth scrolling
      dependency: null,
    );
  }
  /* -------------------------------------------------------------------------------------- */
  WheelConfig _getYearWheel() {
    return WheelConfig(
      itemCount: widget.endYear - widget.startYear + 1,
      initialIndex: _year - widget.startYear,
      formatter: (i) => (widget.startYear + i).toString(),
      width: 80,
      wheelId: 'year_wheel',
      // No dependency - this wheel is never recreated for smooth scrolling
      dependency: null,
    );
  }
  /* -------------------------------------------------------------------------------------- */
  @override
  Widget build(BuildContext context) {
    return SelectiveWheelPickerBuilder(
      key: _pickerKey,
      wheels: _buildWheelConfigs(),
      onChanged: _handleDateChange,
      selectedItemColor: widget.selectedItemColor,
      unselectedItemColor: widget.unselectedItemColor,
      themeAware: widget.themeAware,
      barColor: widget.barColor,
      textStyle: widget.textStyle,
      wheelManager: _wheelManager,
    );
  }
  /* -------------------------------------------------------------------------------------- */
  @override
  void dispose() {
    _wheelManager.dispose();
    super.dispose();
  }
}
