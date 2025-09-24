import 'wheel_config.dart';


/// Request object for wheel recreation operations
class RecreationRequest {
  final int wheelIndex;
  final WheelConfig newConfig;
  final bool preserveSelection;
  /* -------------------------------------------------------------------------------------- */
  RecreationRequest({
    required this.wheelIndex,
    required this.newConfig,
    this.preserveSelection = true,
  });
}
