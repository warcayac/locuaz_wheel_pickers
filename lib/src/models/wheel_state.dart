import 'package:flutter/material.dart';

import 'wheel_config.dart';


/// Represents the current state of a wheel in the picker
class WheelState {
  final String wheelId;
  final int selectedIndex;
  final FixedExtentScrollController controller;
  final WheelConfig config;
  final bool needsRecreation;
  /* -------------------------------------------------------------------------------------- */
  const WheelState({
    required this.wheelId,
    required this.selectedIndex,
    required this.controller,
    required this.config,
    this.needsRecreation = false,
  });
  /* -------------------------------------------------------------------------------------- */
  /// Creates a WheelState from a WheelConfig
  factory WheelState.fromConfig(
    WheelConfig config, {
    String? wheelId,
    int? selectedIndex,
    FixedExtentScrollController? controller,
  }) {
    final id = wheelId ?? config.wheelId ?? 'wheel_${DateTime.now().millisecondsSinceEpoch}';
    final index = selectedIndex ?? config.initialIndex;
    final ctrl = controller ?? FixedExtentScrollController(initialItem: index);
    
    return WheelState(
      wheelId: id,
      selectedIndex: index,
      controller: ctrl,
      config: config,
    );
  }
  /* -------------------------------------------------------------------------------------- */
  /// Creates a new WheelState with updated configuration
  factory WheelState.withNewConfig(
    WheelState currentState,
    WheelConfig newConfig, {
    bool preserveSelection = true,
  }) {
    final needsRecreation = currentState.config.needsRecreation(newConfig);
    int newSelectedIndex = newConfig.initialIndex;
    
    if (preserveSelection) {
      newSelectedIndex = needsRecreation
        // Try to preserve selection within new bounds
        ? currentState.selectedIndex.clamp(0, newConfig.itemCount - 1)
        // Keep current selection if no recreation needed
        : currentState.selectedIndex
      ;
    }
    
    return WheelState(
      wheelId: currentState.wheelId,
      selectedIndex: newSelectedIndex,
      controller: needsRecreation 
        ? FixedExtentScrollController(initialItem: newSelectedIndex)
        : currentState.controller,
      config: newConfig,
      needsRecreation: needsRecreation,
    );
  }
  /* -------------------------------------------------------------------------------------- */
  /// Validates the current wheel state
  bool isValid() {
    return config.isValid()
          && selectedIndex >= 0
          && selectedIndex < config.itemCount
          && wheelId.isNotEmpty;
  }
  /* -------------------------------------------------------------------------------------- */
  /// Checks if this state is consistent with another state
  bool isConsistentWith(WheelState other) {
    return wheelId == other.wheelId
           && selectedIndex == other.selectedIndex
           && config.itemCount == other.config.itemCount;
  }
  /* -------------------------------------------------------------------------------------- */
  /// Creates a copy of this state with optional parameter overrides
  WheelState copyWith({
    String? wheelId,
    int? selectedIndex,
    FixedExtentScrollController? controller,
    WheelConfig? config,
    bool? needsRecreation,
  }) {
    return WheelState(
      wheelId: wheelId ?? this.wheelId,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      controller: controller ?? this.controller,
      config: config ?? this.config,
      needsRecreation: needsRecreation ?? this.needsRecreation,
    );
  }
  /* -------------------------------------------------------------------------------------- */
  /// Disposes the controller if it needs recreation
  void disposeIfNeeded() {
    if (needsRecreation) {
      controller.dispose();
    }
  }
  /* -------------------------------------------------------------------------------------- */
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WheelState
          && other.wheelId == wheelId
          && other.selectedIndex == selectedIndex
          && other.config == config
          && other.needsRecreation == needsRecreation;
  }
  /* -------------------------------------------------------------------------------------- */
  @override
  int get hashCode => Object.hash(wheelId, selectedIndex, config, needsRecreation);
  /* -------------------------------------------------------------------------------------- */
  @override
  String toString() {
    return 'WheelState(wheelId: $wheelId, selectedIndex: $selectedIndex, needsRecreation: $needsRecreation)';
  }
}