import 'package:flutter/foundation.dart';

/// Configuration class that defines wheel dependencies and recreation logic.
/// 
/// This class allows developers to declaratively specify which wheels depend on others
/// and provides callbacks to calculate new configurations when dependencies change.
/// It's the core component of the dependency-based wheel recreation system.
/// 
/// ## Basic Usage:
/// 
/// ```dart
/// // Day wheel depends on month and year wheels
/// final dayDependency = WheelDependency(
///   dependsOn: [1, 2], // Month wheel (index 1) and year wheel (index 2)
///   calculateItemCount: (dependencyValues) {
///     final month = dependencyValues[0] + 1; // Convert from 0-based
///     final year = 2000 + dependencyValues[1];
///     return DateTime(year, month + 1, 0).day; // Days in month
///   },
/// );
/// ```
/// 
/// ## With Initial Index Calculation:
/// 
/// ```dart
/// final dayDependency = WheelDependency(
///   dependsOn: [1, 2],
///   calculateItemCount: (dependencyValues) {
///     final month = dependencyValues[0] + 1;
///     final year = 2000 + dependencyValues[1];
///     return DateTime(year, month + 1, 0).day;
///   },
///   calculateInitialIndex: (dependencyValues, currentSelection) {
///     final month = dependencyValues[0] + 1;
///     final year = 2000 + dependencyValues[1];
///     final maxDays = DateTime(year, month + 1, 0).day;
///     return currentSelection >= maxDays ? maxDays - 1 : currentSelection;
///   },
/// );
/// ```
class WheelDependency {
  /// List of wheel indices that this wheel depends on.
  /// 
  /// When any of these wheels change their selection, this wheel will be
  /// evaluated for potential recreation. The indices correspond to the
  /// position of wheels in the picker's wheel list.
  final List<int> dependsOn;
  /// Callback to calculate the new item count based on dependency values.
  /// 
  /// This function receives the current selection values of all dependency
  /// wheels and should return the new item count for this wheel.
  /// 
  /// **Parameters:**
  /// - [dependencyValues]: List of current selections from dependency wheels,
  ///   in the same order as specified in [dependsOn]
  /// 
  /// **Returns:** The new item count for this wheel
  final int Function(List<int> dependencyValues) calculateItemCount;
  /// Optional callback to calculate the initial index when recreation occurs.
  /// 
  /// This function is called when the wheel is recreated to determine what
  /// the new initial selection should be. If not provided, the system will
  /// attempt to preserve the current selection or default to 0.
  /// 
  /// **Parameters:**
  /// - [dependencyValues]: List of current selections from dependency wheels
  /// - [currentSelection]: The current selection index of this wheel
  /// 
  /// **Returns:** The new initial index for the recreated wheel
  final int Function(List<int> dependencyValues, int currentSelection)? calculateInitialIndex;

  /// Optional factory to rebuild the item label formatter when dependencies change.
  ///
  /// This allows dependent wheels to refresh their displayed labels in sync with
  /// the dependency-driven recreation. The factory receives the current dependency
  /// selections (in the same order as [dependsOn]) and must return a formatter:
  /// `(int itemIndex) => String`.
  ///
  /// If not provided, the existing formatter is preserved during recreation.
  final String Function(int index) Function(List<int> dependencyValues)? buildFormatter;
  /* -------------------------------------------------------------------------------------- */
  /// Creates a new wheel dependency configuration.
  ///
  /// **Parameters:**
  /// - [dependsOn]: List of wheel indices this wheel depends on
  /// - [calculateItemCount]: Function to calculate new item count
  /// - [calculateInitialIndex]: Optional function to calculate new initial index
  /// - [buildFormatter]: Optional factory to rebuild the formatter when dependencies change
  const WheelDependency({
    required this.dependsOn,
    required this.calculateItemCount,
    this.calculateInitialIndex,
    this.buildFormatter,
  });
  /* -------------------------------------------------------------------------------------- */
  /// Validates the dependency configuration for correctness.
  /// 
  /// Checks that the dependency specification is valid and can be safely used
  /// in the wheel picker system.
  /// 
  /// **Validation Rules:**
  /// - [dependsOn] must not be empty
  /// - [dependsOn] must not contain negative indices
  /// - [dependsOn] must not contain duplicate indices
  /// - [calculateItemCount] must not be null
  /// 
  /// **Parameters:**
  /// - [totalWheelCount]: Total number of wheels in the picker (optional)
  ///   If provided, validates that dependency indices are within bounds
  /// 
  /// **Returns:** `true` if configuration is valid, `false` otherwise
  /// 
  /// **Example:**
  /// ```dart
  /// final dependency = WheelDependency(
  ///   dependsOn: [1, 2],
  ///   calculateItemCount: (values) => values[0] + values[1],
  /// );
  /// 
  /// if (dependency.isValid(totalWheelCount: 5)) {
  ///   // Safe to use dependency
  ///   registerDependency(wheelIndex, dependency);
  /// } else {
  ///   // Handle invalid dependency
  ///   throw ArgumentError('Invalid wheel dependency configuration');
  /// }
  /// ```
  bool isValid({int? totalWheelCount}) {
    // Check if dependsOn is not empty
    if (dependsOn.isEmpty) {
      return false;
    }

    // Check for negative indices
    if (dependsOn.any((index) => index < 0)) {
      return false;
    }

    // Check for duplicate indices
    if (dependsOn.toSet().length != dependsOn.length) {
      return false;
    }

    // Check bounds if total wheel count is provided
    if (totalWheelCount != null) {
      if (dependsOn.any((index) => index >= totalWheelCount)) {
        return false;
      }
    }

    return true;
  }
  /* -------------------------------------------------------------------------------------- */
  /// Checks if this dependency would create a circular reference.
  /// 
  /// A circular dependency occurs when wheel A depends on wheel B,
  /// and wheel B (directly or indirectly) depends on wheel A.
  /// 
  /// **Parameters:**
  /// - [wheelIndex]: The index of the wheel this dependency belongs to
  /// - [allDependencies]: Map of all wheel dependencies in the system
  /// 
  /// **Returns:** `true` if adding this dependency would create a cycle
  /// 
  /// **Example:**
  /// ```dart
  /// final dependencies = <int, WheelDependency>{
  ///   1: WheelDependency(dependsOn: [2], calculateItemCount: (v) => v[0]),
  ///   2: WheelDependency(dependsOn: [3], calculateItemCount: (v) => v[0]),
  /// };
  /// 
  /// final newDependency = WheelDependency(
  ///   dependsOn: [1], // This would create a cycle: 3 -> 1 -> 2 -> 3
  ///   calculateItemCount: (v) => v[0],
  /// );
  /// 
  /// if (newDependency.wouldCreateCycle(3, dependencies)) {
  ///   throw ArgumentError('Circular dependency detected');
  /// }
  /// ```
  bool wouldCreateCycle(int wheelIndex, Map<int, WheelDependency> allDependencies) {
    // Use depth-first search to detect cycles
    final visited = <int>{};
    final recursionStack = <int>{};

    bool hasCycleDFS(int currentWheel) {
      if (recursionStack.contains(currentWheel)) {
        return true; // Back edge found - cycle detected
      }

      if (visited.contains(currentWheel)) {
        return false; // Already processed this path
      }

      visited.add(currentWheel);
      recursionStack.add(currentWheel);

      // Get dependencies for current wheel
      List<int> dependencies;
      if (currentWheel == wheelIndex) {
        // Use this dependency for the wheel we're checking
        dependencies = dependsOn;
      } else {
        // Use existing dependency if it exists
        final existingDependency = allDependencies[currentWheel];
        dependencies = existingDependency?.dependsOn ?? [];
      }

      // Check all dependencies
      for (final dep in dependencies) {
        if (hasCycleDFS(dep)) {
          return true;
        }
      }

      recursionStack.remove(currentWheel);
      return false;
    }

    return hasCycleDFS(wheelIndex);
  }
  /* -------------------------------------------------------------------------------------- */
  /// Calculates the new item count for this wheel based on current dependency values.
  /// 
  /// This is a safe wrapper around the [calculateItemCount] callback that handles
  /// potential exceptions and validates the result.
  /// 
  /// **Parameters:**
  /// - [dependencyValues]: Current selection values from dependency wheels
  /// 
  /// **Returns:** The calculated item count, or null if calculation fails
  /// 
  /// **Example:**
  /// ```dart
  /// final dependency = WheelDependency(
  ///   dependsOn: [0, 1],
  ///   calculateItemCount: (values) {
  ///     final month = values[0] + 1;
  ///     final year = 2000 + values[1];
  ///     return DateTime(year, month + 1, 0).day;
  ///   },
  /// );
  /// 
  /// final newItemCount = dependency.calculateNewItemCount([1, 24]); // Feb 2024
  /// if (newItemCount != null && newItemCount > 0) {
  ///   // Use the calculated item count
  ///   updateWheelItemCount(newItemCount);
  /// }
  /// ```
  int? calculateNewItemCount(List<int> dependencyValues) {
    try {
      // Validate input
      if (dependencyValues.length != dependsOn.length) {
        debugPrint('WheelDependency: Dependency values length mismatch. '
            'Expected ${dependsOn.length}, got ${dependencyValues.length}');
        return null;
      }

      final result = calculateItemCount(dependencyValues);
      
      // Validate result
      if (result <= 0) {
        debugPrint('WheelDependency: calculateItemCount returned invalid value: $result');
        return null;
      }

      return result;
    } catch (e) {
      debugPrint('WheelDependency: Error calculating item count: $e');
      return null;
    }
  }
  /* -------------------------------------------------------------------------------------- */
  /// Calculates the new initial index for this wheel based on current dependency values.
  /// 
  /// This is a safe wrapper around the [calculateInitialIndex] callback that handles
  /// potential exceptions and validates the result.
  /// 
  /// **Parameters:**
  /// - [dependencyValues]: Current selection values from dependency wheels
  /// - [currentSelection]: Current selection index of this wheel
  /// - [newItemCount]: The new item count for this wheel
  /// 
  /// **Returns:** The calculated initial index, or a safe default if calculation fails
  /// 
  /// **Example:**
  /// ```dart
  /// final dependency = WheelDependency(
  ///   dependsOn: [0, 1],
  ///   calculateItemCount: (values) => /* ... */,
  ///   calculateInitialIndex: (values, current) {
  ///     final maxDays = calculateItemCount(values);
  ///     return current >= maxDays ? maxDays - 1 : current;
  ///   },
  /// );
  /// 
  /// final newIndex = dependency.calculateNewInitialIndex([1, 24], 30, 29);
  /// // Returns 28 (29-1) since current selection 30 is out of bounds
  /// ```
  int calculateNewInitialIndex(List<int> dependencyValues, int currentSelection, int newItemCount) {
    try {
      // If no custom calculation provided, use safe default
      if (calculateInitialIndex == null) {
        return currentSelection < newItemCount ? currentSelection : newItemCount - 1;
      }

      // Validate input
      if (dependencyValues.length != dependsOn.length) {
        debugPrint('WheelDependency: Dependency values length mismatch for initial index calculation');
        return currentSelection < newItemCount ? currentSelection : newItemCount - 1;
      }

      final result = calculateInitialIndex!(dependencyValues, currentSelection);
      
      // Validate result is within bounds
      if (result < 0 || result >= newItemCount) {
        debugPrint('WheelDependency: calculateInitialIndex returned out-of-bounds value: $result');
        return currentSelection < newItemCount ? currentSelection : newItemCount - 1;
      }

      return result;
    } catch (e) {
      debugPrint('WheelDependency: Error calculating initial index: $e');
      return currentSelection < newItemCount ? currentSelection : newItemCount - 1;
    }
  }
  /* -------------------------------------------------------------------------------------- */
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WheelDependency &&
        listEquals(other.dependsOn, dependsOn);
    // Note: We don't compare function references as they can't be meaningfully compared
  }
  /* -------------------------------------------------------------------------------------- */
  @override
  int get hashCode {
    return Object.hashAll(dependsOn);
  }
  /* -------------------------------------------------------------------------------------- */
  @override
  String toString() {
    return 'WheelDependency(dependsOn: $dependsOn, hasCalculateInitialIndex: ${calculateInitialIndex != null}, hasBuildFormatter: ${buildFormatter != null})';
  }
}