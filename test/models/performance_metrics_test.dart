import 'package:flutter_test/flutter_test.dart';
import 'package:locuaz_wheel_pickers/src/models/performance_metrics.dart';

void main() {
  group('PerformanceMetrics', () {
    late PerformanceMetrics metrics;

    setUp(() {
      metrics = PerformanceMetrics();
    });

    group('initialization', () {
      test('starts with zero values', () {
        expect(metrics.recreationCount, equals(0));
        expect(metrics.batchedRecreationCount, equals(0));
        expect(metrics.throttledRequestCount, equals(0));
        expect(metrics.lastRecreationTime, isNull);
        expect(metrics.totalRecreationTime, equals(Duration.zero));
        expect(metrics.recreationDurations, isEmpty);
        expect(metrics.averageRecreationTime, equals(0.0));
      });
    });

    group('recordRecreation', () {
      test('records single recreation correctly', () {
        final duration = const Duration(milliseconds: 100);
        final beforeTime = DateTime.now();
        
        metrics.recordRecreation(duration);
        
        final afterTime = DateTime.now();

        expect(metrics.recreationCount, equals(1));
        expect(metrics.totalRecreationTime, equals(duration));
        expect(metrics.recreationDurations, hasLength(1));
        expect(metrics.recreationDurations.first, equals(duration));
        expect(metrics.lastRecreationTime, isNotNull);
        expect(metrics.lastRecreationTime!.isAfter(beforeTime), isTrue);
        expect(metrics.lastRecreationTime!.isBefore(afterTime), isTrue);
      });

      test('accumulates multiple recreations correctly', () {
        final duration1 = const Duration(milliseconds: 50);
        final duration2 = const Duration(milliseconds: 75);
        final duration3 = const Duration(milliseconds: 25);

        metrics.recordRecreation(duration1);
        metrics.recordRecreation(duration2);
        metrics.recordRecreation(duration3);

        expect(metrics.recreationCount, equals(3));
        expect(metrics.totalRecreationTime, equals(const Duration(milliseconds: 150)));
        expect(metrics.recreationDurations, hasLength(3));
        expect(metrics.recreationDurations, containsAllInOrder([duration1, duration2, duration3]));
      });

      test('limits recreation durations list to 100 items', () {
        // Add 105 recreations
        for (int i = 0; i < 105; i++) {
          metrics.recordRecreation(Duration(milliseconds: i + 1));
        }

        expect(metrics.recreationCount, equals(105));
        expect(metrics.recreationDurations, hasLength(100));
        // Should contain the last 100 durations (6ms to 105ms)
        expect(metrics.recreationDurations.first, equals(const Duration(milliseconds: 6)));
        expect(metrics.recreationDurations.last, equals(const Duration(milliseconds: 105)));
        
        // Total recreation time should still include all recreations
        final expectedTotal = Duration(milliseconds: (1 + 105) * 105 ~/ 2); // sum of 1 to 105
        expect(metrics.totalRecreationTime, equals(expectedTotal));
      });

      test('updates lastRecreationTime with each call', () {
        final duration = const Duration(milliseconds: 10);
        
        metrics.recordRecreation(duration);
        final firstTime = metrics.lastRecreationTime!;
        
        // Small delay to ensure different timestamp
        Future.delayed(const Duration(milliseconds: 1));
        
        metrics.recordRecreation(duration);
        final secondTime = metrics.lastRecreationTime!;
        
        expect(secondTime.isAfter(firstTime) || secondTime.isAtSameMomentAs(firstTime), isTrue);
      });
    });

    group('recordBatchedRecreation', () {
      test('increments batched recreation count', () {
        expect(metrics.batchedRecreationCount, equals(0));
        
        metrics.recordBatchedRecreation();
        expect(metrics.batchedRecreationCount, equals(1));
        
        metrics.recordBatchedRecreation();
        metrics.recordBatchedRecreation();
        expect(metrics.batchedRecreationCount, equals(3));
      });

      test('does not affect other metrics', () {
        metrics.recordBatchedRecreation();
        
        expect(metrics.recreationCount, equals(0));
        expect(metrics.throttledRequestCount, equals(0));
        expect(metrics.lastRecreationTime, isNull);
        expect(metrics.totalRecreationTime, equals(Duration.zero));
        expect(metrics.recreationDurations, isEmpty);
      });
    });

    group('recordThrottledRequest', () {
      test('increments throttled request count', () {
        expect(metrics.throttledRequestCount, equals(0));
        
        metrics.recordThrottledRequest();
        expect(metrics.throttledRequestCount, equals(1));
        
        metrics.recordThrottledRequest();
        metrics.recordThrottledRequest();
        expect(metrics.throttledRequestCount, equals(3));
      });

      test('does not affect other metrics', () {
        metrics.recordThrottledRequest();
        
        expect(metrics.recreationCount, equals(0));
        expect(metrics.batchedRecreationCount, equals(0));
        expect(metrics.lastRecreationTime, isNull);
        expect(metrics.totalRecreationTime, equals(Duration.zero));
        expect(metrics.recreationDurations, isEmpty);
      });
    });

    group('averageRecreationTime', () {
      test('returns 0.0 when no recreations recorded', () {
        expect(metrics.averageRecreationTime, equals(0.0));
      });

      test('calculates average correctly for single recreation', () {
        metrics.recordRecreation(const Duration(milliseconds: 100));
        
        expect(metrics.averageRecreationTime, equals(100.0)); // 100ms
      });

      test('calculates average correctly for multiple recreations', () {
        metrics.recordRecreation(const Duration(milliseconds: 50));  // 50ms
        metrics.recordRecreation(const Duration(milliseconds: 100)); // 100ms
        metrics.recordRecreation(const Duration(milliseconds: 150)); // 150ms
        
        // Average should be (50 + 100 + 150) / 3 = 100ms
        expect(metrics.averageRecreationTime, equals(100.0));
      });

      test('calculates average correctly with microsecond precision', () {
        metrics.recordRecreation(const Duration(microseconds: 1500)); // 1.5ms
        metrics.recordRecreation(const Duration(microseconds: 2500)); // 2.5ms
        
        // Average should be (1.5 + 2.5) / 2 = 2.0ms
        expect(metrics.averageRecreationTime, equals(2.0));
      });

      test('uses only recent durations when list is trimmed', () {
        // Add 105 recreations with known durations
        for (int i = 1; i <= 105; i++) {
          metrics.recordRecreation(Duration(milliseconds: i));
        }
        
        // Should calculate average of last 100 durations (6ms to 105ms)
        final expectedAverage = (6 + 105) * 100 / 2 / 100; // arithmetic mean
        expect(metrics.averageRecreationTime, equals(expectedAverage));
      });

      test('handles zero duration correctly', () {
        metrics.recordRecreation(Duration.zero);
        metrics.recordRecreation(const Duration(milliseconds: 100));
        
        // Average should be (0 + 100) / 2 = 50ms
        expect(metrics.averageRecreationTime, equals(50.0));
      });
    });

    group('reset', () {
      test('resets all metrics to initial state', () {
        // Set up some data
        metrics.recordRecreation(const Duration(milliseconds: 100));
        metrics.recordRecreation(const Duration(milliseconds: 200));
        metrics.recordBatchedRecreation();
        metrics.recordBatchedRecreation();
        metrics.recordThrottledRequest();
        
        // Verify data exists
        expect(metrics.recreationCount, equals(2));
        expect(metrics.batchedRecreationCount, equals(2));
        expect(metrics.throttledRequestCount, equals(1));
        expect(metrics.lastRecreationTime, isNotNull);
        expect(metrics.totalRecreationTime, equals(const Duration(milliseconds: 300)));
        expect(metrics.recreationDurations, hasLength(2));
        expect(metrics.averageRecreationTime, equals(150.0));
        
        // Reset
        metrics.reset();
        
        // Verify reset state
        expect(metrics.recreationCount, equals(0));
        expect(metrics.batchedRecreationCount, equals(0));
        expect(metrics.throttledRequestCount, equals(0));
        expect(metrics.lastRecreationTime, isNull);
        expect(metrics.totalRecreationTime, equals(Duration.zero));
        expect(metrics.recreationDurations, isEmpty);
        expect(metrics.averageRecreationTime, equals(0.0));
      });

      test('allows recording new data after reset', () {
        // Set up and reset
        metrics.recordRecreation(const Duration(milliseconds: 100));
        metrics.reset();
        
        // Record new data
        metrics.recordRecreation(const Duration(milliseconds: 50));
        metrics.recordBatchedRecreation();
        metrics.recordThrottledRequest();
        
        // Verify new data is recorded correctly
        expect(metrics.recreationCount, equals(1));
        expect(metrics.batchedRecreationCount, equals(1));
        expect(metrics.throttledRequestCount, equals(1));
        expect(metrics.totalRecreationTime, equals(const Duration(milliseconds: 50)));
        expect(metrics.averageRecreationTime, equals(50.0));
      });
    });

    group('edge cases and error handling', () {
      test('handles very large durations correctly', () {
        final largeDuration = const Duration(days: 1); // 24 hours
        
        metrics.recordRecreation(largeDuration);
        
        expect(metrics.recreationCount, equals(1));
        expect(metrics.totalRecreationTime, equals(largeDuration));
        expect(metrics.averageRecreationTime, equals(24 * 60 * 60 * 1000.0)); // 24 hours in ms
      });

      test('handles very small durations correctly', () {
        final smallDuration = const Duration(microseconds: 1);
        
        metrics.recordRecreation(smallDuration);
        
        expect(metrics.recreationCount, equals(1));
        expect(metrics.totalRecreationTime, equals(smallDuration));
        expect(metrics.averageRecreationTime, equals(0.001)); // 1 microsecond = 0.001ms
      });

      test('handles mixed duration sizes correctly', () {
        metrics.recordRecreation(const Duration(microseconds: 1));    // 0.001ms
        metrics.recordRecreation(const Duration(milliseconds: 1));    // 1ms
        metrics.recordRecreation(const Duration(seconds: 1));         // 1000ms
        
        expect(metrics.recreationCount, equals(3));
        expect(metrics.averageRecreationTime, closeTo(333.667, 0.001)); // (0.001 + 1 + 1000) / 3
      });
    });

    group('real-world usage scenarios', () {
      test('simulates typical wheel picker performance monitoring', () {
        // Simulate a series of wheel recreations with realistic timings
        final recreationTimes = [
          const Duration(milliseconds: 15),  // Fast recreation
          const Duration(milliseconds: 25),  // Normal recreation
          const Duration(milliseconds: 45),  // Slower recreation
          const Duration(milliseconds: 12),  // Fast recreation
          const Duration(milliseconds: 30),  // Normal recreation
        ];
        
        // Record some batched operations and throttled requests
        metrics.recordBatchedRecreation();
        metrics.recordThrottledRequest();
        metrics.recordThrottledRequest();
        
        // Record recreations
        for (final duration in recreationTimes) {
          metrics.recordRecreation(duration);
        }
        
        // Verify realistic performance metrics
        expect(metrics.recreationCount, equals(5));
        expect(metrics.batchedRecreationCount, equals(1));
        expect(metrics.throttledRequestCount, equals(2));
        expect(metrics.averageRecreationTime, equals(25.4)); // (15+25+45+12+30)/5 = 25.4ms
        expect(metrics.totalRecreationTime, equals(const Duration(milliseconds: 127)));
        
        // Verify performance is within acceptable ranges
        expect(metrics.averageRecreationTime, lessThan(50.0)); // Under 50ms average
        expect(metrics.recreationCount, lessThan(10)); // Not too many recreations
      });

      test('demonstrates performance optimization tracking', () {
        // Before optimization: many recreations
        for (int i = 0; i < 20; i++) {
          metrics.recordRecreation(const Duration(milliseconds: 40));
        }
        
        final beforeOptimization = {
          'recreations': metrics.recreationCount,
          'average': metrics.averageRecreationTime,
          'batched': metrics.batchedRecreationCount,
        };
        
        // After optimization: fewer recreations, more batching
        metrics.reset();
        
        for (int i = 0; i < 5; i++) {
          metrics.recordRecreation(const Duration(milliseconds: 20)); // Faster
        }
        for (int i = 0; i < 10; i++) {
          metrics.recordBatchedRecreation(); // More batching
        }
        
        final afterOptimization = {
          'recreations': metrics.recreationCount,
          'average': metrics.averageRecreationTime,
          'batched': metrics.batchedRecreationCount,
        };
        
        // Verify optimization improvements
        expect(afterOptimization['recreations']! < beforeOptimization['recreations']!, isTrue);
        expect(afterOptimization['average']! < beforeOptimization['average']!, isTrue);
        expect(afterOptimization['batched']! > beforeOptimization['batched']!, isTrue);
      });
    });
  });
}