import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import '../models/performance_metrics.dart';
import '../models/wheel_state.dart';
import '../models/wheel_config.dart';
import 'dependency_manager.dart';
import 'recreation_decision.dart';
import 'recreation_logic.dart';

/// GetX controller for managing wheel states and selective recreation.
///
/// This class serves as the central state management system for SelectiveWheelPicker,
/// providing advanced features like selective recreation, performance optimization,
/// memory management, and error recovery.
///
/// ## Key Features:
///
/// - **Selective Recreation**: Recreate individual wheels without affecting others
/// - **Performance Optimization**: Controller reuse, throttling, and batching
/// - **Memory Management**: Automatic cleanup and controller pooling
/// - **State Validation**: Built-in consistency checks and repair mechanisms
/// - **Performance Monitoring**: Comprehensive metrics and reporting
///
/// ## Basic Usage:
///
/// ```dart
/// final wheelManager = WheelManager();
///
/// // Initialize with wheel configurations
/// wheelManager.initialize([
///   WheelConfig(itemCount: 24, ...),
///   WheelConfig(itemCount: 60, ...),
/// ]);
///
/// // Use in SelectiveWheelPicker
/// SelectiveWheelPicker(
///   wheels: wheelManager.wheels,
///   wheelManager: wheelManager,
///   onChanged: (indices) { ... },
/// )
///
/// // Recreate a wheel
/// wheelManager.recreateWheel(0, newConfig);
///
/// // Don't forget to dispose
/// wheelManager.dispose();
/// ```
///
/// ## Advanced Usage:
///
/// ```dart
/// // Immediate recreation (bypasses throttling)
/// wheelManager.recreateWheelImmediate(0, newConfig);
///
/// // Batch recreation
/// wheelManager.recreateWheels([0, 1], [config1, config2]);
///
/// // Performance monitoring
/// final report = wheelManager.getPerformanceReport();
/// print('Average recreation time: ${report['averageRecreationTime']}ms');
///
/// // Memory management
/// if (wheelManager.needsMemoryCleanup()) {
///   wheelManager.performMemoryCleanup();
/// }
///
/// // State validation
/// if (!wheelManager.validateStateConsistency()) {
///   wheelManager.repairStateInconsistencies();
/// }
/// ```
///
/// ## Performance Optimizations:
///
/// - **Dependency-Based Recreation**: Only recreates wheels when dependencies actually change
/// - **Intelligent Recreation Logic**: Uses RecreationLogic to determine when recreation is needed
/// - **Controller Reuse**: Scroll controllers are pooled and reused when possible
/// - **Memory Cleanup**: Automatic cleanup of unused resources
///
/// ## Error Recovery:
///
/// - **State Validation**: Automatic detection of inconsistent states
/// - **State Repair**: Automatic repair of common inconsistencies
/// - **Controller Validation**: Detection and handling of disposed controllers
///
/// See also:
/// - [WheelConfig] for wheel configuration
/// - [WheelState] for wheel state representation
/// - [PerformanceMetrics] for performance monitoring
class WheelManager extends GetxController {
  // Reactive lists for wheel management
  final RxList<WheelConfig> _wheels = <WheelConfig>[].obs;
  final RxList<FixedExtentScrollController> _controllers =
      <FixedExtentScrollController>[].obs;
  final RxList<int> _selectedIndices = <int>[].obs;
  final RxList<String> _wheelKeys = <String>[].obs;

  // Performance optimization fields (throttling removed for dependency-based system)
  final PerformanceMetrics _performanceMetrics = PerformanceMetrics();

  // Controller reuse pool for memory optimization
  final List<FixedExtentScrollController> _controllerPool = [];
  static const int _maxControllerPoolSize = 10;

  // Memory management tracking
  int _totalControllersCreated = 0;
  int _totalControllersReused = 0;
  int _totalControllersDisposed = 0;

  // Dependency-based recreation system
  final DependencyManager _dependencyManager = DependencyManager();
  final RecreationLogic _recreationLogic = RecreationLogic();

  // Debounce dependency-based recreations to avoid flicker while user is scrolling
  final Map<int, Timer> _recreationDebounceTimers = {};
  /* -------------------------------------------------------------------------------------- */
  // Getters for accessing reactive data
  List<WheelConfig> get wheels => _wheels;
  List<FixedExtentScrollController> get controllers => _controllers;
  List<int> get selectedIndices => _selectedIndices;
  List<String> get wheelKeys => _wheelKeys;
  PerformanceMetrics get performanceMetrics => _performanceMetrics;
  DependencyManager get dependencyManager => _dependencyManager;
  RecreationLogic get recreationLogic => _recreationLogic;
  /* -------------------------------------------------------------------------------------- */
  /// Initialize the wheel manager with initial configurations
  void initialize(List<WheelConfig> initialWheels) {
    _wheels.clear();
    _controllers.clear();
    _selectedIndices.clear();
    _wheelKeys.clear();
    _dependencyManager.clear();

    for (int i = 0; i < initialWheels.length; i++) {
      final config = initialWheels[i];
      _wheels.add(config);
      _selectedIndices.add(config.initialIndex);
      _wheelKeys.add(config.wheelId ?? 'wheel_$i');
      _createController(i, config);

      // Register dependencies if present
      if (config.dependency != null) {
        try {
          _dependencyManager.registerDependency(
            i,
            config.dependency!,
            totalWheelCount: initialWheels.length,
          );
        } catch (e) {
          debugPrint(
            'WheelManager: Failed to register dependency for wheel $i: $e',
          );
        }
      }
    }

    // Validate dependency graph
    if (!_dependencyManager.validateGraph(
      totalWheelCount: initialWheels.length,
    )) {
      debugPrint('WheelManager: Warning - Invalid dependency graph detected');
    }
  }

  /* -------------------------------------------------------------------------------------- */
  /// Create a new controller for the specified wheel index
  void _createController(int index, WheelConfig config) {
    FixedExtentScrollController controller;

    // Try to reuse a controller from the pool with matching initial item
    final matchingControllerIndex = _controllerPool.indexWhere((c) {
      try {
        return _isControllerValidForReuse(c) &&
            c.initialItem == config.initialIndex;
      } catch (e) {
        return false;
      }
    });

    if (matchingControllerIndex >= 0) {
      controller = _controllerPool.removeAt(matchingControllerIndex);
      _totalControllersReused++;
    } else {
      controller = FixedExtentScrollController(
        initialItem: config.initialIndex,
      );
      _totalControllersCreated++;
    }

    if (index < _controllers.length) {
      _controllers[index] = controller;
    } else {
      _controllers.add(controller);
    }
  }

  /* -------------------------------------------------------------------------------------- */
  /// Check if a controller is valid for reuse
  bool _isControllerValidForReuse(FixedExtentScrollController controller) {
    try {
      // Controller is valid for reuse only if it is not disposed AND not currently attached.
      // Never reuse an attached controller to avoid multi-attachment issues.
      controller.initialItem; // access to verify not disposed
      if (controller.hasClients) {
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /* -------------------------------------------------------------------------------------- */
  /// Dispose a controller at the specified index
  void _disposeController(int index) {
    if (index < _controllers.length && _isControllerValid(index)) {
      final controller = _controllers[index];

      // Do not pool controllers during active rebuild; avoid reusing attached controllers.
      // Dispose safely once the controller is fully detached.
      void safeDispose(FixedExtentScrollController c) {
        try {
          if (!c.hasClients) {
            c.dispose();
            _totalControllersDisposed++;
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) => safeDispose(c));
          }
        } catch (_) {
          // Controller might already be disposed or in an invalid state.
        }
      }

      safeDispose(controller);
    }
  }

  /* -------------------------------------------------------------------------------------- */
  /// Force dispose all controllers in the pool
  void _disposeControllerPool() {
    for (final controller in _controllerPool) {
      try {
        controller.dispose();
        _totalControllersDisposed++;
      } catch (e) {
        // Controller might already be disposed
      }
    }
    _controllerPool.clear();
  }

  /* -------------------------------------------------------------------------------------- */
  /// Trim controller pool to reduce memory usage
  void trimControllerPool({int? maxSize}) {
    final targetSize = maxSize ?? (_maxControllerPoolSize ~/ 2);

    while (_controllerPool.length > targetSize) {
      final controller = _controllerPool.removeAt(0);
      try {
        controller.dispose();
        _totalControllersDisposed++;
      } catch (e) {
        // Controller might already be disposed
      }
    }
  }

  /* -------------------------------------------------------------------------------------- */
  /// Validate if a controller at the specified index is valid and not disposed
  bool _isControllerValid(int index) {
    if (index < 0 || index >= _controllers.length) {
      return false;
    }

    try {
      // Try to access a property to check if controller is disposed
      final controller = _controllers[index];
      // If we can access the initialItem, the controller is likely valid
      controller.initialItem;
      return true;
    } catch (e) {
      // Controller is likely disposed or invalid
      return false;
    }
  }

  /* -------------------------------------------------------------------------------------- */
  /// Check if all controllers are in a valid state
  bool areAllControllersValid() {
    for (int i = 0; i < _controllers.length; i++) {
      if (!_isControllerValid(i)) {
        return false;
      }
    }
    return true;
  }

  /* -------------------------------------------------------------------------------------- */
  /// Get the count of valid controllers
  int getValidControllerCount() {
    int count = 0;
    for (int i = 0; i < _controllers.length; i++) {
      if (_isControllerValid(i)) {
        count++;
      }
    }
    return count;
  }

  /* -------------------------------------------------------------------------------------- */
  /// Recreate a single wheel with new configuration using dependency-based logic
  void recreateWheel(int index, WheelConfig newConfig) {
    if (index < 0 || index >= _wheels.length) {
      debugPrint('WheelManager: Invalid wheel index $index for recreation');
      return;
    }

    // Use dependency-based recreation logic instead of throttling
    final decision = _recreationLogic.shouldRecreateWheel(
      wheelIndex: index,
      currentConfig: _wheels[index],
      allSelections: _selectedIndices,
      dependencyManager: _dependencyManager,
    );

    if (decision.needsRecreation &&
        _recreationLogic.validateRecreationDecision(decision, _wheels.length)) {
      _performImmediateRecreation(index, decision.newConfig ?? newConfig);
    } else {
      // IMPORTANT:
      // Avoid applying structural changes (itemCount/wheelId/initialIndex) without recreation.
      // If a dependency-aware proposal indicates a structural change, perform immediate recreation.
      final currentConfig = _wheels[index];

      // Try to derive a dependency-aware proposed config based on current selections
      final proposed = _dependencyManager.calculateNewConfig(
        index,
        currentConfig,
        _selectedIndices,
      );

      // If proposed requires recreation, do it now to prevent flicker loops.
      List<int>? depVals;
      if (currentConfig.dependency != null) {
        depVals = _selectedIndices;
      }
      if (proposed != null &&
          currentConfig.needsRecreation(
            proposed,
            currentDependencyValues: depVals,
          )) {
        _performImmediateRecreation(index, proposed);
        return;
      }

      // Otherwise, apply only non-structural updates (formatter/callbacks/separators/width).
      final safeConfig = currentConfig.copyWith(
        formatter: (proposed ?? newConfig).formatter,
        width: (proposed ?? newConfig).width,
        onChanged: (proposed ?? newConfig).onChanged,
        leadingSeparator: (proposed ?? newConfig).leadingSeparator,
        trailingSeparator: (proposed ?? newConfig).trailingSeparator,
        // Keep itemCount, initialIndex, wheelId, dependency unchanged for non-structural update
      );

      _wheels[index] = safeConfig;
      debugPrint(
        'WheelManager: Updated non-structural config without recreation for wheel $index',
      );
    }
  }

  /* -------------------------------------------------------------------------------------- */
  /// Process dependency-based recreation for a specific wheel change (immediate)
  ///
  /// Execute immediately so tests and tight loops observe actual recreations.
  /// The previous debounce caused tests (that use pump() without advancing time)
  /// to miss recreations, resulting in false negatives.
  void _processDependencyBasedRecreation(int changedWheelIndex) {
    // Cancel any pending run for this driver wheel
    _recreationDebounceTimers[changedWheelIndex]?.cancel();
    _recreationDebounceTimers.remove(changedWheelIndex);

    // Execute immediately to reflect current state
    _executeDependencyBasedRecreation(changedWheelIndex);
  }

  /// Execute dependency-based recreation immediately (internal)
  void _executeDependencyBasedRecreation(int changedWheelIndex) {
    final stopwatch = Stopwatch()..start();

    try {
      // Determine dependents of the changed wheel
      final dependents = _dependencyManager.getDependentWheels(
        changedWheelIndex,
      );

      if (dependents.isEmpty) {
        stopwatch.stop();
        _performanceMetrics.recordRecreation(stopwatch.elapsed);
        return;
      }

      // Order dependents so that dependencies are processed before their dependents.
      final topo = _dependencyManager.getTopologicalOrder();
      final ordered = <int>[];
      for (final idx in topo) {
        if (dependents.contains(idx)) {
          ordered.add(idx);
        }
      }
      // Fallback: if topo couldn't be created, keep the original set order
      if (ordered.isEmpty) {
        ordered.addAll(dependents);
      }

      int recreationCount = 0;
      int updatedCount = 0;

      // Process sequentially so that downstream dependents (e.g., day) see the
      // latest selections from upstream dependents (e.g., month/year).
      for (final idx in ordered) {
        if (idx < 0 || idx >= _wheels.length) continue;

        final decision = _recreationLogic.shouldRecreateWheel(
          wheelIndex: idx,
          currentConfig: _wheels[idx],
          allSelections: _selectedIndices,
          dependencyManager: _dependencyManager,
        );

        if (decision.needsRecreation &&
            _recreationLogic.validateRecreationDecision(
              decision,
              _wheels.length,
            )) {
          _performImmediateRecreation(idx, decision.newConfig!);
          recreationCount++;
        } else {
          // Apply dependency-aware updates carefully: if structural, recreate; else non-structural update
          final currentConfig = _wheels[idx];
          final proposed = _dependencyManager.calculateNewConfig(
            idx,
            currentConfig,
            _selectedIndices,
          );

          List<int>? depVals;
          if (currentConfig.dependency != null) {
            depVals = _selectedIndices;
          }

          if (proposed != null &&
              currentConfig.needsRecreation(
                proposed,
                currentDependencyValues: depVals,
              )) {
            _performImmediateRecreation(idx, proposed);
            recreationCount++;
          } else if (proposed != null) {
            final safeConfig = currentConfig.copyWith(
              formatter: proposed.formatter,
              width: proposed.width,
              onChanged: proposed.onChanged,
              leadingSeparator: proposed.leadingSeparator,
              trailingSeparator: proposed.trailingSeparator,
            );
            _wheels[idx] = safeConfig;
            updatedCount++;
          }
        }
      }

      if (recreationCount > 0 || updatedCount > 0) {
        debugPrint(
          'WheelManager: Processed dependency changes (ordered) - '
          'recreated: $recreationCount, updated: $updatedCount',
        );
      }
    } catch (e) {
      debugPrint('WheelManager: Error in dependency-based recreation: $e');
    }

    stopwatch.stop();
    _performanceMetrics.recordRecreation(stopwatch.elapsed);
  }

  /* -------------------------------------------------------------------------------------- */
  /// Perform immediate recreation without throttling
  void _performImmediateRecreation(int index, WheelConfig newConfig) {
    if (index < 0 || index >= _wheels.length) {
      return;
    }

    final currentConfig = _wheels[index];

    // Use dependency-aware recreation check
    List<int>? dependencyValues;
    if (currentConfig.dependency != null) {
      dependencyValues = _selectedIndices;
    }

    if (!currentConfig.needsRecreation(
      newConfig,
      currentDependencyValues: dependencyValues,
    )) {
      return; // No recreation needed
    }

    // Dispose old controller
    _disposeController(index);

    // Update dependency registration if changed
    if (currentConfig.dependency != newConfig.dependency) {
      _dependencyManager.unregisterDependency(index);
      if (newConfig.dependency != null) {
        try {
          _dependencyManager.registerDependency(
            index,
            newConfig.dependency!,
            totalWheelCount: _wheels.length,
          );
        } catch (e) {
          debugPrint(
            'WheelManager: Failed to register new dependency for wheel $index: $e',
          );
        }
      }
    }

    // Update configuration
    _wheels[index] = newConfig;
    _wheelKeys[index] = newConfig.wheelId ?? 'wheel_$index';

    // Create new controller
    _createController(index, newConfig);

    // Update selected index if needed
    if (newConfig.initialIndex != _selectedIndices[index]) {
      _selectedIndices[index] = newConfig.initialIndex;
    }
  }

  /* -------------------------------------------------------------------------------------- */
  /// Recreate a single wheel immediately without throttling (for urgent updates)
  void recreateWheelImmediate(int index, WheelConfig newConfig) {
    final stopwatch = Stopwatch()..start();
    _performImmediateRecreation(index, newConfig);
    stopwatch.stop();
    _performanceMetrics.recordRecreation(stopwatch.elapsed);
  }

  /* -------------------------------------------------------------------------------------- */
  /// Recreate multiple wheels using dependency-based logic
  void recreateWheels(List<int> indices, List<WheelConfig> newConfigs) {
    if (indices.length != newConfigs.length) {
      throw ArgumentError(
        'Indices and configs lists must have the same length',
      );
    }

    final stopwatch = Stopwatch()..start();

    try {
      // Get recreation decisions for all requested wheels
      final decisions = <RecreationDecision>[];

      for (int i = 0; i < indices.length; i++) {
        final wheelIndex = indices[i];
        final newConfig = newConfigs[i];

        final decision = _recreationLogic.shouldRecreateWheel(
          wheelIndex: wheelIndex,
          currentConfig: wheelIndex < _wheels.length
              ? _wheels[wheelIndex]
              : newConfig,
          allSelections: _selectedIndices,
          dependencyManager: _dependencyManager,
        );

        decisions.add(decision);
      }

      // Process only wheels that actually need recreation
      int recreationCount = 0;
      for (int i = 0; i < decisions.length; i++) {
        final decision = decisions[i];
        final wheelIndex = indices[i];
        final parentConfig = newConfigs[i];

        if (decision.needsRecreation &&
            _recreationLogic.validateRecreationDecision(
              decision,
              _wheels.length,
            )) {
          _performImmediateRecreation(
            wheelIndex,
            decision.newConfig ?? parentConfig,
          );
          recreationCount++;
        } else if (wheelIndex >= 0 && wheelIndex < _wheels.length) {
          // Try a dependency-aware proposal for the current selections
          final currentConfig = _wheels[wheelIndex];
          final proposed = _dependencyManager.calculateNewConfig(
            wheelIndex,
            currentConfig,
            _selectedIndices,
          );

          List<int>? depVals;
          if (currentConfig.dependency != null) {
            depVals = _selectedIndices;
          }

          if (proposed != null &&
              currentConfig.needsRecreation(
                proposed,
                currentDependencyValues: depVals,
              )) {
            _performImmediateRecreation(wheelIndex, proposed);
            recreationCount++;
          } else {
            // Apply only non-structural updates
            final source = proposed ?? parentConfig;
            final safeConfig = currentConfig.copyWith(
              formatter: source.formatter,
              width: source.width,
              onChanged: source.onChanged,
              leadingSeparator: source.leadingSeparator,
              trailingSeparator: source.trailingSeparator,
            );
            _wheels[wheelIndex] = safeConfig;
          }
        }
      }

      debugPrint(
        'WheelManager: Batch recreation completed - $recreationCount of ${indices.length} wheels recreated/updated',
      );
    } catch (e) {
      debugPrint('WheelManager: Error in batch recreation: $e');
    }

    stopwatch.stop();
    _performanceMetrics.recordRecreation(stopwatch.elapsed);
  }

  /* -------------------------------------------------------------------------------------- */
  /// Recreate multiple wheels immediately without throttling
  void recreateWheelsImmediate(
    List<int> indices,
    List<WheelConfig> newConfigs,
  ) {
    if (indices.length != newConfigs.length) {
      throw ArgumentError(
        'Indices and configs lists must have the same length',
      );
    }

    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < indices.length; i++) {
      _performImmediateRecreation(indices[i], newConfigs[i]);
    }

    stopwatch.stop();
    _performanceMetrics.recordRecreation(stopwatch.elapsed);
    _performanceMetrics.recordBatchedRecreation();
  }

  /* -------------------------------------------------------------------------------------- */
  /// Update wheel configuration without recreation if possible
  void updateWheelConfig(int index, WheelConfig newConfig) {
    if (index < 0 || index >= _wheels.length) {
      return;
    }

    final currentConfig = _wheels[index];

    // Use dependency-aware recreation check
    List<int>? dependencyValues;
    if (currentConfig.dependency != null) {
      dependencyValues = _selectedIndices;
    }

    if (currentConfig.needsRecreation(
      newConfig,
      currentDependencyValues: dependencyValues,
    )) {
      recreateWheel(index, newConfig);
    } else {
      // IMPORTANT for dependent wheels:
      // When no recreation is needed, keep structural fields (itemCount, initialIndex, wheelId, dependency)
      // and apply only non-structural updates (formatter, callbacks, separators, width).
      final safeConfig = currentConfig.copyWith(
        formatter: newConfig.formatter,
        width: newConfig.width,
        onChanged: newConfig.onChanged,
        leadingSeparator: newConfig.leadingSeparator,
        trailingSeparator: newConfig.trailingSeparator,
        // Preserve itemCount, initialIndex, wheelId, dependency to avoid oscillation
      );
      _wheels[index] = safeConfig;

      // Update dependency registration only if the dependency object actually changed in a structural path
      if (currentConfig.dependency != newConfig.dependency) {
        _dependencyManager.unregisterDependency(index);
        if (newConfig.dependency != null) {
          try {
            _dependencyManager.registerDependency(
              index,
              newConfig.dependency!,
              totalWheelCount: _wheels.length,
            );
          } catch (e) {
            debugPrint(
              'WheelManager: Failed to register new dependency for wheel $index: $e',
            );
          }
        }
      }
    }
  }

  /* -------------------------------------------------------------------------------------- */
  /// Check if a wheel needs recreation based on dependency-driven logic
  bool needsRecreation(int wheelIndex) {
    if (wheelIndex < 0 || wheelIndex >= _wheels.length) {
      return false;
    }

    final decision = _recreationLogic.shouldRecreateWheel(
      wheelIndex: wheelIndex,
      currentConfig: _wheels[wheelIndex],
      allSelections: _selectedIndices,
      dependencyManager: _dependencyManager,
    );

    return decision.needsRecreation;
  }

  /* -------------------------------------------------------------------------------------- */
  /// Get recreation decision for a specific wheel
  RecreationDecision getRecreationDecision(int wheelIndex) {
    if (wheelIndex < 0 || wheelIndex >= _wheels.length) {
      return RecreationDecision(
        wheelIndex: wheelIndex,
        needsRecreation: false,
        newConfig: null,
        reason: 'Invalid wheel index',
      );
    }

    return _recreationLogic.shouldRecreateWheel(
      wheelIndex: wheelIndex,
      currentConfig: _wheels[wheelIndex],
      allSelections: _selectedIndices,
      dependencyManager: _dependencyManager,
    );
  }

  /* -------------------------------------------------------------------------------------- */
  /// Get recreation decisions for all wheels
  List<RecreationDecision> getAllRecreationDecisions() {
    return _recreationLogic.shouldRecreateWheels(
      wheelConfigs: _wheels,
      allSelections: _selectedIndices,
      dependencyManager: _dependencyManager,
    );
  }

  /* -------------------------------------------------------------------------------------- */
  /// Recreate all wheels that need recreation based on current state
  void recreateWheelsAsNeeded() {
    final decisions = getAllRecreationDecisions();

    for (final decision in decisions) {
      if (decision.needsRecreation &&
          _recreationLogic.validateRecreationDecision(
            decision,
            _wheels.length,
          )) {
        debugPrint(
          'WheelManager: Auto-recreating wheel ${decision.wheelIndex}: ${decision.reason}',
        );
        _performImmediateRecreation(decision.wheelIndex, decision.newConfig!);
      }
    }

    final stats = _recreationLogic.getRecreationStats(decisions);
    if (stats['recreationCount'] > 0) {
      debugPrint(
        'WheelManager: Auto-recreation completed - '
        '${stats['recreationCount']} of ${stats['totalWheels']} wheels recreated',
      );
    }
  }

  /* -------------------------------------------------------------------------------------- */
  /// Update selected index for a wheel and handle dependency-based recreation
  void updateSelectedIndex(int wheelIndex, int selectedIndex) {
    if (wheelIndex >= 0 && wheelIndex < _selectedIndices.length) {
      final oldSelection = _selectedIndices[wheelIndex];
      _selectedIndices[wheelIndex] = selectedIndex;

      // Check if any dependent wheels need recreation
      if (oldSelection != selectedIndex) {
        _processDependencyBasedRecreation(wheelIndex);
      }
    }
  }

  /* -------------------------------------------------------------------------------------- */
  /// Update wheel position without recreation (for smooth scrolling)
  void updateWheelPosition(int wheelIndex, int newPosition) {
    if (wheelIndex >= 0 && wheelIndex < _selectedIndices.length) {
      // Only update position if wheel has no dependencies or doesn't need recreation
      if (!_dependencyManager.hasDependencies(wheelIndex)) {
        _selectedIndices[wheelIndex] = newPosition;
        debugPrint(
          'WheelManager: Updated position for independent wheel $wheelIndex to $newPosition',
        );
      } else {
        // For dependent wheels, check if recreation is needed
        updateSelectedIndex(wheelIndex, newPosition);
      }
    }
  }

  /* -------------------------------------------------------------------------------------- */
  /// Update wheel selection with real-time visual updates without recreation
  ///
  /// This method provides smooth scrolling by updating the controller position
  /// directly without disposing/creating controllers. It's optimized for
  /// independent wheels that don't trigger recreations.
  ///
  /// WARNING:
  /// - Do NOT call this from onSelectedItemChanged handlers (i.e., user-driven scroll).
  ///   ListWheelScrollView already applies snapping physics; forcing jumpToItem/animateToItem
  ///   during a fling will fight the physics and cause visible jank/stutter.
  /// - Use this ONLY for programmatic position changes (e.g., external API calls),
  ///   not as part of the regular user scroll update loop.
  /// - For user-driven updates, prefer updateSelectedIndex() so dependent wheels can
  ///   recreate as needed while preserving the native scroll physics.
  ///
  /// **Parameters:**
  /// - [wheelIndex]: Index of the wheel to update
  /// - [newSelection]: New selection index
  /// - [animateToPosition]: Whether to animate to the new position (default: false for smooth scrolling)
  ///
  /// **Performance:** This method avoids controller disposal/creation cycles
  /// and provides real-time visual updates for smooth user experience.
  void updateWheelSelectionWithVisualUpdate(
    int wheelIndex,
    int newSelection, {
    bool animateToPosition = false,
  }) {
    if (wheelIndex < 0 || wheelIndex >= _selectedIndices.length) {
      return;
    }

    // Update selection index
    _selectedIndices[wheelIndex] = newSelection;

    // Update controller position for real-time visual feedback
    if (wheelIndex < _controllers.length && _isControllerValid(wheelIndex)) {
      final controller = _controllers[wheelIndex];

      try {
        // Check if controller has clients (is attached to a widget)
        if (controller.hasClients) {
          if (animateToPosition) {
            // Animate to new position for smooth transition
            controller.animateToItem(
              newSelection,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
            );
          } else {
            // Jump to position immediately for real-time updates
            controller.jumpToItem(newSelection);
          }
        }
      } catch (e) {
        debugPrint(
          'WheelManager: Failed to update controller position for wheel $wheelIndex: $e',
        );
      }
    }

    // For smooth visual updates, DO NOT trigger dependency-based recreation here.
    // This keeps scrolling smooth and avoids controller churn. For user-driven
    // updates that should propagate to dependents, use updateSelectedIndex().
  }

  /* -------------------------------------------------------------------------------------- */
  /// Update multiple wheel positions simultaneously for batch operations
  ///
  /// This method efficiently handles batch position updates while maintaining
  /// smooth scrolling performance.
  ///
  /// **Parameters:**
  /// - [updates]: Map of wheel indices to new selection values
  /// - [animateToPosition]: Whether to animate to new positions
  void updateMultipleWheelPositions(
    Map<int, int> updates, {
    bool animateToPosition = false,
  }) {
    if (updates.isEmpty) return;

    final stopwatch = Stopwatch()..start();

    try {
      // Track which wheels changed for dependency processing
      final changedWheels = <int>[];

      // Update all positions first
      for (final entry in updates.entries) {
        final wheelIndex = entry.key;
        final newSelection = entry.value;

        if (wheelIndex >= 0 && wheelIndex < _selectedIndices.length) {
          final oldSelection = _selectedIndices[wheelIndex];

          // Update selection
          _selectedIndices[wheelIndex] = newSelection;

          // Update controller position
          if (wheelIndex < _controllers.length &&
              _isControllerValid(wheelIndex)) {
            final controller = _controllers[wheelIndex];

            try {
              if (controller.hasClients) {
                if (animateToPosition) {
                  controller.animateToItem(
                    newSelection,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                  );
                } else {
                  controller.jumpToItem(newSelection);
                }
              }
            } catch (e) {
              debugPrint(
                'WheelManager: Failed to update controller position for wheel $wheelIndex: $e',
              );
            }
          }

          // Track changed wheels for dependency processing
          if (oldSelection != newSelection) {
            changedWheels.add(wheelIndex);
          }
        }
      }

      // Process dependencies for all changed wheels
      for (final wheelIndex in changedWheels) {
        if (_dependencyManager.hasDependents(wheelIndex)) {
          _processDependencyBasedRecreation(wheelIndex);
        }
      }

      debugPrint(
        'WheelManager: Batch position update completed for ${updates.length} wheels',
      );
    } catch (e) {
      debugPrint('WheelManager: Error in batch position update: $e');
    }

    stopwatch.stop();
    _performanceMetrics.recordRecreation(stopwatch.elapsed);
  }

  /* -------------------------------------------------------------------------------------- */
  /// Check if a controller can be updated without recreation
  ///
  /// This method validates that a controller is in a state where position
  /// updates can be performed safely.
  ///
  /// **Parameters:**
  /// - [wheelIndex]: Index of the wheel to check
  ///
  /// **Returns:** `true` if the controller can be updated safely
  bool canUpdateControllerPosition(int wheelIndex) {
    if (wheelIndex < 0 || wheelIndex >= _controllers.length) {
      return false;
    }

    if (!_isControllerValid(wheelIndex)) {
      return false;
    }

    try {
      final controller = _controllers[wheelIndex];
      return controller.hasClients;
    } catch (e) {
      return false;
    }
  }

  /* -------------------------------------------------------------------------------------- */
  /// Get current controller position for a wheel
  ///
  /// **Parameters:**
  /// - [wheelIndex]: Index of the wheel
  ///
  /// **Returns:** Current controller position or null if unavailable
  int? getCurrentControllerPosition(int wheelIndex) {
    if (!canUpdateControllerPosition(wheelIndex)) {
      return null;
    }

    try {
      final controller = _controllers[wheelIndex];
      return controller.selectedItem;
    } catch (e) {
      return null;
    }
  }

  /* -------------------------------------------------------------------------------------- */
  /// Get the current state of a specific wheel
  WheelState? getWheelState(int index) {
    if (index < 0 || index >= _wheels.length) {
      return null;
    }

    return WheelState(
      wheelId: _wheelKeys[index],
      selectedIndex: _selectedIndices[index],
      controller: _controllers[index],
      config: _wheels[index],
    );
  }

  /* -------------------------------------------------------------------------------------- */
  /// Check if any wheels need recreation
  bool hasWheelsNeedingRecreation() {
    // This method can be extended to track recreation state
    return false;
  }

  /* -------------------------------------------------------------------------------------- */
  /// Validate state consistency across all wheels
  bool validateStateConsistency() {
    // Check if all lists have the same length
    if (_wheels.length != _controllers.length ||
        _wheels.length != _selectedIndices.length ||
        _wheels.length != _wheelKeys.length) {
      return false;
    }

    // Check if all controllers are valid
    if (!areAllControllersValid()) {
      return false;
    }

    // Check if selected indices are within valid ranges
    for (int i = 0; i < _wheels.length; i++) {
      final selectedIndex = _selectedIndices[i];
      final itemCount = _wheels[i].itemCount;
      if (selectedIndex < 0 || selectedIndex >= itemCount) {
        return false;
      }
    }

    return true;
  }

  /* -------------------------------------------------------------------------------------- */
  /// Repair state inconsistencies if possible
  bool repairStateInconsistencies() {
    try {
      // Trim lists to the minimum valid length
      final minValidLength = _wheels.length;

      if (_controllers.length > minValidLength) {
        // Dispose extra controllers (add to pool if possible)
        for (int i = minValidLength; i < _controllers.length; i++) {
          if (_isControllerValid(i)) {
            final controller = _controllers[i];
            if (_controllerPool.length < _maxControllerPoolSize &&
                _isControllerValidForReuse(controller)) {
              _controllerPool.add(controller);
            } else {
              controller.dispose();
              _totalControllersDisposed++;
            }
          }
        }
        _controllers.removeRange(minValidLength, _controllers.length);
      }

      if (_selectedIndices.length > minValidLength) {
        _selectedIndices.removeRange(minValidLength, _selectedIndices.length);
      }

      if (_wheelKeys.length > minValidLength) {
        _wheelKeys.removeRange(minValidLength, _wheelKeys.length);
      }

      // Fix selected indices that are out of range
      for (int i = 0; i < _wheels.length; i++) {
        final itemCount = _wheels[i].itemCount;
        if (i < _selectedIndices.length) {
          if (_selectedIndices[i] >= itemCount) {
            _selectedIndices[i] = itemCount - 1;
          } else if (_selectedIndices[i] < 0) {
            _selectedIndices[i] = 0;
          }
        }
      }

      return validateStateConsistency();
    } catch (e) {
      return false;
    }
  }

  /* -------------------------------------------------------------------------------------- */
  /// Force recreation check for all wheels based on current dependencies
  void validateAndRecreateWheelsAsNeeded() {
    final decisions = _recreationLogic.shouldRecreateWheels(
      wheelConfigs: _wheels,
      allSelections: _selectedIndices,
      dependencyManager: _dependencyManager,
    );

    int recreationCount = 0;
    for (final decision in decisions) {
      if (decision.needsRecreation &&
          _recreationLogic.validateRecreationDecision(
            decision,
            _wheels.length,
          )) {
        _performImmediateRecreation(decision.wheelIndex, decision.newConfig!);
        recreationCount++;
      }
    }

    if (recreationCount > 0) {
      debugPrint(
        'WheelManager: Validation completed - $recreationCount wheels recreated',
      );
    }
  }

  /* -------------------------------------------------------------------------------------- */
  /// Get performance monitoring data
  Map<String, dynamic> getPerformanceReport() {
    final dependencyGraphInfo = _dependencyManager.getGraphInfo();
    final currentDecisions = getAllRecreationDecisions();
    final recreationStats = _recreationLogic.getRecreationStats(
      currentDecisions,
    );

    return {
      'recreationCount': _performanceMetrics.recreationCount,
      'batchedRecreationCount': _performanceMetrics.batchedRecreationCount,
      'averageRecreationTime': _performanceMetrics.averageRecreationTime,
      'totalRecreationTime':
          _performanceMetrics.totalRecreationTime.inMilliseconds,
      'lastRecreationTime': _performanceMetrics.lastRecreationTime
          ?.toIso8601String(),
      'controllerPoolSize': _controllerPool.length,
      'totalControllersCreated': _totalControllersCreated,
      'totalControllersReused': _totalControllersReused,
      'totalControllersDisposed': _totalControllersDisposed,
      'controllerReuseRate': _totalControllersCreated > 0
          ? (_totalControllersReused /
                    (_totalControllersCreated + _totalControllersReused)) *
                100
          : 0.0,
      // Dependency-based recreation metrics
      'dependencyGraph': dependencyGraphInfo,
      'currentRecreationNeeds': recreationStats,
      'dependentWheelCount': _dependencyManager.getDependentWheelCount(),
      'hasCircularDependencies': dependencyGraphInfo['hasCircularDependencies'],
      'dependencyBasedRecreationEnabled': true,
      'throttlingDisabled': true,
    };
  }

  /* -------------------------------------------------------------------------------------- */
  /// Get memory usage statistics
  Map<String, dynamic> getMemoryStats() {
    return {
      'activeControllers': _controllers.length,
      'pooledControllers': _controllerPool.length,
      'totalWheels': _wheels.length,
      'memoryEfficiencyScore': _calculateMemoryEfficiencyScore(),
    };
  }

  /* -------------------------------------------------------------------------------------- */
  /// Calculate a memory efficiency score (0-100)
  ///
  /// Prioritizes stability for scenarios with no recreations:
  /// - Stable active controller count matching wheel count
  /// - No controller disposals
  /// - Low pool utilization
  /// Reuse is still rewarded when present.
  double _calculateMemoryEfficiencyScore() {
    final totalControllers = _totalControllersCreated + _totalControllersReused;
    final reuseRate = totalControllers > 0
        ? (_totalControllersReused / totalControllers)
        : 0.0;

    final poolUtilization = _maxControllerPoolSize > 0
        ? (_controllerPool.length / _maxControllerPoolSize)
        : 0.0;

    final expectedControllers = _wheels.length;
    final activeControllers = _controllers.length;
    final hasStableCount =
        expectedControllers > 0 && activeControllers == expectedControllers;
    final noDisposals = _totalControllersDisposed == 0;

    // Stability score in [0,1]
    double stabilityScore = 0.0;
    if (expectedControllers == 0) {
      stabilityScore = 1.0;
    } else {
      final countDelta = (activeControllers - expectedControllers)
          .abs()
          .toDouble();
      final countMatch = hasStableCount
          ? 1.0
          : (1.0 - (countDelta / expectedControllers.toDouble())).clamp(
              0.0,
              1.0,
            );

      final disposalDenom = (totalControllers > 0 ? totalControllers : 1)
          .toDouble();
      final disposalHealth = noDisposals
          ? 1.0
          : (1.0 - (_totalControllersDisposed.toDouble() / disposalDenom))
                .clamp(0.0, 1.0);

      // Weight: count match 70%, disposal health 30%
      stabilityScore = (countMatch * 0.7) + (disposalHealth * 0.3);
    }

    // Weights: stability 40%, reuse 40%, pool efficiency 20%
    final score =
        (stabilityScore * 40) + (reuseRate * 40) + ((1 - poolUtilization) * 20);

    return score.clamp(0.0, 100.0);
  }

  /* -------------------------------------------------------------------------------------- */
  /// Reset performance metrics
  void resetPerformanceMetrics() {
    _performanceMetrics.reset();
  }

  /* -------------------------------------------------------------------------------------- */
  /// Clean up controller pool
  void cleanupControllerPool() {
    _disposeControllerPool();
  }

  /* -------------------------------------------------------------------------------------- */
  /// Perform memory cleanup and optimization
  void performMemoryCleanup() {
    // Trim controller pool to half size
    trimControllerPool();

    // Reset performance metrics if they're getting too large
    if (_performanceMetrics.recreationDurations.length > 50) {
      final recentDurations = _performanceMetrics.recreationDurations
          .skip(_performanceMetrics.recreationDurations.length - 25)
          .toList();
      _performanceMetrics.recreationDurations.clear();
      _performanceMetrics.recreationDurations.addAll(recentDurations);
    }
  }

  /* -------------------------------------------------------------------------------------- */
  /// Check if memory cleanup is needed
  bool needsMemoryCleanup() {
    return _controllerPool.length > (_maxControllerPoolSize * 0.8) ||
        _performanceMetrics.recreationDurations.length > 100 ||
        _performanceMetrics.recreationCount > 50;
  }

  /* -------------------------------------------------------------------------------------- */
  /// Auto-cleanup memory if needed
  void autoCleanupMemory() {
    if (needsMemoryCleanup()) {
      performMemoryCleanup();
    }
  }

  /* -------------------------------------------------------------------------------------- */
  /// Check if dependency-based recreation is enabled
  bool get isDependencyBasedRecreationEnabled => true;
  /* -------------------------------------------------------------------------------------- */
  /// Get dependency manager for external access
  DependencyManager get dependencyManagerInstance => _dependencyManager;
  /* -------------------------------------------------------------------------------------- */
  @override
  void onClose() {
    // Clear dependency manager
    _dependencyManager.clear();

    // Dispose all controllers when the manager is closed
    for (final controller in _controllers) {
      try {
        controller.dispose();
        _totalControllersDisposed++;
      } catch (e) {
        // Controller might already be disposed
      }
    }
    _controllers.clear();

    // Dispose controller pool
    _disposeControllerPool();

    // Clear all reactive lists
    _wheels.clear();
    _selectedIndices.clear();
    _wheelKeys.clear();

    super.onClose();
  }
}
