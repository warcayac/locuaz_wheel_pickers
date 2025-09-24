import '../models/wheel_config.dart';

/// Decision result for wheel recreation.
/// 
/// Contains information about whether a wheel needs recreation,
/// the new configuration if needed, and the reason for the decision.
class RecreationDecision {
  /// Index of the wheel this decision applies to.
  final int wheelIndex;
  /// Whether the wheel needs recreation.
  final bool needsRecreation;
  /// New configuration for the wheel (only if recreation is needed).
  final WheelConfig? newConfig;
  /// Human-readable reason for the decision.
  final String reason;
  /* -------------------------------------------------------------------------------------- */
  /// Creates a new recreation decision.
  const RecreationDecision({
    required this.wheelIndex,
    required this.needsRecreation,
    required this.newConfig,
    required this.reason,
  });
  /* -------------------------------------------------------------------------------------- */
  @override
  String toString() {
    return 'RecreationDecision(wheelIndex: $wheelIndex, '
        'needsRecreation: $needsRecreation, reason: $reason)';
  }
  /* -------------------------------------------------------------------------------------- */
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecreationDecision &&
        other.wheelIndex == wheelIndex &&
        other.needsRecreation == needsRecreation &&
        other.newConfig == newConfig &&
        other.reason == reason;
  }
  /* -------------------------------------------------------------------------------------- */
  @override
  int get hashCode {
    return Object.hash(wheelIndex, needsRecreation, newConfig, reason);
  }
}