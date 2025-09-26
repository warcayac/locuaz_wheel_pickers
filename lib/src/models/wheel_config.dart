import 'package:flutter/material.dart';

import 'wheel_dependency.dart';

/// Configuration class for individual wheels in the picker.
/// 
/// This class defines all the properties needed to configure and render
/// a single wheel in the **SelectiveWheelPickerBuilder** or **SimpleWheelPickerBuilder**. 
/// It includes display properties, behavior callbacks, and metadata for selective recreation.
/// 
/// ## Basic Usage:
/// 
/// ```dart
/// WheelConfig(
///   itemCount: 24,
///   formatter: (index) => index.toString().padLeft(2, '0'),
///   width: 60,
///   wheelId: 'hour_wheel',
///   // initialIndex defaults to 0
/// )
/// ```
/// 
/// ## With Separators:
/// 
/// ```dart
/// WheelConfig(
///   itemCount: 60,
///   formatter: (index) => index.toString().padLeft(2, '0'),
///   width: 60,
///   wheelId: 'minute_wheel',
///   trailingSeparator: WheelSeparators().colon(),
///   // initialIndex defaults to 0
/// )
/// ```
/// 
/// ## With Callbacks:
/// 
/// ```dart
/// WheelConfig(
///   itemCount: 12,
///   formatter: (index) => months[index],
///   width: 100,
///   wheelId: 'month_wheel',
///   onChanged: (index) {
///     print('Month changed to: ${months[index]}');
///   },
///   // initialIndex defaults to 0
/// )
/// ```
class WheelConfig {
  final int itemCount;
  /// **Use default (0):**
  /// - Simple lists starting from the beginning.
  /// - Dependent wheels where initial month/year/etc. imply 0 is appropriate and the first visible state is acceptable before dependencies settle.
  /// 
  /// **Use explicit non-zero:**
  /// - You need a meaningful preselected value at initial render (time/date/list).
  /// - Dependent wheels whose initial state must reflect non-zero drivers at first paint.
  /// - Large datasets where mid-list starting positions improve UX.
  /// - Any scenario where initial UI must reflect existing app state.
  final int initialIndex;
  final String Function(int index) formatter;
  final double width;
  final ValueChanged<int>? onChanged;
  final Widget? leadingSeparator;  // Separator before this wheel
  final Widget? trailingSeparator; // Separator after this wheel
  final String? wheelId; // Unique identifier for selective recreation
  final WheelDependency? dependency; // Dependency specification for this wheel
  /* -------------------------------------------------------------------------------------- */  
  const WheelConfig({
    required this.itemCount,
    this.initialIndex = 0,
    required this.formatter,
    this.width = 70,
    this.onChanged,
    this.leadingSeparator,
    this.trailingSeparator,
    this.wheelId,
    this.dependency,
  });
  /* -------------------------------------------------------------------------------------- */  
  /// Determines if this wheel configuration requires recreation compared to another.
  /// 
  /// Recreation is needed when core structural properties change that affect
  /// the scroll controller or widget tree structure. Changes to display-only
  /// properties like formatter or callbacks don't require recreation.
  /// 
  /// For wheels with dependencies, recreation is determined by calculating the
  /// new item count based on current dependency values and comparing it with
  /// the current item count.
  /// 
  /// **Recreation Triggers (reduced for stability):**
  /// - [itemCount]: Changes the number of scrollable items
  /// - [wheelId]: Changes the unique identifier
  /// - For dependent wheels: calculated item count differs from current
  /// 
  /// **Non-Recreation Changes:**
  /// - [formatter]: Display formatting function
  /// - [width]: Layout property handled by parent
  /// - [onChanged]: Callback function
  /// - [leadingSeparator]/[trailingSeparator]: Separator widgets
  /// 
  /// **Parameters:**
  /// - [other]: The configuration to compare against
  /// - [currentDependencyValues]: Either:
  ///   - the full allSelections list (indexed by absolute wheel indices), or
  ///   - a compact list whose length/order matches dependency.dependsOn.
  ///   When provided, this method detects the form and extracts specific values accordingly.
  ///   When omitted, the method falls back to reduced comparison.
  ///
  /// **Returns:** `true` if recreation is needed, `false` otherwise
  ///
  /// **Example:**
  /// ```dart
  /// final oldConfig = WheelConfig(itemCount: 30, initialIndex: 0, ...);
  /// final newConfig = WheelConfig(itemCount: 31, initialIndex: 0, ...);
  /// 
  /// if (oldConfig.needsRecreation(newConfig)) {
  ///   // Recreation needed due to itemCount change
  ///   recreateWheel(index, newConfig);
  /// } else {
  ///   // Simple update sufficient
  ///   updateWheelConfig(index, newConfig);
  /// }
  /// ```
  /// 
  /// **Example with Dependencies:**
  /// ```dart
  /// final dayConfig = WheelConfig(
  ///   itemCount: 30,
  ///   initialIndex: 0,
  ///   dependency: WheelDependency(
  ///     dependsOn: [1, 2], // month, year
  ///     calculateItemCount: (values) => DateTime(2000 + values[1], values[0] + 2, 0).day,
  ///   ),
  ///   ...
  /// );
  /// 
  /// // Check if day wheel needs recreation when month/year changes
  /// final needsRecreation = dayConfig.needsRecreation(
  ///   dayConfig, 
  ///   currentDependencyValues: [1, 24], // February 2024
  /// );
  /// ```
  bool needsRecreation(WheelConfig other, {List<int>? currentDependencyValues}) {
    // If no dependency, use reduced property comparison (ignore initialIndex).
    // initialIndex is a starting position only and should not force recreation on rebuilds.
    if (dependency == null) {
      return itemCount != other.itemCount
            || wheelId != other.wheelId;
    }

    // If has dependency, check if calculated item count differs
    if (currentDependencyValues != null) {
      // Accept either:
      // - A compact list already matching dependency.dependsOn length and order, or
      // - The full allSelections list (indexed by absolute wheel indices).
      List<int> specificDependencyValues;

      if (currentDependencyValues.length == dependency!.dependsOn.length) {
        // Treat as compact dependency-only values
        specificDependencyValues = currentDependencyValues;
      } else {
        // Treat as full allSelections; extract only the specific dependency values
        specificDependencyValues = <int>[];
        for (final depIndex in dependency!.dependsOn) {
          if (depIndex < currentDependencyValues.length) {
            specificDependencyValues.add(currentDependencyValues[depIndex]);
          } else {
            // If dependency index is out of bounds, assume recreation is needed
            return true;
          }
        }
      }

      final calculatedItemCount = dependency!.calculateNewItemCount(specificDependencyValues);
      if (calculatedItemCount == null) {
        // If calculation fails, assume recreation is needed for safety
        return true;
      }
      return calculatedItemCount != itemCount;
    }

    // If dependency exists but no values provided, fall back to reduced comparison
    return itemCount != other.itemCount
          || wheelId != other.wheelId;
  }
  /* -------------------------------------------------------------------------------------- */  
  /// Validates the wheel configuration for correctness.
  /// 
  /// Checks that all required properties are valid and within acceptable ranges.
  /// This method is used by WheelState and other components to ensure
  /// configuration integrity before use.
  /// 
  /// **Validation Rules:**
  /// - [itemCount]: Must be greater than 0
  /// - [initialIndex]: Must be within valid range (0 to itemCount-1)
  /// - [width]: Must be greater than 0
  /// - [formatter]: Must not be null
  /// - [dependency]: If present, must be valid according to WheelDependency.isValid()
  /// 
  /// **Parameters:**
  /// - [wheelIndex]: The index of this wheel in the picker (optional)
  ///   Required for dependency validation to check for circular references
  /// - [totalWheelCount]: Total number of wheels in the picker (optional)
  ///   Used to validate dependency indices are within bounds
  /// - [allDependencies]: Map of all wheel dependencies (optional)
  ///   Used to check for circular dependency chains
  /// 
  /// **Returns:** `true` if configuration is valid, `false` otherwise
  /// 
  /// **Example:**
  /// ```dart
  /// final config = WheelConfig(
  ///   itemCount: 24,
  ///   initialIndex: 0,
  ///   formatter: (i) => i.toString(),
  ///   width: 60,
  ///   dependency: WheelDependency(
  ///     dependsOn: [1, 2],
  ///     calculateItemCount: (values) => values[0] + values[1],
  ///   ),
  /// );
  /// 
  /// if (config.isValid(wheelIndex: 0, totalWheelCount: 5)) {
  ///   // Safe to use configuration
  ///   createWheel(config);
  /// } else {
  ///   // Handle invalid configuration
  ///   throw ArgumentError('Invalid wheel configuration');
  /// }
  /// ```
  bool isValid({
    int? wheelIndex,
    int? totalWheelCount,
    Map<int, WheelDependency>? allDependencies,
  }) {
    // Basic validation
    if (itemCount <= 0 || initialIndex < 0 || initialIndex >= itemCount || width <= 0) {
      return false;
    }

    // Dependency validation
    if (dependency != null) {
      // Validate dependency itself
      if (!dependency!.isValid(totalWheelCount: totalWheelCount)) {
        return false;
      }

      // Check for self-dependency
      if (wheelIndex != null && dependency!.dependsOn.contains(wheelIndex)) {
        return false;
      }

      // Check for circular dependencies
      if (wheelIndex != null && allDependencies != null) {
        if (dependency!.wouldCreateCycle(wheelIndex, allDependencies)) {
          return false;
        }
      }
    }

    return true;
  }
  /* -------------------------------------------------------------------------------------- */  
  /// Creates a new configuration based on dependency calculations.
  /// 
  /// This method is used when a wheel with dependencies needs to be recreated
  /// due to changes in its dependency wheels. It calculates the new item count
  /// and initial index based on the current dependency values.
  /// 
  /// **Parameters:**
  /// - [dependencyValues]: Current selection values from dependency wheels
  /// - [currentSelection]: Current selection index of this wheel
  /// 
  /// **Returns:** New WheelConfig with updated values, or null if calculation fails
  /// 
  /// **Example:**
  /// ```dart
  /// final dayConfig = WheelConfig(
  ///   itemCount: 30,
  ///   initialIndex: 15,
  ///   dependency: WheelDependency(
  ///     dependsOn: [1, 2], // month, year
  ///     calculateItemCount: (values) => DateTime(2000 + values[1], values[0] + 2, 0).day,
  ///   ),
  ///   ...
  /// );
  /// 
  /// // Create new config for February 2024
  /// final newConfig = dayConfig.createFromDependency([1, 24], 15);
  /// if (newConfig != null) {
  ///   // Use new configuration with correct number of days
  ///   recreateWheel(newConfig);
  /// }
  /// ```
  WheelConfig? createFromDependency(List<int> dependencyValues, int currentSelection) {
    if (dependency == null) {
      return null; // No dependency, can't create from dependency
    }

    final newItemCount = dependency!.calculateNewItemCount(dependencyValues);
    if (newItemCount == null) {
      return null; // Calculation failed
    }

    final newInitialIndex = dependency!.calculateNewInitialIndex(
      dependencyValues, 
      currentSelection, 
      newItemCount,
    );

    return copyWith(
      itemCount: newItemCount,
      initialIndex: newInitialIndex,
    );
  }
  /* -------------------------------------------------------------------------------------- */  
  /// Creates a copy of this configuration with updated values.
  /// 
  /// This method follows the immutable pattern, creating a new instance
  /// with specified properties updated while preserving all other values.
  /// 
  /// **Parameters:** All parameters are optional. Only specified parameters
  /// will be updated in the new instance.
  /// 
  /// **Example:**
  /// ```dart
  /// final originalConfig = WheelConfig(
  ///   itemCount: 30,
  ///   initialIndex: 0,
  ///   formatter: (i) => i.toString(),
  ///   width: 60,
  ///   wheelId: 'day_wheel',
  /// );
  /// 
  /// // Update only itemCount and wheelId
  /// final updatedConfig = originalConfig.copyWith(
  ///   itemCount: 31,
  ///   wheelId: 'day_wheel_february',
  /// );
  /// 
  /// // All other properties remain the same
  /// assert(updatedConfig.initialIndex == 0);
  /// assert(updatedConfig.width == 60);
  /// ```
  WheelConfig copyWith({
    int? itemCount,
    int? initialIndex,
    String Function(int index)? formatter,
    double? width,
    ValueChanged<int>? onChanged,
    Widget? leadingSeparator,
    Widget? trailingSeparator,
    String? wheelId,
    WheelDependency? dependency,
  }) {
    return WheelConfig(
      itemCount: itemCount ?? this.itemCount,
      initialIndex: initialIndex ?? this.initialIndex,
      formatter: formatter ?? this.formatter,
      width: width ?? this.width,
      onChanged: onChanged ?? this.onChanged,
      leadingSeparator: leadingSeparator ?? this.leadingSeparator,
      trailingSeparator: trailingSeparator ?? this.trailingSeparator,
      wheelId: wheelId ?? this.wheelId,
      dependency: dependency ?? this.dependency,
    );
  }
  /* -------------------------------------------------------------------------------------- */
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WheelConfig
        && other.itemCount == itemCount
        && other.initialIndex == initialIndex
        && other.width == width
        && other.wheelId == wheelId
        && other.dependency == dependency;
    // Note: We don't compare formatter, onChanged, leadingSeparator, trailingSeparator
    // as they are functions/widgets that can't be meaningfully compared
  }
  /* -------------------------------------------------------------------------------------- */  
  @override
  int get hashCode {
    return Object.hash(itemCount, initialIndex, width, wheelId, dependency);
  }
}