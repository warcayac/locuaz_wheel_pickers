import 'package:flutter/foundation.dart';
import '../models/wheel_config.dart';
import '../models/wheel_dependency.dart';
import 'dependency_manager.dart';
import 'recreation_decision.dart';

/// Optimized wheel recreation logic that implements dependency-based recreation decision making.
/// 
/// This class replaces reactive recreation with selective dependency-driven recreation,
/// providing intelligent item count calculation based on dependencies and eliminating
/// unnecessary wheel recreations.
/// 
/// ## Key Features:
/// 
/// - **Dependency-Based Recreation**: Only recreates wheels when their dependencies change
/// - **Intelligent Item Count Calculation**: Calculates new item counts based on dependency values
/// - **Recreation Decision Making**: Determines if recreation is actually needed
/// - **Performance Optimization**: Minimizes unnecessary controller disposal/creation
/// 
/// ## Basic Usage:
/// 
/// ```dart
/// final recreationLogic = RecreationLogic();
/// 
/// // Check if a wheel needs recreation
/// final decision = recreationLogic.shouldRecreateWheel(
///   wheelIndex: 0,
///   currentConfig: dayConfig,
///   allSelections: [15, 1, 24], // day=16, month=Feb, year=2024
///   dependencyManager: dependencyManager,
/// );
/// 
/// if (decision.needsRecreation) {
///   // Recreate the wheel with new configuration
///   recreateWheel(0, decision.newConfig!);
/// }
/// ```
/// 
/// ## Batch Recreation:
/// 
/// ```dart
/// // Check multiple wheels for recreation needs
/// final decisions = recreationLogic.shouldRecreateWheels(
///   wheelConfigs: allConfigs,
///   allSelections: currentSelections,
///   dependencyManager: dependencyManager,
/// );
/// 
/// // Process only wheels that need recreation
/// for (final decision in decisions) {
///   if (decision.needsRecreation) {
///     recreateWheel(decision.wheelIndex, decision.newConfig!);
///   }
/// }
/// ```
class RecreationLogic {
  /// Decision result for wheel recreation.
  /// 
  /// Contains information about whether a wheel needs recreation and
  /// the new configuration if recreation is needed.
  static const String _debugPrefix = 'RecreationLogic';
  /* -------------------------------------------------------------------------------------- */
  /// Determines if a single wheel needs recreation based on its dependencies.
  /// 
  /// This method implements the core logic for dependency-based recreation:
  /// 1. Checks if the wheel has dependencies
  /// 2. If no dependencies, wheel never needs recreation (only position updates)
  /// 3. If has dependencies, calculates new item count based on dependency values
  /// 4. Compares calculated item count with current item count
  /// 5. Returns recreation decision with new configuration if needed
  /// 
  /// **Parameters:**
  /// - [wheelIndex]: Index of the wheel to check
  /// - [currentConfig]: Current configuration of the wheel
  /// - [allSelections]: Current selection values for all wheels
  /// - [dependencyManager]: Manager containing dependency configurations
  /// 
  /// **Returns:** [RecreationDecision] indicating if recreation is needed
  /// 
  /// **Example:**
  /// ```dart
  /// // Check if day wheel needs recreation when month changes
  /// final decision = recreationLogic.shouldRecreateWheel(
  ///   wheelIndex: 0,
  ///   currentConfig: dayConfig,
  ///   allSelections: [15, 1, 24], // day=16, month=Feb, year=2024
  ///   dependencyManager: dependencyManager,
  /// );
  /// 
  /// if (decision.needsRecreation) {
  ///   print('Day wheel needs recreation: ${decision.reason}');
  ///   recreateWheel(0, decision.newConfig!);
  /// } else {
  ///   print('Day wheel recreation not needed: ${decision.reason}');
  /// }
  /// ```
  RecreationDecision shouldRecreateWheel({
    required int wheelIndex,
    required WheelConfig currentConfig,
    required List<int> allSelections,
    required DependencyManager dependencyManager,
  }) {
    try {
      // Check if wheel has dependencies
      if (!dependencyManager.hasDependencies(wheelIndex)) {
        return RecreationDecision(
          wheelIndex: wheelIndex,
          needsRecreation: false,
          newConfig: null,
          reason: 'Wheel has no dependencies - position-only updates',
        );
      }

      // Calculate new configuration based on dependencies
      final newConfig = dependencyManager.calculateNewConfig(
        wheelIndex,
        currentConfig,
        allSelections,
      );

      if (newConfig == null) {
        return RecreationDecision(
          wheelIndex: wheelIndex,
          needsRecreation: false,
          newConfig: null,
          reason: 'Failed to calculate new configuration',
        );
      }

      // Check if recreation is actually needed
      final needsRecreation = currentConfig.needsRecreation(newConfig);

      if (needsRecreation) {
        debugPrint('$_debugPrefix: Wheel $wheelIndex needs recreation - '
            'itemCount: ${currentConfig.itemCount} -> ${newConfig.itemCount}');
        
        return RecreationDecision(
          wheelIndex: wheelIndex,
          needsRecreation: true,
          newConfig: newConfig,
          reason: 'Item count changed: ${currentConfig.itemCount} -> ${newConfig.itemCount}',
        );
      } else {
        return RecreationDecision(
          wheelIndex: wheelIndex,
          needsRecreation: false,
          newConfig: null,
          reason: 'Configuration unchanged - no recreation needed',
        );
      }
    } catch (e) {
      debugPrint('$_debugPrefix: Error checking recreation for wheel $wheelIndex: $e');
      return RecreationDecision(
        wheelIndex: wheelIndex,
        needsRecreation: false,
        newConfig: null,
        reason: 'Error during recreation check: $e',
      );
    }
  }
  /* -------------------------------------------------------------------------------------- */
  /// Determines which wheels need recreation based on a specific wheel change.
  /// 
  /// This method implements the efficient dependency-driven recreation flow:
  /// 1. Gets all wheels that depend on the changed wheel
  /// 2. For each dependent wheel, checks if recreation is needed
  /// 3. Returns only the decisions for wheels that actually need recreation
  /// 
  /// **Parameters:**
  /// - [changedWheelIndex]: Index of the wheel that changed
  /// - [wheelConfigs]: Current configurations of all wheels
  /// - [allSelections]: Current selection values for all wheels
  /// - [dependencyManager]: Manager containing dependency configurations
  /// 
  /// **Returns:** List of [RecreationDecision] for wheels that need recreation
  /// 
  /// **Example:**
  /// ```dart
  /// // User scrolled the month wheel (index 1)
  /// final decisions = recreationLogic.getRecreationDecisionsForChange(
  ///   changedWheelIndex: 1,
  ///   wheelConfigs: allConfigs,
  ///   allSelections: currentSelections,
  ///   dependencyManager: dependencyManager,
  /// );
  /// 
  /// // Only day wheel (index 0) depends on month, so decisions will contain
  /// // at most one decision for the day wheel
  /// for (final decision in decisions) {
  ///   if (decision.needsRecreation) {
  ///     recreateWheel(decision.wheelIndex, decision.newConfig!);
  ///   }
  /// }
  /// ```
  List<RecreationDecision> getRecreationDecisionsForChange({
    required int changedWheelIndex,
    required List<WheelConfig> wheelConfigs,
    required List<int> allSelections,
    required DependencyManager dependencyManager,
  }) {
    final decisions = <RecreationDecision>[];

    try {
      // Get wheels that depend on the changed wheel
      final dependentWheels = dependencyManager.getDependentWheels(changedWheelIndex);

      debugPrint('$_debugPrefix: Wheel $changedWheelIndex changed, '
          'checking ${dependentWheels.length} dependent wheels: $dependentWheels');

      // Check each dependent wheel for recreation needs
      for (final wheelIndex in dependentWheels) {
        if (wheelIndex >= 0 && wheelIndex < wheelConfigs.length) {
          final decision = shouldRecreateWheel(
            wheelIndex: wheelIndex,
            currentConfig: wheelConfigs[wheelIndex],
            allSelections: allSelections,
            dependencyManager: dependencyManager,
          );

          decisions.add(decision);
        }
      }

      final recreationCount = decisions.where((d) => d.needsRecreation).length;
      debugPrint('$_debugPrefix: ${decisions.length} wheels checked, '
          '$recreationCount need recreation');

      return decisions;
    } catch (e) {
      debugPrint('$_debugPrefix: Error getting recreation decisions for change: $e');
      return [];
    }
  }
  /* -------------------------------------------------------------------------------------- */
  /// Checks all wheels for recreation needs based on current state.
  /// 
  /// This method is useful for batch operations or when you need to validate
  /// the entire wheel picker state for consistency.
  /// 
  /// **Parameters:**
  /// - [wheelConfigs]: Current configurations of all wheels
  /// - [allSelections]: Current selection values for all wheels
  /// - [dependencyManager]: Manager containing dependency configurations
  /// 
  /// **Returns:** List of [RecreationDecision] for all wheels
  /// 
  /// **Example:**
  /// ```dart
  /// // Check all wheels after major state change
  /// final decisions = recreationLogic.shouldRecreateWheels(
  ///   wheelConfigs: allConfigs,
  ///   allSelections: currentSelections,
  ///   dependencyManager: dependencyManager,
  /// );
  /// 
  /// // Process all recreation decisions
  /// final recreationsNeeded = decisions.where((d) => d.needsRecreation).toList();
  /// if (recreationsNeeded.isNotEmpty) {
  ///   print('${recreationsNeeded.length} wheels need recreation');
  ///   for (final decision in recreationsNeeded) {
  ///     recreateWheel(decision.wheelIndex, decision.newConfig!);
  ///   }
  /// }
  /// ```
  List<RecreationDecision> shouldRecreateWheels({
    required List<WheelConfig> wheelConfigs,
    required List<int> allSelections,
    required DependencyManager dependencyManager,
  }) {
    final decisions = <RecreationDecision>[];

    try {
      for (int i = 0; i < wheelConfigs.length; i++) {
        final decision = shouldRecreateWheel(
          wheelIndex: i,
          currentConfig: wheelConfigs[i],
          allSelections: allSelections,
          dependencyManager: dependencyManager,
        );

        decisions.add(decision);
      }

      final recreationCount = decisions.where((d) => d.needsRecreation).length;
      debugPrint('$_debugPrefix: Checked ${decisions.length} wheels, '
          '$recreationCount need recreation');

      return decisions;
    } catch (e) {
      debugPrint('$_debugPrefix: Error checking all wheels for recreation: $e');
      return [];
    }
  }
  /* -------------------------------------------------------------------------------------- */
  /// Calculates the optimal initial index for a recreated wheel.
  /// 
  /// This method determines what the initial selection should be when a wheel
  /// is recreated, taking into account the current selection and the new item count.
  /// 
  /// **Parameters:**
  /// - [currentSelection]: Current selection index of the wheel
  /// - [newItemCount]: New item count for the recreated wheel
  /// - [dependency]: Dependency configuration (optional for custom calculation)
  /// - [dependencyValues]: Current values from dependency wheels (for custom calculation)
  /// 
  /// **Returns:** Optimal initial index for the recreated wheel
  /// 
  /// **Example:**
  /// ```dart
  /// // Day wheel is being recreated from 31 days to 28 days (February)
  /// final optimalIndex = recreationLogic.calculateOptimalInitialIndex(
  ///   currentSelection: 30, // March 31st
  ///   newItemCount: 28,     // February has 28 days
  ///   dependency: dayDependency,
  ///   dependencyValues: [1, 24], // February 2024
  /// );
  /// // Returns 27 (February 28th) - the last valid day
  /// ```
  int calculateOptimalInitialIndex({
    required int currentSelection,
    required int newItemCount,
    WheelDependency? dependency,
    List<int>? dependencyValues,
  }) {
    try {
      // If dependency has custom calculation, use it
      if (dependency != null && dependencyValues != null) {
        return dependency.calculateNewInitialIndex(
          dependencyValues,
          currentSelection,
          newItemCount,
        );
      }

      // Default logic: preserve selection if valid, otherwise use last valid index
      if (currentSelection < newItemCount) {
        return currentSelection;
      } else {
        return newItemCount - 1;
      }
    } catch (e) {
      debugPrint('$_debugPrefix: Error calculating optimal initial index: $e');
      // Fallback to safe default
      return newItemCount > 0 ? newItemCount - 1 : 0;
    }
  }
  /* -------------------------------------------------------------------------------------- */
  /// Validates that a recreation decision is safe to execute.
  /// 
  /// This method performs safety checks before recreation to ensure the
  /// operation won't cause errors or inconsistent state.
  /// 
  /// **Parameters:**
  /// - [decision]: The recreation decision to validate
  /// - [currentWheelCount]: Current number of wheels in the picker
  /// 
  /// **Returns:** `true` if the decision is safe to execute
  /// 
  /// **Example:**
  /// ```dart
  /// final decision = recreationLogic.shouldRecreateWheel(...);
  /// 
  /// if (decision.needsRecreation && 
  ///     recreationLogic.validateRecreationDecision(decision, wheels.length)) {
  ///   // Safe to proceed with recreation
  ///   recreateWheel(decision.wheelIndex, decision.newConfig!);
  /// } else {
  ///   // Skip recreation due to safety concerns
  ///   print('Skipping unsafe recreation: ${decision.reason}');
  /// }
  /// ```
  bool validateRecreationDecision(RecreationDecision decision, int currentWheelCount) {
    try {
      // Check wheel index bounds
      if (decision.wheelIndex < 0 || decision.wheelIndex >= currentWheelCount) {
        debugPrint('$_debugPrefix: Invalid wheel index: ${decision.wheelIndex}');
        return false;
      }

      // If recreation is needed, validate new configuration
      if (decision.needsRecreation) {
        if (decision.newConfig == null) {
          debugPrint('$_debugPrefix: Recreation needed but no new config provided');
          return false;
        }

        // Validate new configuration
        if (!decision.newConfig!.isValid()) {
          debugPrint('$_debugPrefix: Invalid new configuration for wheel ${decision.wheelIndex}');
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('$_debugPrefix: Error validating recreation decision: $e');
      return false;
    }
  }
  /* -------------------------------------------------------------------------------------- */
  /// Gets statistics about recreation decisions for monitoring and debugging.
  /// 
  /// **Parameters:**
  /// - [decisions]: List of recreation decisions to analyze
  /// 
  /// **Returns:** Map containing statistics about the decisions
  /// 
  /// **Example:**
  /// ```dart
  /// final decisions = recreationLogic.shouldRecreateWheels(...);
  /// final stats = recreationLogic.getRecreationStats(decisions);
  /// 
  /// print('Recreation rate: ${stats['recreationRate']}%');
  /// print('Wheels needing recreation: ${stats['recreationCount']}');
  /// ```
  Map<String, dynamic> getRecreationStats(List<RecreationDecision> decisions) {
    if (decisions.isEmpty) {
      return {
        'totalWheels': 0,
        'recreationCount': 0,
        'recreationRate': 0.0,
        'reasons': <String, int>{},
      };
    }

    final recreationCount = decisions.where((d) => d.needsRecreation).length;
    final recreationRate = (recreationCount / decisions.length) * 100;

    // Count reasons
    final reasons = <String, int>{};
    for (final decision in decisions) {
      final reason = decision.needsRecreation ? 'Recreation needed' : 'No recreation';
      reasons[reason] = (reasons[reason] ?? 0) + 1;
    }

    return {
      'totalWheels': decisions.length,
      'recreationCount': recreationCount,
      'recreationRate': recreationRate,
      'reasons': reasons,
    };
  }
}
