import 'package:flutter_test/flutter_test.dart';
import 'package:locuaz_wheel_pickers/src/controllers/dependency_manager.dart';
import 'package:locuaz_wheel_pickers/src/models/wheel_config.dart';
import 'package:locuaz_wheel_pickers/src/models/wheel_dependency.dart';

void main() {
  group('DependencyManager', () {
    late DependencyManager manager;

    setUp(() {
      manager = DependencyManager();
    });

    group('registerDependency', () {
      test('registers valid dependency successfully', () {
        final dependency = WheelDependency(
          dependsOn: [1, 2],
          calculateItemCount: (values) => values[0] + values[1],
        );

        expect(() => manager.registerDependency(0, dependency, totalWheelCount: 3), returnsNormally);
        expect(manager.hasDependencies(0), isTrue);
        expect(manager.getDependency(0), equals(dependency));
      });

      test('throws error for invalid dependency', () {
        final invalidDependency = WheelDependency(
          dependsOn: [], // empty dependsOn is invalid
          calculateItemCount: (values) => 10,
        );

        expect(
          () => manager.registerDependency(0, invalidDependency),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws error for circular dependency', () {
        final dependency1 = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => values[0],
        );
        final dependency2 = WheelDependency(
          dependsOn: [0], // creates cycle: 0 -> 1 -> 0
          calculateItemCount: (values) => values[0],
        );

        manager.registerDependency(0, dependency1);
        
        expect(
          () => manager.registerDependency(1, dependency2),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('updates reverse mapping correctly', () {
        final dependency = WheelDependency(
          dependsOn: [1, 2],
          calculateItemCount: (values) => values[0] + values[1],
        );

        manager.registerDependency(0, dependency);

        expect(manager.getDependentWheels(1), contains(0));
        expect(manager.getDependentWheels(2), contains(0));
        expect(manager.hasDependents(1), isTrue);
        expect(manager.hasDependents(2), isTrue);
      });

      test('replaces existing dependency', () {
        final dependency1 = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => values[0],
        );
        final dependency2 = WheelDependency(
          dependsOn: [2],
          calculateItemCount: (values) => values[0] * 2,
        );

        manager.registerDependency(0, dependency1);
        manager.registerDependency(0, dependency2);

        expect(manager.getDependency(0), equals(dependency2));
        expect(manager.getDependentWheels(1), isEmpty); // old dependency removed
        expect(manager.getDependentWheels(2), contains(0)); // new dependency added
      });

      test('validates bounds when totalWheelCount provided', () {
        final dependency = WheelDependency(
          dependsOn: [5], // index 5 >= totalWheelCount 3
          calculateItemCount: (values) => values[0],
        );

        expect(
          () => manager.registerDependency(0, dependency, totalWheelCount: 3),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('unregisterDependency', () {
      test('removes dependency and cleans up reverse mapping', () {
        final dependency = WheelDependency(
          dependsOn: [1, 2],
          calculateItemCount: (values) => values[0] + values[1],
        );

        manager.registerDependency(0, dependency);
        expect(manager.hasDependencies(0), isTrue);
        expect(manager.hasDependents(1), isTrue);

        manager.unregisterDependency(0);

        expect(manager.hasDependencies(0), isFalse);
        expect(manager.getDependency(0), isNull);
        expect(manager.getDependentWheels(1), isEmpty);
        expect(manager.getDependentWheels(2), isEmpty);
        expect(manager.hasDependents(1), isFalse);
        expect(manager.hasDependents(2), isFalse);
      });

      test('handles non-existent dependency gracefully', () {
        expect(() => manager.unregisterDependency(0), returnsNormally);
        expect(manager.hasDependencies(0), isFalse);
      });

      test('cleans up empty dependent sets', () {
        final dependency1 = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => values[0],
        );
        final dependency2 = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => values[0] * 2,
        );

        manager.registerDependency(0, dependency1);
        manager.registerDependency(2, dependency2);
        
        expect(manager.getDependentWheels(1), containsAll([0, 2]));

        manager.unregisterDependency(0);
        expect(manager.getDependentWheels(1), contains(2));
        expect(manager.getDependentWheels(1), isNot(contains(0)));

        manager.unregisterDependency(2);
        expect(manager.getDependentWheels(1), isEmpty);
        expect(manager.hasDependents(1), isFalse);
      });
    });

    group('getDependentWheels', () {
      test('returns correct dependent wheels', () {
        final dependency1 = WheelDependency(
          dependsOn: [1, 2],
          calculateItemCount: (values) => values[0] + values[1],
        );
        final dependency2 = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => values[0] * 2,
        );

        manager.registerDependency(0, dependency1);
        manager.registerDependency(3, dependency2);

        final dependents = manager.getDependentWheels(1);
        expect(dependents, containsAll([0, 3]));
        expect(dependents, hasLength(2));
      });

      test('returns empty set for wheel with no dependents', () {
        final dependents = manager.getDependentWheels(5);
        expect(dependents, isEmpty);
      });

      test('returns immutable copy of dependents', () {
        final dependency = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => values[0],
        );

        manager.registerDependency(0, dependency);
        final dependents1 = manager.getDependentWheels(1);
        final dependents2 = manager.getDependentWheels(1);

        expect(identical(dependents1, dependents2), isFalse);
        expect(dependents1, equals(dependents2));
      });
    });

    group('calculateNewConfig', () {
      test('calculates new config for dependent wheel', () {
        final dependency = WheelDependency(
          dependsOn: [1, 2],
          calculateItemCount: (values) => values[0] + values[1] + 10,
          calculateInitialIndex: (values, current) => (values[0] + values[1]) ~/ 2,
        );
        final currentConfig = WheelConfig(
          itemCount: 20,
          initialIndex: 5,
          formatter: (index) => index.toString(),
        );

        manager.registerDependency(0, dependency);

        final newConfig = manager.calculateNewConfig(0, currentConfig, [0, 3, 7, 0]);

        expect(newConfig, isNotNull);
        expect(newConfig!.itemCount, equals(20)); // 3 + 7 + 10
        expect(newConfig.initialIndex, equals(5)); // (3 + 7) / 2
        expect(newConfig.formatter(5), equals('5'));
      });

      test('returns null for wheel without dependencies', () {
        final config = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
        );

        final newConfig = manager.calculateNewConfig(0, config, [5, 3, 7]);
        expect(newConfig, isNull);
      });

      test('returns null when dependency index out of bounds', () {
        final dependency = WheelDependency(
          dependsOn: [5], // index 5 doesn't exist in selections array
          calculateItemCount: (values) => values[0],
        );
        final config = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
        );

        manager.registerDependency(0, dependency);

        final newConfig = manager.calculateNewConfig(0, config, [1, 2, 3]); // length 3
        expect(newConfig, isNull);
      });

      test('returns null when calculation fails', () {
        final dependency = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => throw Exception('Calculation error'),
        );
        final config = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
        );

        manager.registerDependency(0, dependency);

        final newConfig = manager.calculateNewConfig(0, config, [0, 5]);
        expect(newConfig, isNull);
      });

      test('uses buildFormatter when provided', () {
        final dependency = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => values[0] + 5,
          buildFormatter: (values) => (index) => 'Item $index (${values[0]})',
        );
        final config = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
        );

        manager.registerDependency(0, dependency);

        final newConfig = manager.calculateNewConfig(0, config, [0, 3]);

        expect(newConfig, isNotNull);
        expect(newConfig!.formatter(2), equals('Item 2 (3)'));
      });
    });

    group('needsRecreation', () {
      test('returns false for wheel without dependencies', () {
        final config = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
        );

        expect(manager.needsRecreation(0, config, [5, 3, 7]), isFalse);
      });

      test('returns true when recreation is needed', () {
        final dependency = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => values[0] + 10,
        );
        final config = WheelConfig(
          itemCount: 15,
          initialIndex: 5,
          formatter: (index) => index.toString(),
          dependency: dependency,
        );

        manager.registerDependency(0, dependency);

        // Current config has 15 items, but dependency calculation gives 18 (8 + 10)
        expect(manager.needsRecreation(0, config, [0, 8]), isTrue);
      });

      test('returns false when recreation is not needed', () {
        final dependency = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => values[0] + 10,
        );
        final config = WheelConfig(
          itemCount: 15,
          initialIndex: 5,
          formatter: (index) => index.toString(),
          dependency: dependency,
        );

        manager.registerDependency(0, dependency);

        // Current config has 15 items, dependency calculation also gives 15 (5 + 10)
        expect(manager.needsRecreation(0, config, [0, 5]), isFalse);
      });

      test('returns false when dependency index out of bounds', () {
        final dependency = WheelDependency(
          dependsOn: [5],
          calculateItemCount: (values) => values[0],
        );
        final config = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
          dependency: dependency,
        );

        manager.registerDependency(0, dependency);

        expect(manager.needsRecreation(0, config, [1, 2, 3]), isFalse);
      });
    });

    group('validateGraph', () {
      test('returns true for valid graph', () {
        final dependency1 = WheelDependency(
          dependsOn: [2],
          calculateItemCount: (values) => values[0],
        );
        final dependency2 = WheelDependency(
          dependsOn: [2, 3],
          calculateItemCount: (values) => values[0] + values[1],
        );

        manager.registerDependency(0, dependency1);
        manager.registerDependency(1, dependency2);

        expect(manager.validateGraph(totalWheelCount: 4), isTrue);
      });

      test('returns false for graph with circular dependencies', () {
        final dependency1 = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => values[0],
        );
        
        manager.registerDependency(0, dependency1);
        
        // Force circular dependency using testing method
        final dependency2 = WheelDependency(
          dependsOn: [0],
          calculateItemCount: (values) => values[0],
        );
        manager.setDependencyForTesting(1, dependency2);

        expect(manager.validateGraph(), isFalse);
      });

      test('returns false for invalid individual dependency', () {
        final validDependency = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => values[0],
        );
        final invalidDependency = WheelDependency(
          dependsOn: [5], // out of bounds
          calculateItemCount: (values) => values[0],
        );

        manager.registerDependency(0, validDependency);
        manager.setDependencyForTesting(1, invalidDependency);

        expect(manager.validateGraph(totalWheelCount: 3), isFalse);
      });
    });

    group('hasCircularDependencies', () {
      test('returns false for acyclic graph', () {
        final dependency1 = WheelDependency(
          dependsOn: [2],
          calculateItemCount: (values) => values[0],
        );
        final dependency2 = WheelDependency(
          dependsOn: [3],
          calculateItemCount: (values) => values[0],
        );

        manager.registerDependency(0, dependency1);
        manager.registerDependency(1, dependency2);

        expect(manager.hasCircularDependencies(), isFalse);
      });

      test('returns true for direct cycle', () {
        final dependency1 = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => values[0],
        );
        final dependency2 = WheelDependency(
          dependsOn: [0],
          calculateItemCount: (values) => values[0],
        );

        manager.setDependencyForTesting(0, dependency1);
        manager.setDependencyForTesting(1, dependency2);

        expect(manager.hasCircularDependencies(), isTrue);
      });

      test('returns true for indirect cycle', () {
        final dependency1 = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => values[0],
        );
        final dependency2 = WheelDependency(
          dependsOn: [2],
          calculateItemCount: (values) => values[0],
        );
        final dependency3 = WheelDependency(
          dependsOn: [0],
          calculateItemCount: (values) => values[0],
        );

        manager.setDependencyForTesting(0, dependency1);
        manager.setDependencyForTesting(1, dependency2);
        manager.setDependencyForTesting(2, dependency3);

        expect(manager.hasCircularDependencies(), isTrue);
      });

      test('returns true for self-dependency', () {
        final selfDependency = WheelDependency(
          dependsOn: [0],
          calculateItemCount: (values) => values[0],
        );

        manager.setDependencyForTesting(0, selfDependency);

        expect(manager.hasCircularDependencies(), isTrue);
      });
    });

    group('getTopologicalOrder', () {
      test('returns correct order for acyclic graph', () {
        final dependency1 = WheelDependency(
          dependsOn: [2, 3],
          calculateItemCount: (values) => values[0] + values[1],
        );
        final dependency2 = WheelDependency(
          dependsOn: [3],
          calculateItemCount: (values) => values[0],
        );

        manager.registerDependency(0, dependency1);
        manager.registerDependency(1, dependency2);

        final order = manager.getTopologicalOrder();

        // Dependencies should come before dependents
        expect(order.indexOf(2), lessThan(order.indexOf(0)));
        expect(order.indexOf(3), lessThan(order.indexOf(0)));
        expect(order.indexOf(3), lessThan(order.indexOf(1)));
      });

      test('returns empty list for cyclic graph', () {
        final dependency1 = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => values[0],
        );
        final dependency2 = WheelDependency(
          dependsOn: [0],
          calculateItemCount: (values) => values[0],
        );

        manager.setDependencyForTesting(0, dependency1);
        manager.setDependencyForTesting(1, dependency2);

        expect(manager.getTopologicalOrder(), isEmpty);
      });

      test('handles complex dependency graph', () {
        // Create a more complex graph: 0->1, 0->2, 1->3, 2->3
        final dependency1 = WheelDependency(
          dependsOn: [1, 2],
          calculateItemCount: (values) => values[0] + values[1],
        );
        final dependency2 = WheelDependency(
          dependsOn: [3],
          calculateItemCount: (values) => values[0],
        );
        final dependency3 = WheelDependency(
          dependsOn: [3],
          calculateItemCount: (values) => values[0],
        );

        manager.registerDependency(0, dependency1);
        manager.registerDependency(1, dependency2);
        manager.registerDependency(2, dependency3);

        final order = manager.getTopologicalOrder();

        // Verify dependencies come before dependents
        expect(order.indexOf(3), lessThan(order.indexOf(1)));
        expect(order.indexOf(3), lessThan(order.indexOf(2)));
        expect(order.indexOf(1), lessThan(order.indexOf(0)));
        expect(order.indexOf(2), lessThan(order.indexOf(0)));
      });
    });

    group('getGraphInfo', () {
      test('returns correct information for empty graph', () {
        final info = manager.getGraphInfo();

        expect(info['wheelCount'], equals(0));
        expect(info['dependencyCount'], equals(0));
        expect(info['hasCircularDependencies'], isFalse);
        expect(info['topologicalOrder'], isEmpty);
        expect(info['dependencies'], isEmpty);
        expect(info['dependents'], isEmpty);
      });

      test('returns correct information for populated graph', () {
        final dependency1 = WheelDependency(
          dependsOn: [1, 2],
          calculateItemCount: (values) => values[0] + values[1],
        );
        final dependency2 = WheelDependency(
          dependsOn: [2],
          calculateItemCount: (values) => values[0],
        );

        manager.registerDependency(0, dependency1);
        manager.registerDependency(3, dependency2);

        final info = manager.getGraphInfo();

        expect(info['wheelCount'], equals(2));
        expect(info['dependencyCount'], equals(3)); // 2 + 1
        expect(info['hasCircularDependencies'], isFalse);
        expect(info['topologicalOrder'], isNotEmpty);
        expect(info['dependencies'], containsPair(0, [1, 2]));
        expect(info['dependencies'], containsPair(3, [2]));
        expect(info['dependents'], containsPair(1, [0]));
        expect(info['dependents'], containsPair(2, [0, 3]));
      });
    });

    group('clear', () {
      test('clears all dependencies and dependents', () {
        final dependency1 = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => values[0],
        );
        final dependency2 = WheelDependency(
          dependsOn: [2],
          calculateItemCount: (values) => values[0],
        );

        manager.registerDependency(0, dependency1);
        manager.registerDependency(1, dependency2);

        expect(manager.getDependentWheelCount(), equals(2));
        expect(manager.hasDependencies(0), isTrue);
        expect(manager.hasDependents(1), isTrue);

        manager.clear();

        expect(manager.getDependentWheelCount(), equals(0));
        expect(manager.hasDependencies(0), isFalse);
        expect(manager.hasDependents(1), isFalse);
        expect(manager.getDependentWheels(1), isEmpty);
        expect(manager.getDependentWheels(2), isEmpty);
      });
    });

    group('utility methods', () {
      test('getDependency returns correct dependency', () {
        final dependency = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => values[0],
        );

        expect(manager.getDependency(0), isNull);

        manager.registerDependency(0, dependency);
        expect(manager.getDependency(0), equals(dependency));
      });

      test('hasDependencies works correctly', () {
        expect(manager.hasDependencies(0), isFalse);

        final dependency = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => values[0],
        );
        manager.registerDependency(0, dependency);

        expect(manager.hasDependencies(0), isTrue);
        expect(manager.hasDependencies(1), isFalse);
      });

      test('hasDependents works correctly', () {
        expect(manager.hasDependents(1), isFalse);

        final dependency = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => values[0],
        );
        manager.registerDependency(0, dependency);

        expect(manager.hasDependents(1), isTrue);
        expect(manager.hasDependents(0), isFalse);
      });

      test('getDependentWheelCount returns correct count', () {
        expect(manager.getDependentWheelCount(), equals(0));

        final dependency1 = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => values[0],
        );
        final dependency2 = WheelDependency(
          dependsOn: [2],
          calculateItemCount: (values) => values[0],
        );

        manager.registerDependency(0, dependency1);
        expect(manager.getDependentWheelCount(), equals(1));

        manager.registerDependency(3, dependency2);
        expect(manager.getDependentWheelCount(), equals(2));

        manager.unregisterDependency(0);
        expect(manager.getDependentWheelCount(), equals(1));
      });
    });

    group('real-world scenarios', () {
      test('date picker dependencies work correctly', () {
        // Day wheel depends on month and year
        final dayDependency = WheelDependency(
          dependsOn: [1, 2], // month, year
          calculateItemCount: (values) {
            final month = values[0] + 1;
            final year = 2000 + values[1];
            return DateTime(year, month + 1, 0).day;
          },
        );

        manager.registerDependency(0, dayDependency);

        final dayConfig = WheelConfig(
          itemCount: 31,
          initialIndex: 15,
          formatter: (index) => (index + 1).toString(),
        );

        // February 2024 (leap year) - should have 29 days
        final newConfig = manager.calculateNewConfig(0, dayConfig, [15, 1, 24]);
        expect(newConfig, isNotNull);
        expect(newConfig!.itemCount, equals(29));

        // February 2023 (non-leap year) - should have 28 days
        final newConfig2 = manager.calculateNewConfig(0, dayConfig, [15, 1, 23]);
        expect(newConfig2, isNotNull);
        expect(newConfig2!.itemCount, equals(28));

        // April 2024 - should have 30 days
        final newConfig3 = manager.calculateNewConfig(0, dayConfig, [15, 3, 24]);
        expect(newConfig3, isNotNull);
        expect(newConfig3!.itemCount, equals(30));
      });

      test('cascading dependencies work correctly', () {
        // State depends on country, city depends on state
        final stateDependency = WheelDependency(
          dependsOn: [0], // country
          calculateItemCount: (values) => values[0] == 0 ? 50 : 10, // USA: 50 states, others: 10 regions
        );
        final cityDependency = WheelDependency(
          dependsOn: [1], // state
          calculateItemCount: (values) => values[0] * 5, // 5 cities per state/region
        );

        manager.registerDependency(1, stateDependency);
        manager.registerDependency(2, cityDependency);

        // Verify dependency graph
        expect(manager.getDependentWheels(0), contains(1)); // country -> state
        expect(manager.getDependentWheels(1), contains(2)); // state -> city
        expect(manager.hasCircularDependencies(), isFalse);

        // Verify topological order
        final order = manager.getTopologicalOrder();
        expect(order.indexOf(0), lessThan(order.indexOf(1)));
        expect(order.indexOf(1), lessThan(order.indexOf(2)));
      });

      test('complex time picker dependencies work correctly', () {
        // Hour format affects hour count, hour affects minute display
        final hourDependency = WheelDependency(
          dependsOn: [3], // format wheel (12/24 hour)
          calculateItemCount: (values) => values[0] == 0 ? 12 : 24,
        );
        final minuteDependency = WheelDependency(
          dependsOn: [0], // hour wheel
          calculateItemCount: (values) => 60, // always 60 minutes
          buildFormatter: (values) => (index) => '${index.toString().padLeft(2, '0')}',
        );

        manager.registerDependency(0, hourDependency);
        manager.registerDependency(1, minuteDependency);

        final hourConfig = WheelConfig(
          itemCount: 24,
          initialIndex: 10,
          formatter: (index) => index.toString(),
        );
        final minuteConfig = WheelConfig(
          itemCount: 60,
          initialIndex: 30,
          formatter: (index) => index.toString(),
        );

        // Switch to 12-hour format
        final newHourConfig = manager.calculateNewConfig(0, hourConfig, [10, 30, 0, 0]);
        expect(newHourConfig, isNotNull);
        expect(newHourConfig!.itemCount, equals(12));

        // Minute config should get updated formatter
        final newMinuteConfig = manager.calculateNewConfig(1, minuteConfig, [10, 30, 0, 0]);
        expect(newMinuteConfig, isNotNull);
        expect(newMinuteConfig!.formatter(5), equals('05'));
      });
    });

    group('edge cases and error handling', () {
      test('handles empty dependency arrays gracefully', () {
        // This should be caught by validation, but test defensive programming
        final dependency = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => values.isEmpty ? 1 : values[0],
        );

        manager.registerDependency(0, dependency);

        final config = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
        );

        // Empty selections array
        final newConfig = manager.calculateNewConfig(0, config, []);
        expect(newConfig, isNull); // Should fail gracefully
      });

      test('handles calculation exceptions gracefully', () {
        final dependency = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => values[0] ~/ 0, // division by zero
        );

        manager.registerDependency(0, dependency);

        final config = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
        );

        final newConfig = manager.calculateNewConfig(0, config, [5, 0]);
        expect(newConfig, isNull); // Should handle exception gracefully
      });

      test('handles very large dependency graphs', () {
        // Create a chain of 100 dependencies: 0->1->2->...->99
        for (int i = 0; i < 99; i++) {
          final dependency = WheelDependency(
            dependsOn: [i + 1],
            calculateItemCount: (values) => values[0] + 1,
          );
          manager.registerDependency(i, dependency);
        }

        expect(manager.getDependentWheelCount(), equals(99));
        expect(manager.hasCircularDependencies(), isFalse);

        final order = manager.getTopologicalOrder();
        expect(order, hasLength(100)); // All wheels should be in order

        // Verify order is correct
        for (int i = 0; i < 99; i++) {
          expect(order.indexOf(i + 1), lessThan(order.indexOf(i)));
        }
      });
    });
  });
}