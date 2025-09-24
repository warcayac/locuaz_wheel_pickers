import 'package:flutter/foundation.dart';
import '../models/wheel_config.dart';
import '../models/wheel_dependency.dart';

/// Manages the dependency graph and determines when wheel recreations are needed.
/// 
/// This class is the core component of the dependency-based wheel recreation system.
/// It maintains a dependency graph, provides efficient lookup of dependent wheels,
/// and validates dependency configurations to prevent circular dependencies.
/// 
/// ## Basic Usage:
/// 
/// ```dart
/// final manager = DependencyManager();
/// 
/// // Register dependencies
/// manager.registerDependency(0, dayWheelDependency); // Day depends on month/year
/// 
/// // Check what wheels need updates when month wheel changes
/// final dependentWheels = manager.getDependentWheels(1); // Returns {0}
/// 
/// // Calculate new configuration for day wheel
/// final newConfig = manager.calculateNewConfig(0, currentDayConfig, allSelections);
/// ```
/// 
/// ## Dependency Graph Management:
/// 
/// The manager maintains two maps for efficient lookups:
/// - **Dependencies**: Maps wheel index → WheelDependency (what this wheel depends on)
/// - **Dependents**: Maps wheel index → Set<int> (what wheels depend on this wheel)
/// 
/// This dual mapping allows for efficient forward and reverse lookups in the dependency graph.
class DependencyManager {
  /// Maps wheel index to its dependency configuration.
  /// 
  /// This map stores the dependency specification for each wheel that has dependencies.
  /// Wheels without dependencies are not present in this map.
  final Map<int, WheelDependency> _dependencies = {};
  /// Maps wheel index to the set of wheels that depend on it.
  /// 
  /// This reverse mapping allows efficient lookup of which wheels need to be
  /// checked when a specific wheel changes. For example, if wheel 1 (month)
  /// changes, we can quickly find that wheel 0 (day) depends on it.
  final Map<int, Set<int>> _dependents = {};
  /* -------------------------------------------------------------------------------------- */
  /// Registers a dependency for a specific wheel.
  /// 
  /// This method adds a wheel's dependency configuration to the graph and
  /// updates the reverse mapping for efficient dependent lookups.
  /// 
  /// **Validation:**
  /// - Validates the dependency configuration
  /// - Checks for circular dependencies
  /// - Ensures dependency indices are within bounds (if totalWheelCount provided)
  /// 
  /// **Parameters:**
  /// - [wheelIndex]: The index of the wheel that has dependencies
  /// - [dependency]: The dependency configuration
  /// - [totalWheelCount]: Optional total wheel count for bounds validation
  /// 
  /// **Throws:**
  /// - [ArgumentError]: If dependency is invalid or would create circular dependency
  /// 
  /// **Example:**
  /// ```dart
  /// final dayDependency = WheelDependency(
  ///   dependsOn: [1, 2], // Month and year wheels
  ///   calculateItemCount: (values) {
  ///     final month = values[0] + 1;
  ///     final year = 2000 + values[1];
  ///     return DateTime(year, month + 1, 0).day;
  ///   },
  /// );
  /// 
  /// manager.registerDependency(0, dayDependency, totalWheelCount: 3);
  /// ```
  void registerDependency(int wheelIndex, WheelDependency dependency, {int? totalWheelCount}) {
    // Validate the dependency configuration
    if (!dependency.isValid(totalWheelCount: totalWheelCount)) {
      throw ArgumentError('Invalid dependency configuration for wheel $wheelIndex');
    }

    // Check for circular dependencies
    if (dependency.wouldCreateCycle(wheelIndex, _dependencies)) {
      throw ArgumentError('Circular dependency detected for wheel $wheelIndex');
    }

    // Remove existing dependency if present
    unregisterDependency(wheelIndex);

    // Register the new dependency
    _dependencies[wheelIndex] = dependency;

    // Update reverse mapping
    for (final dependencyIndex in dependency.dependsOn) {
      _dependents.putIfAbsent(dependencyIndex, () => <int>{}).add(wheelIndex);
    }

    debugPrint('DependencyManager: Registered dependency for wheel $wheelIndex -> ${dependency.dependsOn}');
  }
  /* -------------------------------------------------------------------------------------- */
  /// Unregisters a dependency for a specific wheel.
  /// 
  /// This method removes a wheel's dependency configuration from the graph
  /// and cleans up the reverse mapping.
  /// 
  /// **Parameters:**
  /// - [wheelIndex]: The index of the wheel to remove dependencies for
  /// 
  /// **Example:**
  /// ```dart
  /// // Remove dependency for day wheel
  /// manager.unregisterDependency(0);
  /// ```
  void unregisterDependency(int wheelIndex) {
    final existingDependency = _dependencies.remove(wheelIndex);
    
    if (existingDependency != null) {
      // Clean up reverse mapping
      for (final dependencyIndex in existingDependency.dependsOn) {
        _dependents[dependencyIndex]?.remove(wheelIndex);
        
        // Remove empty sets to keep the map clean
        if (_dependents[dependencyIndex]?.isEmpty == true) {
          _dependents.remove(dependencyIndex);
        }
      }
      
      debugPrint('DependencyManager: Unregistered dependency for wheel $wheelIndex');
    }
  }
  /* -------------------------------------------------------------------------------------- */
  /// Gets the set of wheels that depend on the specified wheel.
  /// 
  /// This method provides efficient lookup of which wheels need to be checked
  /// when a specific wheel changes its selection.
  /// 
  /// **Parameters:**
  /// - [changedWheelIndex]: The index of the wheel that changed
  /// 
  /// **Returns:** Set of wheel indices that depend on the changed wheel
  /// 
  /// **Example:**
  /// ```dart
  /// // User scrolled the month wheel (index 1)
  /// final dependentWheels = manager.getDependentWheels(1);
  /// 
  /// // Check each dependent wheel for recreation needs
  /// for (final wheelIndex in dependentWheels) {
  ///   if (manager.needsRecreation(wheelIndex, currentConfigs[wheelIndex], allSelections)) {
  ///     recreateWheel(wheelIndex);
  ///   }
  /// }
  /// ```
  Set<int> getDependentWheels(int changedWheelIndex) {
    return _dependents[changedWheelIndex]?.toSet() ?? <int>{};
  }
  /* -------------------------------------------------------------------------------------- */
  /// Calculates a new configuration for a dependent wheel based on current selections.
  /// 
  /// This method uses the wheel's dependency configuration to calculate what
  /// the new item count and initial index should be based on the current
  /// selections of its dependency wheels.
  /// 
  /// **Parameters:**
  /// - [wheelIndex]: The index of the wheel to calculate new config for
  /// - [currentConfig]: The current configuration of the wheel
  /// - [allSelections]: Current selection values for all wheels
  /// 
  /// **Returns:** New WheelConfig if calculation succeeds, null if wheel has no dependencies or calculation fails
  /// 
  /// **Example:**
  /// ```dart
  /// final allSelections = [15, 1, 24]; // Day=16, Month=Feb, Year=2024
  /// final newConfig = manager.calculateNewConfig(0, currentDayConfig, allSelections);
  /// 
  /// if (newConfig != null && currentDayConfig.needsRecreation(newConfig)) {
  ///   // Recreation needed - February 2024 has different number of days
  ///   recreateWheel(0, newConfig);
  /// }
  /// ```
  WheelConfig? calculateNewConfig(int wheelIndex, WheelConfig currentConfig, List<int> allSelections) {
    final dependency = _dependencies[wheelIndex];
    if (dependency == null) {
      return null; // No dependency - no new config needed
    }

    try {
      // Extract dependency values - only get values for the specific dependency indices
      final dependencyValues = <int>[];
      for (final depIndex in dependency.dependsOn) {
        if (depIndex < allSelections.length) {
          dependencyValues.add(allSelections[depIndex]);
        } else {
          debugPrint('DependencyManager: Dependency index $depIndex out of bounds for wheel $wheelIndex');
          return null;
        }
      }

      // Calculate new item count
      final newItemCount = dependency.calculateNewItemCount(dependencyValues);
      if (newItemCount == null) {
        debugPrint('DependencyManager: Failed to calculate item count for wheel $wheelIndex');
        return null;
      }

      // Calculate new initial index
      final currentSelection = wheelIndex < allSelections.length ? allSelections[wheelIndex] : 0;
      final newInitialIndex = dependency.calculateNewInitialIndex(
        dependencyValues,
        currentSelection,
        newItemCount,
      );

      // Optionally rebuild formatter based on current dependency values so label content
      // stays in sync without relying on external state closures.
      final formatter = dependency.buildFormatter != null
          ? dependency.buildFormatter!(dependencyValues)
          : currentConfig.formatter;

      // Create new configuration with updated structural values and formatter if supplied
      return currentConfig.copyWith(
        itemCount: newItemCount,
        initialIndex: newInitialIndex,
        formatter: formatter,
      );
    } catch (e) {
      debugPrint('DependencyManager: Error calculating new config for wheel $wheelIndex: $e');
      return null;
    }
  }
  /* -------------------------------------------------------------------------------------- */
  /// Checks if a wheel actually needs recreation based on its dependencies.
  /// 
  /// This method determines whether a wheel needs to be recreated by comparing
  /// its current configuration with what the configuration should be based on
  /// the current dependency values.
  /// 
  /// **Parameters:**
  /// - [wheelIndex]: The index of the wheel to check
  /// - [currentConfig]: The current configuration of the wheel
  /// - [allSelections]: Current selection values for all wheels
  /// 
  /// **Returns:** `true` if recreation is needed, `false` otherwise
  /// 
  /// **Example:**
  /// ```dart
  /// if (manager.needsRecreation(0, currentDayConfig, allSelections)) {
  ///   final newConfig = manager.calculateNewConfig(0, currentDayConfig, allSelections);
  ///   if (newConfig != null) {
  ///     recreateWheel(0, newConfig);
  ///   }
  /// }
  /// ```
  bool needsRecreation(int wheelIndex, WheelConfig currentConfig, List<int> allSelections) {
    final dependency = _dependencies[wheelIndex];
    if (dependency == null) {
      return false; // No dependency - no recreation needed
    }

    try {
      // Validate dependency indices are within bounds of the full selections list
      for (final depIndex in dependency.dependsOn) {
        if (depIndex >= allSelections.length) {
          return false; // Invalid dependency index
        }
      }

      // Use dependency-aware recreation check with full selections list
      return currentConfig.needsRecreation(currentConfig, currentDependencyValues: allSelections);
    } catch (e) {
      debugPrint('DependencyManager: Error checking recreation need for wheel $wheelIndex: $e');
      return false;
    }
  }
  /* -------------------------------------------------------------------------------------- */
  /// Validates the entire dependency graph for correctness.
  /// 
  /// This method performs comprehensive validation of all registered dependencies
  /// to ensure the graph is valid and can be safely used.
  /// 
  /// **Validation Checks:**
  /// - All dependencies are individually valid
  /// - No circular dependencies exist in the graph
  /// - All dependency indices are within bounds (if totalWheelCount provided)
  /// 
  /// **Parameters:**
  /// - [totalWheelCount]: Optional total wheel count for bounds validation
  /// 
  /// **Returns:** `true` if the entire graph is valid, `false` otherwise
  /// 
  /// **Example:**
  /// ```dart
  /// // After registering all dependencies
  /// if (!manager.validateGraph(totalWheelCount: wheels.length)) {
  ///   throw StateError('Invalid dependency graph configuration');
  /// }
  /// ```
  bool validateGraph({int? totalWheelCount}) {
    // Validate each individual dependency
    for (final entry in _dependencies.entries) {
      final wheelIndex = entry.key;
      final dependency = entry.value;

      if (!dependency.isValid(totalWheelCount: totalWheelCount)) {
        debugPrint('DependencyManager: Invalid dependency for wheel $wheelIndex');
        return false;
      }

      if (dependency.wouldCreateCycle(wheelIndex, _dependencies)) {
        debugPrint('DependencyManager: Circular dependency detected for wheel $wheelIndex');
        return false;
      }
    }

    return true;
  }
  /* -------------------------------------------------------------------------------------- */
  /// Detects if there are any circular dependencies in the current graph.
  /// 
  /// Uses depth-first search to detect cycles in the dependency graph.
  /// A cycle exists if there's a path from a wheel back to itself through dependencies.
  /// 
  /// **Returns:** `true` if circular dependencies exist, `false` otherwise
  /// 
  /// **Example:**
  /// ```dart
  /// if (manager.hasCircularDependencies()) {
  ///   throw StateError('Circular dependencies detected in wheel configuration');
  /// }
  /// ```
  bool hasCircularDependencies() {
    final visited = <int>{};
    final recursionStack = <int>{};

    bool hasCycleDFS(int wheelIndex) {
      if (recursionStack.contains(wheelIndex)) {
        return true; // Back edge found - cycle detected
      }

      if (visited.contains(wheelIndex)) {
        return false; // Already processed this path
      }

      visited.add(wheelIndex);
      recursionStack.add(wheelIndex);

      // Check all dependencies of current wheel
      final dependency = _dependencies[wheelIndex];
      if (dependency != null) {
        for (final depIndex in dependency.dependsOn) {
          if (hasCycleDFS(depIndex)) {
            return true;
          }
        }
      }

      recursionStack.remove(wheelIndex);
      return false;
    }

    // Check all wheels in the graph
    for (final wheelIndex in _dependencies.keys) {
      if (!visited.contains(wheelIndex)) {
        if (hasCycleDFS(wheelIndex)) {
          return true;
        }
      }
    }

    return false;
  }
  /* -------------------------------------------------------------------------------------- */
  /// Gets a topological ordering of the dependency graph.
  /// 
  /// Returns wheels in an order where dependencies come before dependents.
  /// This is useful for batch updates where you want to process wheels
  /// in dependency order.
  /// 
  /// **Returns:** List of wheel indices in topological order, or empty list if cycles exist
  /// 
  /// **Example:**
  /// ```dart
  /// final processingOrder = manager.getTopologicalOrder();
  /// 
  /// // Process wheels in dependency order
  /// for (final wheelIndex in processingOrder) {
  ///   processWheel(wheelIndex);
  /// }
  /// ```
  List<int> getTopologicalOrder() {
    if (hasCircularDependencies()) {
      debugPrint('DependencyManager: Cannot create topological order - circular dependencies exist');
      return [];
    }

    final visited = <int>{};
    final result = <int>[];

    void dfs(int wheelIndex) {
      if (visited.contains(wheelIndex)) {
        return;
      }

      visited.add(wheelIndex);

      // Visit all dependencies first
      final dependency = _dependencies[wheelIndex];
      if (dependency != null) {
        for (final depIndex in dependency.dependsOn) {
          dfs(depIndex);
        }
      }

      // Add current wheel after its dependencies
      result.add(wheelIndex);
    }

    // Process all wheels
    final allWheels = <int>{
      ..._dependencies.keys,
      ..._dependents.keys,
    };

    for (final wheelIndex in allWheels) {
      dfs(wheelIndex);
    }

    return result;
  }
  /* -------------------------------------------------------------------------------------- */
  /// Gets information about the current dependency graph.
  /// 
  /// Returns a map containing statistics and information about the dependency graph
  /// for debugging and monitoring purposes.
  /// 
  /// **Returns:** Map with graph information including:
  /// - `wheelCount`: Number of wheels with dependencies
  /// - `dependencyCount`: Total number of dependency relationships
  /// - `hasCircularDependencies`: Whether circular dependencies exist
  /// - `topologicalOrder`: Topological ordering of wheels (if no cycles)
  /// 
  /// **Example:**
  /// ```dart
  /// final info = manager.getGraphInfo();
  /// print('Dependency graph: ${info['wheelCount']} wheels, ${info['dependencyCount']} dependencies');
  /// 
  /// if (info['hasCircularDependencies'] == true) {
  ///   print('Warning: Circular dependencies detected!');
  /// }
  /// ```
  Map<String, dynamic> getGraphInfo() {
    final dependencyCount = _dependencies.values
        .map((dep) => dep.dependsOn.length)
        .fold(0, (sum, count) => sum + count);

    return {
      'wheelCount': _dependencies.length,
      'dependencyCount': dependencyCount,
      'hasCircularDependencies': hasCircularDependencies(),
      'topologicalOrder': getTopologicalOrder(),
      'dependencies': Map.fromEntries(
        _dependencies.entries.map((e) => MapEntry(e.key, e.value.dependsOn)),
      ),
      'dependents': Map.fromEntries(
        _dependents.entries.map((e) => MapEntry(e.key, e.value.toList())),
      ),
    };
  }
  /* -------------------------------------------------------------------------------------- */
  /// Clears all registered dependencies.
  /// 
  /// This method removes all dependency configurations and cleans up
  /// the internal data structures. Useful for resetting the manager
  /// or when reconfiguring the entire wheel picker.
  /// 
  /// **Example:**
  /// ```dart
  /// // Reset all dependencies
  /// manager.clear();
  /// 
  /// // Register new dependencies
  /// manager.registerDependency(0, newDayDependency);
  /// ```
  void clear() {
    _dependencies.clear();
    _dependents.clear();
    debugPrint('DependencyManager: Cleared all dependencies');
  }
  /* -------------------------------------------------------------------------------------- */
  /// Gets the dependency configuration for a specific wheel.
  /// 
  /// **Parameters:**
  /// - [wheelIndex]: The index of the wheel
  /// 
  /// **Returns:** The dependency configuration, or null if wheel has no dependencies
  /// 
  /// **Example:**
  /// ```dart
  /// final dependency = manager.getDependency(0);
  /// if (dependency != null) {
  ///   print('Day wheel depends on: ${dependency.dependsOn}');
  /// }
  /// ```
  WheelDependency? getDependency(int wheelIndex) {
    return _dependencies[wheelIndex];
  }
  /* -------------------------------------------------------------------------------------- */
  /// Checks if a wheel has any dependencies.
  /// 
  /// **Parameters:**
  /// - [wheelIndex]: The index of the wheel to check
  /// 
  /// **Returns:** `true` if the wheel has dependencies, `false` otherwise
  /// 
  /// **Example:**
  /// ```dart
  /// if (manager.hasDependencies(0)) {
  ///   // Day wheel has dependencies - check for recreation needs
  ///   checkRecreationNeeds(0);
  /// } else {
  ///   // Independent wheel - only update position
  ///   updateWheelPosition(0);
  /// }
  /// ```
  bool hasDependencies(int wheelIndex) {
    return _dependencies.containsKey(wheelIndex);
  }
  /* -------------------------------------------------------------------------------------- */
  /// Checks if a wheel has any dependents (other wheels that depend on it).
  /// 
  /// **Parameters:**
  /// - [wheelIndex]: The index of the wheel to check
  /// 
  /// **Returns:** `true` if other wheels depend on this wheel, `false` otherwise
  /// 
  /// **Example:**
  /// ```dart
  /// if (manager.hasDependents(1)) {
  ///   // Month wheel has dependents - changing it may trigger recreations
  ///   processDependencyBasedRecreation(1);
  /// } else {
  ///   // No dependents - changing this wheel won't affect others
  ///   updateWheelPositionOnly(1);
  /// }
  /// ```
  bool hasDependents(int wheelIndex) {
    return _dependents.containsKey(wheelIndex) && _dependents[wheelIndex]!.isNotEmpty;
  }
  /* -------------------------------------------------------------------------------------- */
  /// Gets the number of wheels that have dependencies.
  /// 
  /// **Returns:** Count of wheels with dependency configurations
  /// 
  /// **Example:**
  /// ```dart
  /// final dependentWheelCount = manager.getDependentWheelCount();
  /// print('$dependentWheelCount wheels have dependencies');
  /// ```
  int getDependentWheelCount() {
    return _dependencies.length;
  }
  /* -------------------------------------------------------------------------------------- */
  /// **FOR TESTING ONLY** - Directly sets a dependency without validation.
  /// 
  /// This method bypasses all validation and is only intended for testing
  /// scenarios where we need to create invalid states (like circular dependencies)
  /// to test the validation logic.
  /// 
  /// **WARNING:** This method should NEVER be used in production code.
  @visibleForTesting
  void setDependencyForTesting(int wheelIndex, WheelDependency dependency) {
    _dependencies[wheelIndex] = dependency;
    
    // Update reverse mapping
    for (final dependencyIndex in dependency.dependsOn) {
      _dependents.putIfAbsent(dependencyIndex, () => <int>{}).add(wheelIndex);
    }
  }
}