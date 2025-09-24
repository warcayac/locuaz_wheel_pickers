/// Performance monitoring data
class PerformanceMetrics {
  int recreationCount = 0;
  int batchedRecreationCount = 0;
  int throttledRequestCount = 0;
  DateTime? lastRecreationTime;
  Duration totalRecreationTime = Duration.zero;
  List<Duration> recreationDurations = [];
  /* -------------------------------------------------------------------------------------- */
  void recordRecreation(Duration duration) {
    recreationCount++;
    lastRecreationTime = DateTime.now();
    totalRecreationTime += duration;
    recreationDurations.add(duration);
    
    // Keep only last 100 measurements for memory efficiency
    if (recreationDurations.length > 100) {
      recreationDurations.removeAt(0);
      // Don't subtract from totalRecreationTime to maintain cumulative total
    }
  }
  /* -------------------------------------------------------------------------------------- */
  void recordBatchedRecreation() {
    batchedRecreationCount++;
  }
  /* -------------------------------------------------------------------------------------- */
  void recordThrottledRequest() {
    throttledRequestCount++;
  }
  /* -------------------------------------------------------------------------------------- */
  double get averageRecreationTime {
    if (recreationDurations.isEmpty) return 0.0;
    final total = recreationDurations.fold<int>(
      0, 
      (sum, duration) => sum + duration.inMicroseconds,
    );
    return total / recreationDurations.length / 1000; // Return in milliseconds
  }
  /* -------------------------------------------------------------------------------------- */
  void reset() {
    recreationCount = 0;
    batchedRecreationCount = 0;
    throttledRequestCount = 0;
    lastRecreationTime = null;
    totalRecreationTime = Duration.zero;
    recreationDurations.clear();
  }
}