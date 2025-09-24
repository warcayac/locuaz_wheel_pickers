import 'package:flutter_test/flutter_test.dart';
import 'package:locuaz_wheel_pickers/src/models/wheel_dependency.dart';

void main() {
  group('WheelDependency', () {
    group('constructor', () {
      test('creates dependency with required parameters', () {
        final dependency = WheelDependency(
          dependsOn: [0, 1],
          calculateItemCount: (values) => values[0] + values[1],
        );

        expect(dependency.dependsOn, equals([0, 1]));
        expect(dependency.calculateItemCount([3, 7]), equals(10));
        expect(dependency.calculateInitialIndex, isNull);
        expect(dependency.buildFormatter, isNull);
      });

      test('creates dependency with all optional parameters', () {
        final calculateInitialIndex = (List<int> values, int current) => current.clamp(0, values[0] - 1);
        final buildFormatter = (List<int> values) => (int index) => 'Item $index (${values[0]})';

        final dependency = WheelDependency(
          dependsOn: [2, 3],
          calculateItemCount: (values) => values[0] * values[1],
          calculateInitialIndex: calculateInitialIndex,
          buildFormatter: buildFormatter,
        );

        expect(dependency.dependsOn, equals([2, 3]));
        expect(dependency.calculateItemCount([4, 5]), equals(20));
        expect(dependency.calculateInitialIndex, equals(calculateInitialIndex));
        expect(dependency.buildFormatter, equals(buildFormatter));
      });
    });

    group('isValid', () {
      test('returns true for valid dependency', () {
        final dependency = WheelDependency(
          dependsOn: [0, 1, 2],
          calculateItemCount: (values) => values.fold(0, (sum, val) => sum + val),
        );

        expect(dependency.isValid(), isTrue);
        expect(dependency.isValid(totalWheelCount: 5), isTrue);
      });

      test('returns false when dependsOn is empty', () {
        final dependency = WheelDependency(
          dependsOn: [],
          calculateItemCount: (values) => 10,
        );

        expect(dependency.isValid(), isFalse);
      });

      test('returns false when dependsOn contains negative indices', () {
        final dependency = WheelDependency(
          dependsOn: [0, -1, 2],
          calculateItemCount: (values) => values.length,
        );

        expect(dependency.isValid(), isFalse);
      });

      test('returns false when dependsOn contains duplicate indices', () {
        final dependency = WheelDependency(
          dependsOn: [0, 1, 1, 2],
          calculateItemCount: (values) => values.length,
        );

        expect(dependency.isValid(), isFalse);
      });

      test('returns false when indices exceed total wheel count', () {
        final dependency = WheelDependency(
          dependsOn: [0, 1, 5], // index 5 >= totalWheelCount 5
          calculateItemCount: (values) => values.length,
        );

        expect(dependency.isValid(totalWheelCount: 5), isFalse);
        expect(dependency.isValid(totalWheelCount: 6), isTrue);
      });
    });

    group('wouldCreateCycle', () {
      test('returns false when no cycle exists', () {
        final dependencies = <int, WheelDependency>{
          1: WheelDependency(dependsOn: [0], calculateItemCount: (v) => v[0]),
          2: WheelDependency(dependsOn: [1], calculateItemCount: (v) => v[0]),
        };

        final newDependency = WheelDependency(
          dependsOn: [0],
          calculateItemCount: (v) => v[0],
        );

        expect(newDependency.wouldCreateCycle(3, dependencies), isFalse);
      });

      test('returns true when direct cycle would be created', () {
        final dependencies = <int, WheelDependency>{
          1: WheelDependency(dependsOn: [0], calculateItemCount: (v) => v[0]),
        };

        final newDependency = WheelDependency(
          dependsOn: [1], // 0 -> 1 -> 0 (cycle)
          calculateItemCount: (v) => v[0],
        );

        expect(newDependency.wouldCreateCycle(0, dependencies), isTrue);
      });

      test('returns true when indirect cycle would be created', () {
        final dependencies = <int, WheelDependency>{
          1: WheelDependency(dependsOn: [2], calculateItemCount: (v) => v[0]),
          2: WheelDependency(dependsOn: [3], calculateItemCount: (v) => v[0]),
        };

        final newDependency = WheelDependency(
          dependsOn: [1], // 3 -> 1 -> 2 -> 3 (cycle)
          calculateItemCount: (v) => v[0],
        );

        expect(newDependency.wouldCreateCycle(3, dependencies), isTrue);
      });

      test('handles complex dependency graphs correctly', () {
        final dependencies = <int, WheelDependency>{
          1: WheelDependency(dependsOn: [0], calculateItemCount: (v) => v[0]),
          2: WheelDependency(dependsOn: [0], calculateItemCount: (v) => v[0]),
          3: WheelDependency(dependsOn: [1, 2], calculateItemCount: (v) => v[0] + v[1]),
        };

        // Adding dependency 4 -> [3] should not create cycle
        final safeDependency = WheelDependency(
          dependsOn: [3],
          calculateItemCount: (v) => v[0],
        );
        expect(safeDependency.wouldCreateCycle(4, dependencies), isFalse);

        // Adding dependency 0 -> [3] would create cycle: 0 -> 3 -> 1 -> 0
        final cyclicDependency = WheelDependency(
          dependsOn: [3],
          calculateItemCount: (v) => v[0],
        );
        expect(cyclicDependency.wouldCreateCycle(0, dependencies), isTrue);
      });

      test('handles self-dependency correctly', () {
        final dependencies = <int, WheelDependency>{};

        final selfDependency = WheelDependency(
          dependsOn: [1], // wheel 1 depends on itself
          calculateItemCount: (v) => v[0],
        );

        expect(selfDependency.wouldCreateCycle(1, dependencies), isTrue);
      });
    });

    group('calculateNewItemCount', () {
      test('returns calculated value for valid input', () {
        final dependency = WheelDependency(
          dependsOn: [0, 1],
          calculateItemCount: (values) => values[0] * values[1] + 5,
        );

        expect(dependency.calculateNewItemCount([3, 4]), equals(17)); // 3 * 4 + 5
        expect(dependency.calculateNewItemCount([0, 10]), equals(5)); // 0 * 10 + 5
      });

      test('returns null when dependency values length mismatch', () {
        final dependency = WheelDependency(
          dependsOn: [0, 1, 2],
          calculateItemCount: (values) => values.fold(0, (sum, val) => sum + val),
        );

        expect(dependency.calculateNewItemCount([1, 2]), isNull); // too few values
        expect(dependency.calculateNewItemCount([1, 2, 3, 4]), isNull); // too many values
      });

      test('returns null when calculation returns invalid value', () {
        final dependency = WheelDependency(
          dependsOn: [0],
          calculateItemCount: (values) => -5, // invalid negative count
        );

        expect(dependency.calculateNewItemCount([10]), isNull);
      });

      test('returns null when calculation throws exception', () {
        final dependency = WheelDependency(
          dependsOn: [0, 1],
          calculateItemCount: (values) => values[0] ~/ values[1], // division by zero
        );

        expect(dependency.calculateNewItemCount([10, 0]), isNull);
      });

      test('handles edge cases correctly', () {
        final dependency = WheelDependency(
          dependsOn: [0],
          calculateItemCount: (values) => values[0] == 0 ? 1 : values[0],
        );

        expect(dependency.calculateNewItemCount([0]), equals(1));
        expect(dependency.calculateNewItemCount([5]), equals(5));
      });
    });

    group('calculateNewInitialIndex', () {
      test('uses safe default when no custom calculation provided', () {
        final dependency = WheelDependency(
          dependsOn: [0],
          calculateItemCount: (values) => values[0] + 10,
        );

        // Current selection within bounds
        expect(dependency.calculateNewInitialIndex([5], 3, 15), equals(3));
        
        // Current selection out of bounds
        expect(dependency.calculateNewInitialIndex([5], 20, 15), equals(14)); // 15 - 1
      });

      test('uses custom calculation when provided', () {
        final dependency = WheelDependency(
          dependsOn: [0, 1],
          calculateItemCount: (values) => values[0] + values[1],
          calculateInitialIndex: (values, current) {
            final maxIndex = values[0] + values[1] - 1;
            return current > maxIndex ? maxIndex ~/ 2 : current;
          },
        );

        // Current selection within bounds
        expect(dependency.calculateNewInitialIndex([5, 5], 3, 10), equals(3));
        
        // Current selection out of bounds, uses custom logic
        expect(dependency.calculateNewInitialIndex([5, 5], 15, 10), equals(4)); // (10-1) ~/ 2
      });

      test('returns safe default when dependency values length mismatch', () {
        final dependency = WheelDependency(
          dependsOn: [0, 1],
          calculateItemCount: (values) => values[0] + values[1],
          calculateInitialIndex: (values, current) => 0,
        );

        expect(dependency.calculateNewInitialIndex([5], 3, 10), equals(3)); // safe default
        expect(dependency.calculateNewInitialIndex([5, 6, 7], 3, 10), equals(3)); // safe default
      });

      test('returns safe default when custom calculation returns out-of-bounds', () {
        final dependency = WheelDependency(
          dependsOn: [0],
          calculateItemCount: (values) => values[0],
          calculateInitialIndex: (values, current) => 100, // always out of bounds
        );

        expect(dependency.calculateNewInitialIndex([5], 2, 5), equals(2)); // safe default
      });

      test('returns safe default when custom calculation throws exception', () {
        final dependency = WheelDependency(
          dependsOn: [0],
          calculateItemCount: (values) => values[0],
          calculateInitialIndex: (values, current) => throw Exception('Error'),
        );

        expect(dependency.calculateNewInitialIndex([5], 2, 5), equals(2)); // safe default
      });

      test('handles edge cases correctly', () {
        final dependency = WheelDependency(
          dependsOn: [0],
          calculateItemCount: (values) => values[0],
          calculateInitialIndex: (values, current) => values[0] - 1,
        );

        // Normal case
        expect(dependency.calculateNewInitialIndex([5], 2, 5), equals(4));
        
        // Edge case: newItemCount is 1
        expect(dependency.calculateNewInitialIndex([1], 0, 1), equals(0));
      });
    });

    group('equality and hashCode', () {
      test('dependencies with same dependsOn are equal', () {
        final dep1 = WheelDependency(
          dependsOn: [0, 1, 2],
          calculateItemCount: (values) => values.length,
        );
        final dep2 = WheelDependency(
          dependsOn: [0, 1, 2],
          calculateItemCount: (values) => values.fold(0, (sum, val) => sum + val), // different function
        );

        expect(dep1, equals(dep2));
        expect(dep1.hashCode, equals(dep2.hashCode));
      });

      test('dependencies with different dependsOn are not equal', () {
        final dep1 = WheelDependency(
          dependsOn: [0, 1],
          calculateItemCount: (values) => values.length,
        );
        final dep2 = WheelDependency(
          dependsOn: [0, 2],
          calculateItemCount: (values) => values.length,
        );

        expect(dep1, isNot(equals(dep2)));
        expect(dep1.hashCode, isNot(equals(dep2.hashCode)));
      });

      test('identical dependencies are equal', () {
        final dependency = WheelDependency(
          dependsOn: [0, 1],
          calculateItemCount: (values) => values.length,
        );

        expect(dependency, equals(dependency));
        expect(dependency.hashCode, equals(dependency.hashCode));
      });
    });

    group('toString', () {
      test('provides meaningful string representation', () {
        final dependency1 = WheelDependency(
          dependsOn: [0, 1, 2],
          calculateItemCount: (values) => values.length,
        );

        final dependency2 = WheelDependency(
          dependsOn: [3, 4],
          calculateItemCount: (values) => values.length,
          calculateInitialIndex: (values, current) => current,
          buildFormatter: (values) => (index) => 'Item $index',
        );

        expect(dependency1.toString(), contains('[0, 1, 2]'));
        expect(dependency1.toString(), contains('hasCalculateInitialIndex: false'));
        expect(dependency1.toString(), contains('hasBuildFormatter: false'));

        expect(dependency2.toString(), contains('[3, 4]'));
        expect(dependency2.toString(), contains('hasCalculateInitialIndex: true'));
        expect(dependency2.toString(), contains('hasBuildFormatter: true'));
      });
    });

    group('real-world scenarios', () {
      test('date picker day dependency works correctly', () {
        // Day wheel depends on month and year
        final dayDependency = WheelDependency(
          dependsOn: [1, 2], // month wheel (index 1), year wheel (index 2)
          calculateItemCount: (values) {
            final month = values[0] + 1; // Convert from 0-based to 1-based
            final year = 2000 + values[1]; // Convert from offset to actual year
            return DateTime(year, month + 1, 0).day; // Days in month
          },
          calculateInitialIndex: (values, current) {
            final month = values[0] + 1;
            final year = 2000 + values[1];
            final maxDays = DateTime(year, month + 1, 0).day;
            return current >= maxDays ? maxDays - 1 : current;
          },
        );

        // February 2024 (leap year) - should have 29 days
        expect(dayDependency.calculateNewItemCount([1, 24]), equals(29));
        
        // February 2023 (non-leap year) - should have 28 days
        expect(dayDependency.calculateNewItemCount([1, 23]), equals(28));
        
        // April 2024 - should have 30 days
        expect(dayDependency.calculateNewItemCount([3, 24]), equals(30));
        
        // December 2024 - should have 31 days
        expect(dayDependency.calculateNewItemCount([11, 24]), equals(31));

        // Test initial index calculation
        expect(dayDependency.calculateNewInitialIndex([1, 24], 15, 29), equals(15)); // within bounds
        expect(dayDependency.calculateNewInitialIndex([1, 23], 29, 28), equals(27)); // out of bounds, clamp to max
      });

      test('cascading time picker dependencies work correctly', () {
        // Hour dependency (simple)
        final hourDependency = WheelDependency(
          dependsOn: [3], // 12/24 hour format wheel
          calculateItemCount: (values) => values[0] == 0 ? 12 : 24, // 0 = 12-hour, 1 = 24-hour
        );

        // Minute dependency (fixed)
        final minuteDependency = WheelDependency(
          dependsOn: [0], // hour wheel
          calculateItemCount: (values) => 60, // always 60 minutes
        );

        expect(hourDependency.calculateNewItemCount([0]), equals(12)); // 12-hour format
        expect(hourDependency.calculateNewItemCount([1]), equals(24)); // 24-hour format
        expect(minuteDependency.calculateNewItemCount([5]), equals(60)); // always 60
      });
    });
  });
}