import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/recreation_decision.dart';
import '../../controllers/wheel_manager.dart';
import '../../models/wheel_state.dart';
import '../../models/wheel_config.dart';
import '../core/wheel_picker.dart';
import '../../utils/functions.dart';

/// A wheel picker widget that supports selective recreation of individual wheels
/// without affecting the scroll state of other wheels.
///
/// This widget extends the functionality of traditional wheel pickers by allowing
/// individual wheels to be recreated with new configurations while preserving
/// the scroll state and user interaction of other wheels. This is particularly
/// useful for dynamic content scenarios like date pickers where the day wheel
/// needs to update based on month/year selection.
///
/// ## Key Features:
///
/// - **Selective Recreation**: Individual wheels can be recreated without affecting others
/// - **State Management**: Integration with GetX for reactive state management
/// - **Performance Optimization**: Controller reuse, throttling, and memory management
/// - **Error Recovery**: Built-in state validation and automatic recovery
/// - **External Control**: Optional external WheelManager for advanced scenarios
///
/// ## Basic Usage:
///
/// ```dart
/// SelectiveWheelPicker(
///   wheels: [
///     WheelConfig(
///       itemCount: 24,
///       initialIndex: 0,
///       formatter: (i) => i.toString().padLeft(2, '0'),
///       width: 60,
///       wheelId: 'hour_wheel',
///     ),
///     WheelConfig(
///       itemCount: 60,
///       initialIndex: 0,
///       formatter: (i) => i.toString().padLeft(2, '0'),
///       width: 60,
///       wheelId: 'minute_wheel',
///     ),
///   ],
///   onChanged: (indices) {
///     final hour = indices[0];
///     final minute = indices[1];
///     // Handle time change
///   },
/// )
/// ```
///
/// ## Selective Recreation:
///
/// ```dart
/// final GlobalKey pickerKey = GlobalKey();
///
/// // Later, recreate a specific wheel
/// SelectiveWheelPicker.recreateWheelByKey(
///   pickerKey,
///   0, // wheel index
///   WheelConfig(
///     itemCount: 30, // new item count
///     initialIndex: 0,
///     formatter: (i) => (i + 1).toString(),
///     width: 60,
///     wheelId: 'updated_wheel',
///   ),
/// );
/// ```
///
/// ## External Management:
///
/// ```dart
/// final wheelManager = WheelManager();
///
/// SelectiveWheelPicker(
///   wheels: myWheels,
///   wheelManager: wheelManager, // External control
///   onChanged: myCallback,
/// )
///
/// // Control externally
/// wheelManager.recreateWheel(0, newConfig);
/// ```
///
/// See also:
/// - [WheelConfig] for wheel configuration options
/// - [WheelManager] for advanced state management
/// - [WheelSeparators] for common separator widgets
class SelectiveWheelPickerBuilder extends StatefulWidget {
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
  final WheelManager? wheelManager; // Optional external manager
  /* -------------------------------------------------------------------------------------- */
  const SelectiveWheelPickerBuilder({
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
    this.wheelManager,
  });
  /* -------------------------------------------------------------------------------------- */
  @override
  State<SelectiveWheelPickerBuilder> createState() => _SelectiveWheelPickerBuilderState();
  /* -------------------------------------------------------------------------------------- */
  /// Recreates a single wheel using a GlobalKey reference.
  ///
  /// This static method allows external code to trigger selective recreation
  /// of a specific wheel without having direct access to the widget's state.
  ///
  /// **Parameters:**
  /// - [key]: GlobalKey of the SelectiveWheelPicker widget
  /// - [index]: Index of the wheel to recreate (0-based)
  /// - [newConfig]: New configuration for the wheel
  ///
  /// **Example:**
  /// ```dart
  /// final GlobalKey pickerKey = GlobalKey();
  ///
  /// // In your SelectiveWheelPicker
  /// SelectiveWheelPicker(
  ///   key: pickerKey,
  ///   wheels: myWheels,
  ///   onChanged: myCallback,
  /// )
  ///
  /// // Later, recreate the first wheel
  /// SelectiveWheelPicker.recreateWheelByKey(
  ///   pickerKey,
  ///   0,
  ///   WheelConfig(
  ///     itemCount: 30,
  ///     initialIndex: 0,
  ///     formatter: (i) => (i + 1).toString(),
  ///     width: 60,
  ///     wheelId: 'updated_day_wheel',
  ///   ),
  /// );
  /// ```
  ///
  /// **Note:** This method will silently fail if the key doesn't reference
  /// a valid SelectiveWheelPicker widget or if the index is out of bounds.
  static void recreateWheelByKey(
    GlobalKey key,
    int index,
    WheelConfig newConfig,
  ) {
    final state = key.currentState as _SelectiveWheelPickerBuilderState?;
    state?.recreateWheel(index, newConfig);
  }
  /* -------------------------------------------------------------------------------------- */
  /// Recreates multiple wheels using a GlobalKey reference.
  ///
  /// This static method allows batch recreation of multiple wheels, which is
  /// more efficient than recreating them individually.
  ///
  /// **Parameters:**
  /// - [key]: GlobalKey of the SelectiveWheelPicker widget
  /// - [updates]: Map of wheel indices to new configurations
  ///
  /// **Example:**
  /// ```dart
  /// SelectiveWheelPicker.recreateWheelsByKey(pickerKey, {
  ///   0: newDayConfig,
  ///   1: newMonthConfig,
  /// });
  /// ```
  ///
  /// **Performance:** Batch operations are more efficient than individual
  /// recreations as they are processed together and trigger only one rebuild.
  static void recreateWheelsByKey(GlobalKey key, Map<int, WheelConfig> updates) {
    final state = key.currentState as _SelectiveWheelPickerBuilderState?;
    state?.recreateWheels(updates);
  }
  /* -------------------------------------------------------------------------------------- */
  /// Updates wheel configuration using a GlobalKey reference.
  ///
  /// This method intelligently determines whether recreation is needed by
  /// comparing the new configuration with the current one. If recreation
  /// is not needed, it performs a simple update.
  ///
  /// **Parameters:**
  /// - [key]: GlobalKey of the SelectiveWheelPicker widget
  /// - [index]: Index of the wheel to update
  /// - [newConfig]: New configuration for the wheel
  ///
  /// **Example:**
  /// ```dart
  /// // This will only recreate if itemCount, initialIndex, or wheelId changed
  /// SelectiveWheelPicker.updateWheelConfigByKey(
  ///   pickerKey,
  ///   0,
  ///   currentConfig.copyWith(
  ///     onChanged: newCallback, // This won't trigger recreation
  ///   ),
  /// );
  /// ```
  ///
  /// **Optimization:** Use this method when you're unsure if recreation is
  /// needed. It will automatically choose the most efficient update method.
  static void updateWheelConfigByKey(GlobalKey key, int index, WheelConfig newConfig) {
    final state = key.currentState as _SelectiveWheelPickerBuilderState?;
    state?.updateWheelConfig(index, newConfig);
  }
  /* -------------------------------------------------------------------------------------- */
  /// Updates wheel position without recreation using a GlobalKey reference.
  ///
  /// This method provides smooth scrolling by updating only the wheel position
  /// without triggering any recreation logic. It's optimized for independent
  /// wheels that don't have dependencies.
  ///
  /// **Parameters:**
  /// - [key]: GlobalKey of the SelectiveWheelPicker widget
  /// - [index]: Index of the wheel to update
  /// - [newPosition]: New selection position
  /// - [withAnimation]: Whether to animate to the new position (default: false)
  ///
  /// **Example:**
  /// ```dart
  /// // Update month wheel position smoothly
  /// SelectiveWheelPicker.updateWheelPositionByKey(
  ///   pickerKey,
  ///   1, // month wheel
  ///   5, // June (0-based)
  ///   withAnimation: true,
  /// );
  /// ```
  ///
  /// **Performance:** This method is highly optimized for smooth scrolling
  /// and avoids controller disposal/creation cycles.
  static void updateWheelPositionByKey(
    GlobalKey key,
    int index,
    int newPosition, {
    bool withAnimation = false,
  }) {
    final state = key.currentState as _SelectiveWheelPickerBuilderState?;
    state?.updateWheelPositionWithVisualFeedback(
      index,
      newPosition,
      withAnimation: withAnimation,
    );
  }
  /* -------------------------------------------------------------------------------------- */
  /// Updates multiple wheel positions simultaneously using a GlobalKey reference.
  ///
  /// This method efficiently handles batch position updates while maintaining
  /// smooth scrolling performance for all affected wheels.
  ///
  /// **Parameters:**
  /// - [key]: GlobalKey of the SelectiveWheelPicker widget
  /// - [updates]: Map of wheel indices to new positions
  /// - [withAnimation]: Whether to animate to new positions (default: false)
  ///
  /// **Example:**
  /// ```dart
  /// // Update both month and year positions
  /// SelectiveWheelPicker.updateMultipleWheelPositionsByKey(pickerKey, {
  ///   1: 11, // December
  ///   2: 25, // 2025
  /// });
  /// ```
  ///
  /// **Performance:** Batch operations are more efficient than individual
  /// position updates as they are processed together.
  static void updateMultipleWheelPositionsByKey(
    GlobalKey key,
    Map<int, int> updates, {
    bool withAnimation = false,
  }) {
    final state = key.currentState as _SelectiveWheelPickerBuilderState?;
    state?.updateMultipleWheelPositions(updates, withAnimation: withAnimation);
  }
  /* -------------------------------------------------------------------------------------- */
  /// Checks if a wheel can be updated without recreation using a GlobalKey reference.
  ///
  /// **Parameters:**
  /// - [key]: GlobalKey of the SelectiveWheelPicker widget
  /// - [index]: Index of the wheel to check
  ///
  /// **Returns:** `true` if position-only updates are safe for this wheel
  ///
  /// **Example:**
  /// ```dart
  /// if (SelectiveWheelPicker.canUpdateWheelPositionOnlyByKey(pickerKey, 1)) {
  ///   // Safe to use position-only update for smooth scrolling
  ///   SelectiveWheelPicker.updateWheelPositionByKey(pickerKey, 1, newPosition);
  /// } else {
  ///   // Need to use full recreation
  ///   SelectiveWheelPicker.recreateWheelByKey(pickerKey, 1, newConfig);
  /// }
  /// ```
  static bool canUpdateWheelPositionOnlyByKey(GlobalKey key, int index) {
    final state = key.currentState as _SelectiveWheelPickerBuilderState?;
    return state?.canUpdateWheelPositionOnly(index) ?? false;
  }
}

/* ============================================================================================= */

class _SelectiveWheelPickerBuilderState extends State<SelectiveWheelPickerBuilder> {
  late WheelManager _wheelManager;
  bool _isExternalManager = false;
  final Map<int, GlobalKey> _wheelKeys = {};
  /* -------------------------------------------------------------------------------------- */
  @override
  void initState() {
    super.initState();
    _initializeWheelManager();
    _generateWheelKeys();
  }
  /* -------------------------------------------------------------------------------------- */
  void _initializeWheelManager() {
    if (widget.wheelManager != null) {
      _wheelManager = widget.wheelManager!;
      _isExternalManager = true;
    } else {
      _wheelManager = WheelManager();
      _isExternalManager = false;
    }

    _wheelManager.initialize(widget.wheels);
  }
  /* -------------------------------------------------------------------------------------- */
  void _generateWheelKeys() {
    _wheelKeys.clear();
    for (int i = 0; i < widget.wheels.length; i++) {
      _wheelKeys[i] = GlobalKey(debugLabel: 'wheel_$i');
    }
  }
  /* -------------------------------------------------------------------------------------- */
  /// Recreates a single wheel with new configuration.
  ///
  /// This method handles the complete lifecycle of wheel recreation:
  /// 1. Validates the index bounds
  /// 2. Updates the wheel manager (which handles controller disposal/creation)
  /// 3. Generates a new unique key to force widget rebuild
  /// 4. Synchronizes state after recreation
  /// 5. Triggers a widget rebuild
  ///
  /// **Parameters:**
  /// - [index]: Index of the wheel to recreate (0-based)
  /// - [newConfig]: New configuration for the wheel
  ///
  /// **Thread Safety:** This method is safe to call from any thread as it
  /// schedules callbacks appropriately using WidgetsBinding.
  ///
  /// **Performance:** The recreation is optimized to only affect the specified
  /// wheel. Other wheels maintain their scroll controllers and state.
  ///
  /// **Example:**
  /// ```dart
  /// // Recreate day wheel when month changes
  /// void _onMonthChanged(int newMonth) {
  ///   final daysInMonth = DateTime(year, newMonth + 1, 0).day;
  ///   final newDayConfig = WheelConfig(
  ///     itemCount: daysInMonth,
  ///     initialIndex: 0,
  ///     formatter: (i) => (i + 1).toString(),
  ///     width: 60,
  ///     wheelId: 'day_wheel_$newMonth',
  ///   );
  ///   recreateWheel(0, newDayConfig);
  /// }
  /// ```
  void recreateWheel(int index, WheelConfig newConfig) {
    if (index < 0 || index >= _wheelManager.wheels.length) {
      return;
    }

    // Store old callback for comparison
    final oldCallback = _wheelManager.wheels[index].onChanged;

    // Update the wheel manager (handles controller lifecycle)
    _wheelManager.recreateWheel(index, newConfig);

    // Generate new key for the recreated wheel to force widget rebuild
    _wheelKeys[index] = GlobalKey(
      debugLabel: 'wheel_${index}_${DateTime.now().millisecondsSinceEpoch}',
    );

    // Synchronize state after recreation
    _synchronizeStateAfterRecreation(index, oldCallback, newConfig.onChanged);

    // Trigger rebuild
    if (mounted) {
      setState(() {});
    }
  }
  /* -------------------------------------------------------------------------------------- */
  /// Recreates multiple wheels with new configurations.
  ///
  /// This method efficiently handles batch recreation operations by:
  /// 1. Validating all indices before starting any operations
  /// 2. Storing old callbacks for proper state synchronization
  /// 3. Performing batch updates through the wheel manager
  /// 4. Generating new keys for all affected wheels
  /// 5. Synchronizing state for all recreated wheels
  /// 6. Triggering a single widget rebuild
  ///
  /// **Parameters:**
  /// - [updates]: Map of wheel indices to new configurations
  ///
  /// **Performance Benefits:**
  /// - Single widget rebuild instead of multiple rebuilds
  /// - Batch processing reduces overhead
  /// - Atomic operation ensures consistency
  ///
  /// **Example:**
  /// ```dart
  /// // Update both day and month wheels when year changes
  /// void _onYearChanged(int newYear) {
  ///   recreateWheels({
  ///     0: _buildDayConfig(newYear),
  ///     1: _buildMonthConfig(newYear),
  ///   });
  /// }
  /// ```
  ///
  /// **Error Handling:** If any index is invalid, the entire operation
  /// is aborted to maintain consistency.
  void recreateWheels(Map<int, WheelConfig> updates) {
    if (updates.isEmpty) return;

    final indices = updates.keys.toList();
    final configs = updates.values.toList();

    // Validate all indices before proceeding
    for (final index in indices) {
      if (index < 0 || index >= _wheelManager.wheels.length) {
        return;
      }
    }

    // Store old callbacks for comparison
    final oldCallbacks = <int, ValueChanged<int>?>{};
    for (final index in indices) {
      oldCallbacks[index] = _wheelManager.wheels[index].onChanged;
    }

    // Update the wheel manager with batch operation (handles controller lifecycle)
    _wheelManager.recreateWheels(indices, configs);

    // Generate new keys for all recreated wheels
    for (final index in indices) {
      _wheelKeys[index] = GlobalKey(
        debugLabel: 'wheel_${index}_${DateTime.now().millisecondsSinceEpoch}',
      );
    }

    // Synchronize state after batch recreation
    for (int i = 0; i < indices.length; i++) {
      final index = indices[i];
      final config = configs[i];
      _synchronizeStateAfterRecreation(index, oldCallbacks[index], config.onChanged);
    }

    // Trigger rebuild
    if (mounted) {
      setState(() {});
    }
  }
  /* -------------------------------------------------------------------------------------- */
  /// Updates wheel configuration, recreating only if necessary.
  ///
  /// This method intelligently determines whether full recreation is needed
  /// by comparing the new configuration with the current one using the
  /// [WheelConfig.needsRecreation] method.
  ///
  /// **Recreation Triggers:**
  /// - Change in itemCount
  /// - Change in initialIndex
  /// - Change in wheelId
  ///
  /// **Non-Recreation Updates:**
  /// - Change in formatter function
  /// - Change in onChanged callback
  /// - Change in separator widgets
  /// - Change in width (handled by layout)
  ///
  /// **Parameters:**
  /// - [index]: Index of the wheel to update
  /// - [newConfig]: New configuration for the wheel
  ///
  /// **Performance:** This method is more efficient than [recreateWheel]
  /// when recreation is not needed, as it avoids controller disposal/creation.
  ///
  /// **Example:**
  /// ```dart
  /// // Update callback without recreation
  /// updateWheelConfig(0, currentConfig.copyWith(
  ///   onChanged: newCallback,
  /// ));
  ///
  /// // This will trigger recreation due to itemCount change
  /// updateWheelConfig(0, currentConfig.copyWith(
  ///   itemCount: 30,
  /// ));
  /// ```
  void updateWheelConfig(int index, WheelConfig newConfig) {
    if (index < 0 || index >= _wheelManager.wheels.length) {
      return;
    }

    final currentConfig = _wheelManager.wheels[index];
    if (currentConfig.needsRecreation(newConfig)) {
      recreateWheel(index, newConfig);
    } else {
      // Simple update without recreation
      final oldCallback = currentConfig.onChanged;
      _wheelManager.updateWheelConfig(index, newConfig);

      // Handle callback changes even without recreation
      _synchronizeStateAfterRecreation(index, oldCallback, newConfig.onChanged);

      if (mounted) {
        setState(() {});
      }
    }
  }
  /* -------------------------------------------------------------------------------------- */
  /// Synchronize state after wheel recreation or update
  void _synchronizeStateAfterRecreation(
    int index,
    ValueChanged<int>? oldCallback,
    ValueChanged<int>? newCallback,
  ) {
    // Validate controller state
    if (!_wheelManager.validateStateConsistency()) {
      // Attempt to repair state inconsistencies
      if (!_wheelManager.repairStateInconsistencies()) {
        // If repair fails, log error but continue
        debugPrint('Warning: State inconsistency detected for wheel $index');
      }
    }

    // If callback changed, notify about current selection
    if (oldCallback != newCallback && newCallback != null) {
      final currentSelection = _wheelManager.selectedIndices[index];
      // Schedule callback for next frame to avoid calling during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          newCallback.call(currentSelection);
          // Also trigger global callback
          widget.onChanged?.call(List.from(_wheelManager.selectedIndices));
        }
      });
    }
  }
  /* -------------------------------------------------------------------------------------- */
  /// Validate all controllers are in a valid state
  bool _validateControllerStates() {
    return _wheelManager.areAllControllersValid();
  }
  /* -------------------------------------------------------------------------------------- */
  /// Get the current state of all wheels for debugging
  // ignore: unused_element
  List<WheelState?> _getCurrentWheelStates() {
    return List.generate(
      _wheelManager.wheels.length,
      (index) => _wheelManager.getWheelState(index),
    );
  }
  /* -------------------------------------------------------------------------------------- */
  @override
  void dispose() {
    // Validate state before disposal
    if (!_validateControllerStates()) {
      debugPrint('Warning: Invalid controller states detected during disposal');
    }

    // Only dispose if we own the manager
    if (!_isExternalManager) {
      _wheelManager.dispose();
    }
    super.dispose();
  }
  /* -------------------------------------------------------------------------------------- */
  @override
  void didUpdateWidget(SelectiveWheelPickerBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only react to wheel count changes here.
    // All dependency-driven updates are handled internally by WheelManager
    // during user interaction, avoiding per-build config pushes that can
    // cause flicker loops for dependent wheels (e.g., day wheel).
    if (widget.wheels.length != oldWidget.wheels.length) {
      _wheelManager.initialize(widget.wheels);
      _generateWheelKeys();
    }
  }
  /* -------------------------------------------------------------------------------------- */
  void _handleWheelChange(int wheelIndex, int selectedIndex) {
    // Store old selection for comparison
    final oldSelection = _wheelManager.selectedIndices[wheelIndex];

    // Unified path: handle all user-driven changes via state-only update.
    // Dependency-based recreations (e.g., day wheel) are triggered inside the manager.

    // Update selection without directly commanding controller during user scroll.
    // Smooth physics are handled by ListWheelScrollView; dependency system will recreate as needed.
    _wheelManager.updateSelectedIndex(wheelIndex, selectedIndex);

    // Only trigger callbacks if selection actually changed
    if (oldSelection != selectedIndex) {
      // Defer external callbacks to post-frame to avoid setState during build in consumers.
      final selectedSnapshot = selectedIndex;
      final indicesSnapshot = List<int>.from(_wheelManager.selectedIndices);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Call individual wheel callback
        _wheelManager.wheels[wheelIndex].onChanged?.call(selectedSnapshot);
        // Call global callback
        widget.onChanged?.call(indicesSnapshot);
      });
    }
  }
  /* -------------------------------------------------------------------------------------- */
  /// Updates wheel position with real-time visual feedback.
  ///
  /// This method provides immediate visual updates for smooth scrolling
  /// by directly updating the controller position without recreation.
  ///
  /// **Parameters:**
  /// - [wheelIndex]: Index of the wheel to update
  /// - [selectedIndex]: New selection index
  /// - [withAnimation]: Whether to animate to the new position
  void updateWheelPositionWithVisualFeedback(
    int wheelIndex,
    int selectedIndex, {
    bool withAnimation = false,
  }) {
    if (wheelIndex >= 0 && wheelIndex < _wheelManager.wheels.length) {
      _wheelManager.updateWheelSelectionWithVisualUpdate(
        wheelIndex,
        selectedIndex,
        animateToPosition: withAnimation,
      );

      // Defer callbacks for external updates to post-frame for safety.
      final selectedSnapshot = selectedIndex;
      final indicesSnapshot = List<int>.from(_wheelManager.selectedIndices);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _wheelManager.wheels[wheelIndex].onChanged?.call(selectedSnapshot);
        widget.onChanged?.call(indicesSnapshot);
      });
    }
  }
  /* -------------------------------------------------------------------------------------- */
  /// Updates multiple wheel positions simultaneously.
  ///
  /// This method efficiently handles batch position updates while maintaining
  /// smooth scrolling performance for all wheels.
  ///
  /// **Parameters:**
  /// - [updates]: Map of wheel indices to new selection values
  /// - [withAnimation]: Whether to animate to new positions
  void updateMultipleWheelPositions(
    Map<int, int> updates, {
    bool withAnimation = false,
  }) {
    if (updates.isNotEmpty) {
      _wheelManager.updateMultipleWheelPositions(
        updates,
        animateToPosition: withAnimation,
      );

      // Defer global callback for batch updates to post-frame.
      final indicesSnapshot = List<int>.from(_wheelManager.selectedIndices);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onChanged?.call(indicesSnapshot);
      });
    }
  }
  /* -------------------------------------------------------------------------------------- */
  /// Checks if a wheel can be updated without recreation.
  ///
  /// **Parameters:**
  /// - [wheelIndex]: Index of the wheel to check
  ///
  /// **Returns:** `true` if position-only updates are safe for this wheel
  bool canUpdateWheelPositionOnly(int wheelIndex) {
    return _wheelManager.canUpdateControllerPosition(wheelIndex) &&
        !_wheelManager.dependencyManager.hasDependencies(wheelIndex);
  }
  /* -------------------------------------------------------------------------------------- */
  /// Checks if a wheel needs recreation based on dependency-driven logic.
  ///
  /// This method replaces reactive recreation checks with intelligent
  /// dependency-based recreation decision making.
  ///
  /// **Parameters:**
  /// - [wheelIndex]: Index of the wheel to check
  ///
  /// **Returns:** `true` if the wheel needs recreation
  ///
  /// **Note:** This method is primarily used for testing and debugging purposes.
  // ignore: unused_element
  bool _needsRecreation(int wheelIndex) {
    return _wheelManager.needsRecreation(wheelIndex);
  }
  /* -------------------------------------------------------------------------------------- */
  /// Gets recreation decision for a specific wheel for debugging.
  ///
  /// **Parameters:**
  /// - [wheelIndex]: Index of the wheel to check
  ///
  /// **Returns:** [RecreationDecision] with detailed information
  ///
  /// **Note:** This method is primarily used for testing and debugging purposes.
  // ignore: unused_element
  RecreationDecision _getRecreationDecision(int wheelIndex) {
    return _wheelManager.getRecreationDecision(wheelIndex);
  }
  /* -------------------------------------------------------------------------------------- */
  @override
  Widget build(BuildContext context) {
    final dark = isDarkModeInUse(context);

    // Avoid rebuilding the entire wheel row on every reactive selection tick.
    // We rebuild via setState() only when wheels are recreated/updated.
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

    for (int i = 0; i < _wheelManager.wheels.length; i++) {
      final wheel = _wheelManager.wheels[i];

      // Add leading separator if exists
      if (wheel.leadingSeparator != null) {
        widgets.add(wheel.leadingSeparator!);
      }

      // Add wheel with unique key
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
    // Scope reactivity per-wheel: this Obx rebuilds only when this wheel's
    // config/controller RxLists are updated (i.e., on recreation/update),
    // not on user-driven selection changes which modify selectedIndices.
    return Obx(() {
      final config = _wheelManager.wheels[index];
      final controller = _wheelManager.controllers[index];

      // Force element rebuild when controller instance or itemCount changes to
      // ensure ListWheelScrollView reconfigures its internal state correctly.
      final rebuildKey = ValueKey<String>(
        'wheel_${index}_${_wheelManager.wheelKeys[index]}_${controller.hashCode}_${config.itemCount}',
      );

      return WheelPicker(
        key: rebuildKey,
        controller: controller,
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
        child: (itemIndex) => Center(child: Text(config.formatter(itemIndex))),
      );
    });
  }
}
