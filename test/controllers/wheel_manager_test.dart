import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:locuaz_wheel_pickers/src/controllers/wheel_manager.dart';
import 'package:locuaz_wheel_pickers/src/models/wheel_config.dart';
import 'package:locuaz_wheel_pickers/src/models/wheel_dependency.dart';

void main() {
  group('WheelManager', () {
    late WheelManager wheelManager;

    setUp(() {
      // Initialize GetX for testing
      Get.testMode = true;
      wheelManager = WheelManager();
    });

    tearDown(() {
      wheelManager.dispose();
      Get.reset();
    });

    group('initialization', () {
      test('initializes with empty state', () {
        expect(wheelManager.wheels, isEmpty);
        expect(wheelManager.controllers, isEmpty);
        expect(wheelManager.selectedIndices, isEmpty);
        expect(wheelManager.wheelKeys, isEmpty);
      });

      test('initializes with wheel configurations', () {
        final configs = [
          WheelConfig(
            itemCount: 24,
            initialIndex: 12,
            formatter: (index) => index.toString(),
            wheelId: 'hour_wheel',
          ),
          WheelConfig(
            itemCount: 60,
            initialIndex: 30,
            formatter: (index) => index.toString(),
            wheelId: 'minute_wheel',
          ),
        ];

        wheelManager.initialize(configs);

        expect(wheelManager.wheels, hasLength(2));
        expect(wheelManager.controllers, hasLength(2));
        expect(wheelManager.selectedIndices, equals([12, 30]));
        expect(wheelManager.wheelKeys, equals(['hour_wheel', 'minute_wheel']));
      });

      test('generates wheel keys when not provided', () {
        final configs = [
          WheelConfig(
            itemCount: 10,
            initialIndex: 5,
            formatter: (index) => index.toString(),
          ),
          WheelConfig(
            itemCount: 15,
            initialIndex: 8,
            formatter: (index) => index.toString(),
          ),
        ];

        wheelManager.initialize(configs);

        expect(wheelManager.wheelKeys[0], equals('wheel_0'));
        expect(wheelManager.wheelKeys[1], equals('wheel_1'));
      });

      test('registers dependencies during initialization', () {
        final dependency = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => values[0] + 10,
        );
        final configs = [
          WheelConfig(
            itemCount: 15,
            initialIndex: 5,
            formatter: (index) => index.toString(),
            dependency: dependency,
          ),
          WheelConfig(
            itemCount: 10,
            initialIndex: 3,
            formatter: (index) => index.toString(),
          ),
        ];

        wheelManager.initialize(configs);

        expect(wheelManager.dependencyManager.hasDependencies(0), isTrue);
        expect(wheelManager.dependencyManager.hasDependents(1), isTrue);
      });

      test('clears existing state before initialization', () {
        // Initialize first time
        final configs1 = [
          WheelConfig(itemCount: 10, initialIndex: 5, formatter: (i) => i.toString()),
        ];
        wheelManager.initialize(configs1);
        expect(wheelManager.wheels, hasLength(1));

        // Initialize second time with different configs
        final configs2 = [
          WheelConfig(itemCount: 20, initialIndex: 10, formatter: (i) => i.toString()),
          WheelConfig(itemCount: 30, initialIndex: 15, formatter: (i) => i.toString()),
        ];
        wheelManager.initialize(configs2);

        expect(wheelManager.wheels, hasLength(2));
        expect(wheelManager.wheels[0].itemCount, equals(20));
        expect(wheelManager.wheels[1].itemCount, equals(30));
      });
    });

    group('controller management', () {
      test('creates controllers with correct initial items', () {
        final configs = [
          WheelConfig(itemCount: 24, initialIndex: 10, formatter: (i) => i.toString()),
          WheelConfig(itemCount: 60, initialIndex: 25, formatter: (i) => i.toString()),
        ];

        wheelManager.initialize(configs);

        expect(wheelManager.controllers[0].initialItem, equals(10));
        expect(wheelManager.controllers[1].initialItem, equals(25));
      });

      test('validates controller state correctly', () {
        final configs = [
          WheelConfig(itemCount: 10, initialIndex: 5, formatter: (i) => i.toString()),
        ];

        wheelManager.initialize(configs);

        expect(wheelManager.areAllControllersValid(), isTrue);
        expect(wheelManager.getValidControllerCount(), equals(1));
      });

      test('handles disposed controllers gracefully', () {
        final configs = [
          WheelConfig(itemCount: 10, initialIndex: 5, formatter: (i) => i.toString()),
        ];

        wheelManager.initialize(configs);
        
        // Manually dispose a controller to simulate disposal
        wheelManager.controllers[0].dispose();

        expect(wheelManager.areAllControllersValid(), isFalse);
        expect(wheelManager.getValidControllerCount(), equals(0));
      });
    });

    group('wheel recreation', () {
      test('recreates wheel when item count changes', () {
        final configs = [
          WheelConfig(itemCount: 10, initialIndex: 5, formatter: (i) => i.toString()),
        ];

        wheelManager.initialize(configs);
        final originalController = wheelManager.controllers[0];

        final newConfig = configs[0].copyWith(itemCount: 15);
        wheelManager.recreateWheel(0, newConfig);

        expect(wheelManager.wheels[0].itemCount, equals(15));
        expect(wheelManager.controllers[0], isNot(equals(originalController)));
      });

      test('does not recreate wheel when only non-structural properties change', () {
        final configs = [
          WheelConfig(itemCount: 10, initialIndex: 5, formatter: (i) => i.toString()),
        ];

        wheelManager.initialize(configs);
        final originalController = wheelManager.controllers[0];

        final newConfig = configs[0].copyWith(
          formatter: (i) => 'Item $i', // non-structural change
          width: 100, // non-structural change
        );
        wheelManager.recreateWheel(0, newConfig);

        expect(wheelManager.wheels[0].formatter(5), equals('Item 5'));
        expect(wheelManager.wheels[0].width, equals(100));
        expect(wheelManager.controllers[0], equals(originalController)); // same controller
      });

      test('handles invalid wheel index gracefully', () {
        final configs = [
          WheelConfig(itemCount: 10, initialIndex: 5, formatter: (i) => i.toString()),
        ];

        wheelManager.initialize(configs);

        // Should not throw or crash
        expect(() => wheelManager.recreateWheel(-1, configs[0]), returnsNormally);
        expect(() => wheelManager.recreateWheel(5, configs[0]), returnsNormally);
      });

      test('recreates multiple wheels correctly', () {
        final configs = [
          WheelConfig(itemCount: 10, initialIndex: 5, formatter: (i) => i.toString()),
          WheelConfig(itemCount: 15, initialIndex: 8, formatter: (i) => i.toString()),
        ];

        wheelManager.initialize(configs);

        final newConfigs = [
          configs[0].copyWith(itemCount: 12),
          configs[1].copyWith(itemCount: 18),
        ];

        wheelManager.recreateWheels([0, 1], newConfigs);

        expect(wheelManager.wheels[0].itemCount, equals(12));
        expect(wheelManager.wheels[1].itemCount, equals(18));
      });

      test('validates recreation decisions', () {
        final configs = [
          WheelConfig(itemCount: 10, initialIndex: 5, formatter: (i) => i.toString()),
        ];

        wheelManager.initialize(configs);

        expect(wheelManager.needsRecreation(0), isFalse); // no dependencies
        
        final decision = wheelManager.getRecreationDecision(0);
        expect(decision.needsRecreation, isFalse);
        expect(decision.wheelIndex, equals(0));
      });
    });

    group('dependency-based recreation', () {
      test('recreates dependent wheels when dependency changes', () {
        final dependency = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => values[0] + 10,
        );
        final configs = [
          WheelConfig(
            itemCount: 15, // 5 + 10
            initialIndex: 5,
            formatter: (i) => i.toString(),
            dependency: dependency,
          ),
          WheelConfig(
            itemCount: 10,
            initialIndex: 5,
            formatter: (i) => i.toString(),
          ),
        ];

        wheelManager.initialize(configs);

        // Change selection in wheel 1 (dependency of wheel 0)
        wheelManager.updateSelectedIndex(1, 8); // 8 + 10 = 18

        // Wheel 0 should be recreated with new item count
        expect(wheelManager.wheels[0].itemCount, equals(18));
      });

      test('does not recreate independent wheels', () {
        final configs = [
          WheelConfig(itemCount: 10, initialIndex: 5, formatter: (i) => i.toString()),
          WheelConfig(itemCount: 15, initialIndex: 8, formatter: (i) => i.toString()),
        ];

        wheelManager.initialize(configs);
        final originalController0 = wheelManager.controllers[0];
        final originalController1 = wheelManager.controllers[1];

        wheelManager.updateSelectedIndex(0, 7);

        // Neither wheel should be recreated
        expect(wheelManager.controllers[0], equals(originalController0));
        expect(wheelManager.controllers[1], equals(originalController1));
        expect(wheelManager.selectedIndices[0], equals(7));
      });

      test('handles complex dependency chains', () {
        // Create chain: wheel 0 depends on 1, wheel 1 depends on 2
        final dependency1 = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => values[0] + 5,
        );
        final dependency2 = WheelDependency(
          dependsOn: [2],
          calculateItemCount: (values) => values[0] * 2,
        );

        final configs = [
          WheelConfig(
            itemCount: 10, // 5 + 5
            initialIndex: 5,
            formatter: (i) => i.toString(),
            dependency: dependency1,
          ),
          WheelConfig(
            itemCount: 10, // 5 * 2
            initialIndex: 3,
            formatter: (i) => i.toString(),
            dependency: dependency2,
          ),
          WheelConfig(
            itemCount: 8,
            initialIndex: 5,
            formatter: (i) => i.toString(),
          ),
        ];

        wheelManager.initialize(configs);

        // Change wheel 2, should cascade to wheels 1 and 0
        wheelManager.updateSelectedIndex(2, 3); // 3 * 2 = 6, then 6 + 5 = 11

        expect(wheelManager.wheels[1].itemCount, equals(6)); // 3 * 2
        expect(wheelManager.wheels[0].itemCount, equals(11)); // 6 + 5
      });
    });

    group('selection updates', () {
      test('updates selected index correctly', () {
        final configs = [
          WheelConfig(itemCount: 10, initialIndex: 5, formatter: (i) => i.toString()),
        ];

        wheelManager.initialize(configs);

        wheelManager.updateSelectedIndex(0, 8);

        expect(wheelManager.selectedIndices[0], equals(8));
      });

      test('handles out of bounds indices gracefully', () {
        final configs = [
          WheelConfig(itemCount: 10, initialIndex: 5, formatter: (i) => i.toString()),
        ];

        wheelManager.initialize(configs);

        // Should not crash or throw
        expect(() => wheelManager.updateSelectedIndex(-1, 5), returnsNormally);
        expect(() => wheelManager.updateSelectedIndex(5, 5), returnsNormally);
      });

      test('updates wheel position for independent wheels', () {
        final configs = [
          WheelConfig(itemCount: 10, initialIndex: 5, formatter: (i) => i.toString()),
        ];

        wheelManager.initialize(configs);

        wheelManager.updateWheelPosition(0, 7);

        expect(wheelManager.selectedIndices[0], equals(7));
      });
    });

    group('performance metrics', () {
      test('tracks recreation metrics', () {
        final configs = [
          WheelConfig(itemCount: 10, initialIndex: 5, formatter: (i) => i.toString()),
        ];

        wheelManager.initialize(configs);

        final initialCount = wheelManager.performanceMetrics.recreationCount;

        final newConfig = configs[0].copyWith(itemCount: 15);
        wheelManager.recreateWheelImmediate(0, newConfig);

        expect(wheelManager.performanceMetrics.recreationCount, equals(initialCount + 1));
      });

      test('provides performance metrics access', () {
        expect(wheelManager.performanceMetrics, isNotNull);
        expect(wheelManager.performanceMetrics.recreationCount, isA<int>());
        expect(wheelManager.performanceMetrics.averageRecreationTime, isA<double>());
      });
    });

    group('memory management', () {
      test('disposes controllers properly', () {
        final configs = [
          WheelConfig(itemCount: 10, initialIndex: 5, formatter: (i) => i.toString()),
        ];

        wheelManager.initialize(configs);
        final controller = wheelManager.controllers[0];

        wheelManager.dispose();

        // Controller should be disposed
        expect(() => controller.initialItem, throwsA(isA<AssertionError>()));
      });

      test('trims controller pool when needed', () {
        final configs = [
          WheelConfig(itemCount: 10, initialIndex: 5, formatter: (i) => i.toString()),
        ];

        wheelManager.initialize(configs);

        // This should not throw
        expect(() => wheelManager.trimControllerPool(maxSize: 5), returnsNormally);
      });
    });

    group('error handling', () {
      test('handles invalid dependency registration gracefully', () {
        final invalidDependency = WheelDependency(
          dependsOn: [], // invalid empty dependency
          calculateItemCount: (values) => 10,
        );
        final configs = [
          WheelConfig(
            itemCount: 10,
            initialIndex: 5,
            formatter: (i) => i.toString(),
            dependency: invalidDependency,
          ),
        ];

        // Should not throw, but dependency won't be registered
        expect(() => wheelManager.initialize(configs), returnsNormally);
        expect(wheelManager.dependencyManager.hasDependencies(0), isFalse);
      });

      test('handles recreation with invalid configurations', () {
        final configs = [
          WheelConfig(itemCount: 10, initialIndex: 5, formatter: (i) => i.toString()),
        ];

        wheelManager.initialize(configs);

        final invalidConfig = WheelConfig(
          itemCount: 0, // invalid
          initialIndex: 0,
          formatter: (i) => i.toString(),
        );

        // Should handle gracefully without crashing
        expect(() => wheelManager.recreateWheel(0, invalidConfig), returnsNormally);
      });

      test('handles exceptions in dependency calculations', () {
        final faultyDependency = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => throw Exception('Calculation error'),
        );
        final configs = [
          WheelConfig(
            itemCount: 10,
            initialIndex: 5,
            formatter: (i) => i.toString(),
            dependency: faultyDependency,
          ),
          WheelConfig(
            itemCount: 5,
            initialIndex: 2,
            formatter: (i) => i.toString(),
          ),
        ];

        wheelManager.initialize(configs);

        // Should handle exception gracefully
        expect(() => wheelManager.updateSelectedIndex(1, 3), returnsNormally);
      });
    });

    group('real-world scenarios', () {
      test('date picker scenario works correctly', () {
        final dayDependency = WheelDependency(
          dependsOn: [1, 2], // month, year
          calculateItemCount: (values) {
            final month = values[0] + 1;
            final year = 2000 + values[1];
            return DateTime(year, month + 1, 0).day;
          },
        );

        final configs = [
          WheelConfig(
            itemCount: 31, // January
            initialIndex: 15,
            formatter: (i) => (i + 1).toString(),
            wheelId: 'day',
            dependency: dayDependency,
          ),
          WheelConfig(
            itemCount: 12,
            initialIndex: 0, // January
            formatter: (i) => ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][i],
            wheelId: 'month',
          ),
          WheelConfig(
            itemCount: 50,
            initialIndex: 24, // 2024
            formatter: (i) => (2000 + i).toString(),
            wheelId: 'year',
          ),
        ];

        wheelManager.initialize(configs);

        // Switch to February 2024 (leap year)
        wheelManager.updateSelectedIndex(1, 1); // February

        // Day wheel should be recreated with 29 days
        expect(wheelManager.wheels[0].itemCount, equals(29));

        // Switch to February 2023 (non-leap year)
        wheelManager.updateSelectedIndex(2, 23); // 2023

        // Day wheel should be recreated with 28 days
        expect(wheelManager.wheels[0].itemCount, equals(28));
      });

      test('time picker scenario works correctly', () {
        final hourDependency = WheelDependency(
          dependsOn: [3], // format wheel
          calculateItemCount: (values) => values[0] == 0 ? 12 : 24,
        );

        final configs = [
          WheelConfig(
            itemCount: 24, // 24-hour format initially
            initialIndex: 15,
            formatter: (i) => i.toString(),
            wheelId: 'hour',
            dependency: hourDependency,
          ),
          WheelConfig(
            itemCount: 60,
            initialIndex: 30,
            formatter: (i) => i.toString().padLeft(2, '0'),
            wheelId: 'minute',
          ),
          WheelConfig(
            itemCount: 60,
            initialIndex: 0,
            formatter: (i) => i.toString().padLeft(2, '0'),
            wheelId: 'second',
          ),
          WheelConfig(
            itemCount: 2,
            initialIndex: 1, // 24-hour format
            formatter: (i) => i == 0 ? '12h' : '24h',
            wheelId: 'format',
          ),
        ];

        wheelManager.initialize(configs);

        // Switch to 12-hour format
        wheelManager.updateSelectedIndex(3, 0);

        // Hour wheel should be recreated with 12 hours
        expect(wheelManager.wheels[0].itemCount, equals(12));
      });
    });

    group('batch operations', () {
      test('recreates multiple wheels as needed', () {
        final configs = [
          WheelConfig(itemCount: 10, initialIndex: 5, formatter: (i) => i.toString()),
          WheelConfig(itemCount: 15, initialIndex: 8, formatter: (i) => i.toString()),
          WheelConfig(itemCount: 20, initialIndex: 10, formatter: (i) => i.toString()),
        ];

        wheelManager.initialize(configs);

        wheelManager.recreateWheelsAsNeeded();

        // Should complete without errors (no recreations needed for independent wheels)
        expect(wheelManager.wheels, hasLength(3));
      });

      test('gets recreation decisions for all wheels', () {
        final configs = [
          WheelConfig(itemCount: 10, initialIndex: 5, formatter: (i) => i.toString()),
          WheelConfig(itemCount: 15, initialIndex: 8, formatter: (i) => i.toString()),
        ];

        wheelManager.initialize(configs);

        final decisions = wheelManager.getAllRecreationDecisions();

        expect(decisions, hasLength(2));
        expect(decisions[0].wheelIndex, equals(0));
        expect(decisions[1].wheelIndex, equals(1));
        expect(decisions.every((d) => !d.needsRecreation), isTrue); // No dependencies
      });
    });
  });
}