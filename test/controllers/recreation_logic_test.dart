import 'package:flutter_test/flutter_test.dart';
import 'package:locuaz_wheel_pickers/src/controllers/recreation_logic.dart';
import 'package:locuaz_wheel_pickers/src/controllers/dependency_manager.dart';
import 'package:locuaz_wheel_pickers/src/controllers/recreation_decision.dart';
import 'package:locuaz_wheel_pickers/src/models/wheel_config.dart';
import 'package:locuaz_wheel_pickers/src/models/wheel_dependency.dart';

void main() {
  group('RecreationLogic', () {
    late RecreationLogic recreationLogic;
    late DependencyManager dependencyManager;

    setUp(() {
      recreationLogic = RecreationLogic();
      dependencyManager = DependencyManager();
    });

    group('shouldRecreateWheel', () {
      test('returns no recreation needed for wheel without dependencies', () {
        final config = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
        );

        final decision = recreationLogic.shouldRecreateWheel(
          wheelIndex: 0,
          currentConfig: config,
          allSelections: [5, 3, 7],
          dependencyManager: dependencyManager,
        );

        expect(decision.needsRecreation, isFalse);
        expect(decision.wheelIndex, equals(0));
        expect(decision.newConfig, isNull);
        expect(decision.reason, contains('no dependencies'));
      });

      test('returns recreation needed when item count changes', () {
        final dependency = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => values[0] + 10,
        );
        final config = WheelConfig(
          itemCount: 15,
          initialIndex: 5,
          formatter: (index) => index.toString(),
        );

        dependencyManager.registerDependency(0, dependency);

        // Current config has 15 items, but dependency calculation gives 18 (8 + 10)
        final decision = recreationLogic.shouldRecreateWheel(
          wheelIndex: 0,
          currentConfig: config,
          allSelections: [5, 8],
          dependencyManager: dependencyManager,
        );

        expect(decision.needsRecreation, isTrue);
        expect(decision.wheelIndex, equals(0));
        expect(decision.newConfig, isNotNull);
        expect(decision.newConfig!.itemCount, equals(18));
        expect(decision.reason, contains('Item count changed'));
      });

      test('returns no recreation needed when item count unchanged', () {
        final dependency = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => values[0] + 10,
        );
        final config = WheelConfig(
          itemCount: 15,
          initialIndex: 5,
          formatter: (index) => index.toString(),
        );

        dependencyManager.registerDependency(0, dependency);

        // Current config has 15 items, dependency calculation also gives 15 (5 + 10)
        final decision = recreationLogic.shouldRecreateWheel(
          wheelIndex: 0,
          currentConfig: config,
          allSelections: [5, 5],
          dependencyManager: dependencyManager,
        );

        expect(decision.needsRecreation, isFalse);
        expect(decision.wheelIndex, equals(0));
        expect(decision.newConfig, isNull);
        expect(decision.reason, contains('Configuration unchanged'));
      });

      test('returns no recreation when config calculation fails', () {
        final dependency = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => throw Exception('Calculation error'),
        );
        final config = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
        );

        dependencyManager.registerDependency(0, dependency);

        final decision = recreationLogic.shouldRecreateWheel(
          wheelIndex: 0,
          currentConfig: config,
          allSelections: [5, 3],
          dependencyManager: dependencyManager,
        );

        expect(decision.needsRecreation, isFalse);
        expect(decision.reason, contains('Failed to calculate'));
      });

      test('handles exceptions gracefully', () {
        final config = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
        );

        // Force an exception by providing invalid dependency manager state
        final decision = recreationLogic.shouldRecreateWheel(
          wheelIndex: -1, // invalid index
          currentConfig: config,
          allSelections: [5, 3],
          dependencyManager: dependencyManager,
        );

        expect(decision.needsRecreation, isFalse);
        expect(decision.reason, contains('Error during recreation check'));
      });

      test('works with complex dependencies', () {
        final dependency = WheelDependency(
          dependsOn: [1, 2],
          calculateItemCount: (values) => values[0] * values[1] + 5,
          calculateInitialIndex: (values, current) => (values[0] + values[1]) ~/ 2,
        );
        final config = WheelConfig(
          itemCount: 20,
          initialIndex: 10,
          formatter: (index) => index.toString(),
        );

        dependencyManager.registerDependency(0, dependency);

        final decision = recreationLogic.shouldRecreateWheel(
          wheelIndex: 0,
          currentConfig: config,
          allSelections: [10, 3, 4], // 3 * 4 + 5 = 17
          dependencyManager: dependencyManager,
        );

        expect(decision.needsRecreation, isTrue);
        expect(decision.newConfig!.itemCount, equals(17));
        expect(decision.newConfig!.initialIndex, equals(3)); // (3 + 4) / 2
      });
    });

    group('getRecreationDecisionsForChange', () {
      test('returns decisions for dependent wheels only', () {
        final dependency1 = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => values[0] + 10,
        );
        final dependency2 = WheelDependency(
          dependsOn: [2],
          calculateItemCount: (values) => values[0] * 2,
        );

        final configs = [
          WheelConfig(itemCount: 15, initialIndex: 5, formatter: (i) => i.toString()),
          WheelConfig(itemCount: 10, initialIndex: 3, formatter: (i) => i.toString()),
          WheelConfig(itemCount: 20, initialIndex: 8, formatter: (i) => i.toString()),
        ];

        dependencyManager.registerDependency(0, dependency1); // depends on wheel 1
        dependencyManager.registerDependency(2, dependency2); // depends on wheel 2

        // Wheel 1 changed - only wheel 0 should be checked
        final decisions = recreationLogic.getRecreationDecisionsForChange(
          changedWheelIndex: 1,
          wheelConfigs: configs,
          allSelections: [5, 8, 10],
          dependencyManager: dependencyManager,
        );

        expect(decisions, hasLength(1));
        expect(decisions[0].wheelIndex, equals(0));
        expect(decisions[0].needsRecreation, isTrue); // 8 + 10 = 18 != 15
      });

      test('returns empty list when no wheels depend on changed wheel', () {
        final configs = [
          WheelConfig(itemCount: 10, initialIndex: 5, formatter: (i) => i.toString()),
          WheelConfig(itemCount: 10, initialIndex: 3, formatter: (i) => i.toString()),
        ];

        final decisions = recreationLogic.getRecreationDecisionsForChange(
          changedWheelIndex: 0,
          wheelConfigs: configs,
          allSelections: [5, 3],
          dependencyManager: dependencyManager,
        );

        expect(decisions, isEmpty);
      });

      test('handles multiple dependent wheels', () {
        final dependency1 = WheelDependency(
          dependsOn: [2],
          calculateItemCount: (values) => values[0] + 5,
        );
        final dependency2 = WheelDependency(
          dependsOn: [2],
          calculateItemCount: (values) => values[0] * 2,
        );

        final configs = [
          WheelConfig(itemCount: 10, initialIndex: 5, formatter: (i) => i.toString()),
          WheelConfig(itemCount: 20, initialIndex: 8, formatter: (i) => i.toString()),
          WheelConfig(itemCount: 5, initialIndex: 2, formatter: (i) => i.toString()),
        ];

        dependencyManager.registerDependency(0, dependency1);
        dependencyManager.registerDependency(1, dependency2);

        // Wheel 2 changed - both wheels 0 and 1 should be checked
        final decisions = recreationLogic.getRecreationDecisionsForChange(
          changedWheelIndex: 2,
          wheelConfigs: configs,
          allSelections: [5, 8, 3],
          dependencyManager: dependencyManager,
        );

        expect(decisions, hasLength(2));
        expect(decisions.map((d) => d.wheelIndex), containsAll([0, 1]));
      });

      test('handles out of bounds wheel indices gracefully', () {
        final dependency = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => values[0],
        );

        final configs = [
          WheelConfig(itemCount: 10, initialIndex: 5, formatter: (i) => i.toString()),
        ];

        dependencyManager.registerDependency(5, dependency); // wheel 5 doesn't exist

        final decisions = recreationLogic.getRecreationDecisionsForChange(
          changedWheelIndex: 1,
          wheelConfigs: configs,
          allSelections: [5, 3],
          dependencyManager: dependencyManager,
        );

        expect(decisions, isEmpty); // Should skip invalid wheel index
      });

      test('handles exceptions gracefully', () {
        final decisions = recreationLogic.getRecreationDecisionsForChange(
          changedWheelIndex: -1, // invalid index
          wheelConfigs: [],
          allSelections: [],
          dependencyManager: dependencyManager,
        );

        expect(decisions, isEmpty);
      });
    });

    group('shouldRecreateWheels', () {
      test('checks all wheels and returns decisions', () {
        final dependency1 = WheelDependency(
          dependsOn: [2],
          calculateItemCount: (values) => values[0] + 10,
        );
        final dependency2 = WheelDependency(
          dependsOn: [2],
          calculateItemCount: (values) => values[0] * 2,
        );

        final configs = [
          WheelConfig(itemCount: 15, initialIndex: 5, formatter: (i) => i.toString()),
          WheelConfig(itemCount: 10, initialIndex: 3, formatter: (i) => i.toString()),
          WheelConfig(itemCount: 5, initialIndex: 2, formatter: (i) => i.toString()),
        ];

        dependencyManager.registerDependency(0, dependency1);
        dependencyManager.registerDependency(1, dependency2);

        final decisions = recreationLogic.shouldRecreateWheels(
          wheelConfigs: configs,
          allSelections: [5, 3, 3],
          dependencyManager: dependencyManager,
        );

        expect(decisions, hasLength(3));
        expect(decisions[0].wheelIndex, equals(0));
        expect(decisions[1].wheelIndex, equals(1));
        expect(decisions[2].wheelIndex, equals(2));

        // Check recreation needs
        expect(decisions[0].needsRecreation, isTrue); // 3 + 10 = 13 != 15
        expect(decisions[1].needsRecreation, isTrue); // 3 * 2 = 6 != 10
        expect(decisions[2].needsRecreation, isFalse); // no dependencies
      });

      test('handles empty wheel list', () {
        final decisions = recreationLogic.shouldRecreateWheels(
          wheelConfigs: [],
          allSelections: [],
          dependencyManager: dependencyManager,
        );

        expect(decisions, isEmpty);
      });

      test('handles exceptions gracefully', () {
        final configs = [
          WheelConfig(itemCount: 10, initialIndex: 5, formatter: (i) => i.toString()),
        ];

        final decisions = recreationLogic.shouldRecreateWheels(
          wheelConfigs: configs,
          allSelections: [], // empty selections will cause issues
          dependencyManager: dependencyManager,
        );

        expect(decisions, hasLength(1));
        expect(decisions[0].needsRecreation, isFalse); // Should handle gracefully
      });
    });

    group('calculateOptimalInitialIndex', () {
      test('preserves current selection when within bounds', () {
        final index = recreationLogic.calculateOptimalInitialIndex(
          currentSelection: 5,
          newItemCount: 10,
        );

        expect(index, equals(5));
      });

      test('clamps to last valid index when out of bounds', () {
        final index = recreationLogic.calculateOptimalInitialIndex(
          currentSelection: 15,
          newItemCount: 10,
        );

        expect(index, equals(9)); // newItemCount - 1
      });

      test('uses dependency calculation when provided', () {
        final dependency = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => values[0],
          calculateInitialIndex: (values, current) => values[0] ~/ 2,
        );

        final index = recreationLogic.calculateOptimalInitialIndex(
          currentSelection: 10,
          newItemCount: 8,
          dependency: dependency,
          dependencyValues: [6],
        );

        expect(index, equals(3)); // 6 / 2
      });

      test('falls back to default when dependency calculation fails', () {
        final dependency = WheelDependency(
          dependsOn: [1],
          calculateItemCount: (values) => values[0],
          calculateInitialIndex: (values, current) => throw Exception('Error'),
        );

        final index = recreationLogic.calculateOptimalInitialIndex(
          currentSelection: 15,
          newItemCount: 10,
          dependency: dependency,
          dependencyValues: [5],
        );

        expect(index, equals(9)); // fallback to newItemCount - 1
      });

      test('handles edge case of zero item count', () {
        final index = recreationLogic.calculateOptimalInitialIndex(
          currentSelection: 5,
          newItemCount: 0,
        );

        expect(index, equals(0)); // safe fallback
      });

      test('handles edge case of single item', () {
        final index = recreationLogic.calculateOptimalInitialIndex(
          currentSelection: 5,
          newItemCount: 1,
        );

        expect(index, equals(0)); // only valid index
      });
    });

    group('validateRecreationDecision', () {
      test('returns true for valid decision without recreation', () {
        final decision = RecreationDecision(
          wheelIndex: 1,
          needsRecreation: false,
          newConfig: null,
          reason: 'No recreation needed',
        );

        expect(recreationLogic.validateRecreationDecision(decision, 3), isTrue);
      });

      test('returns true for valid decision with recreation', () {
        final newConfig = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
        );
        final decision = RecreationDecision(
          wheelIndex: 1,
          needsRecreation: true,
          newConfig: newConfig,
          reason: 'Recreation needed',
        );

        expect(recreationLogic.validateRecreationDecision(decision, 3), isTrue);
      });

      test('returns false for out of bounds wheel index', () {
        final decision = RecreationDecision(
          wheelIndex: 5, // >= currentWheelCount 3
          needsRecreation: false,
          newConfig: null,
          reason: 'Test',
        );

        expect(recreationLogic.validateRecreationDecision(decision, 3), isFalse);
      });

      test('returns false for negative wheel index', () {
        final decision = RecreationDecision(
          wheelIndex: -1,
          needsRecreation: false,
          newConfig: null,
          reason: 'Test',
        );

        expect(recreationLogic.validateRecreationDecision(decision, 3), isFalse);
      });

      test('returns false when recreation needed but no config provided', () {
        final decision = RecreationDecision(
          wheelIndex: 1,
          needsRecreation: true,
          newConfig: null, // missing config
          reason: 'Recreation needed',
        );

        expect(recreationLogic.validateRecreationDecision(decision, 3), isFalse);
      });

      test('returns false when new config is invalid', () {
        final invalidConfig = WheelConfig(
          itemCount: 0, // invalid
          initialIndex: 0,
          formatter: (index) => index.toString(),
        );
        final decision = RecreationDecision(
          wheelIndex: 1,
          needsRecreation: true,
          newConfig: invalidConfig,
          reason: 'Recreation needed',
        );

        expect(recreationLogic.validateRecreationDecision(decision, 3), isFalse);
      });

      test('handles exceptions gracefully', () {
        final decision = RecreationDecision(
          wheelIndex: 1,
          needsRecreation: false,
          newConfig: null,
          reason: 'Test',
        );

        // This should not throw even with edge cases
        expect(recreationLogic.validateRecreationDecision(decision, 0), isFalse);
      });
    });

    group('getRecreationStats', () {
      test('returns correct stats for empty list', () {
        final stats = recreationLogic.getRecreationStats([]);

        expect(stats['totalWheels'], equals(0));
        expect(stats['recreationCount'], equals(0));
        expect(stats['recreationRate'], equals(0.0));
        expect(stats['reasons'], isEmpty);
      });

      test('returns correct stats for mixed decisions', () {
        final decisions = [
          RecreationDecision(
            wheelIndex: 0,
            needsRecreation: true,
            newConfig: WheelConfig(itemCount: 10, initialIndex: 5, formatter: (i) => i.toString()),
            reason: 'Item count changed',
          ),
          RecreationDecision(
            wheelIndex: 1,
            needsRecreation: false,
            newConfig: null,
            reason: 'No dependencies',
          ),
          RecreationDecision(
            wheelIndex: 2,
            needsRecreation: true,
            newConfig: WheelConfig(itemCount: 15, initialIndex: 8, formatter: (i) => i.toString()),
            reason: 'Item count changed',
          ),
          RecreationDecision(
            wheelIndex: 3,
            needsRecreation: false,
            newConfig: null,
            reason: 'Configuration unchanged',
          ),
        ];

        final stats = recreationLogic.getRecreationStats(decisions);

        expect(stats['totalWheels'], equals(4));
        expect(stats['recreationCount'], equals(2));
        expect(stats['recreationRate'], equals(50.0)); // 2/4 * 100
        expect(stats['reasons']['Recreation needed'], equals(2));
        expect(stats['reasons']['No recreation'], equals(2));
      });

      test('returns correct stats for all recreation needed', () {
        final decisions = [
          RecreationDecision(
            wheelIndex: 0,
            needsRecreation: true,
            newConfig: WheelConfig(itemCount: 10, initialIndex: 5, formatter: (i) => i.toString()),
            reason: 'Item count changed',
          ),
          RecreationDecision(
            wheelIndex: 1,
            needsRecreation: true,
            newConfig: WheelConfig(itemCount: 15, initialIndex: 8, formatter: (i) => i.toString()),
            reason: 'Item count changed',
          ),
        ];

        final stats = recreationLogic.getRecreationStats(decisions);

        expect(stats['totalWheels'], equals(2));
        expect(stats['recreationCount'], equals(2));
        expect(stats['recreationRate'], equals(100.0));
        expect(stats['reasons']['Recreation needed'], equals(2));
        expect(stats['reasons']['No recreation'], isNull);
      });

      test('returns correct stats for no recreation needed', () {
        final decisions = [
          RecreationDecision(
            wheelIndex: 0,
            needsRecreation: false,
            newConfig: null,
            reason: 'No dependencies',
          ),
          RecreationDecision(
            wheelIndex: 1,
            needsRecreation: false,
            newConfig: null,
            reason: 'Configuration unchanged',
          ),
        ];

        final stats = recreationLogic.getRecreationStats(decisions);

        expect(stats['totalWheels'], equals(2));
        expect(stats['recreationCount'], equals(0));
        expect(stats['recreationRate'], equals(0.0));
        expect(stats['reasons']['Recreation needed'], isNull);
        expect(stats['reasons']['No recreation'], equals(2));
      });
    });

    group('real-world scenarios', () {
      test('date picker day wheel recreation logic', () {
        final dayDependency = WheelDependency(
          dependsOn: [1, 2], // month, year
          calculateItemCount: (values) {
            final month = values[0] + 1;
            final year = 2000 + values[1];
            return DateTime(year, month + 1, 0).day;
          },
          calculateInitialIndex: (values, current) {
            final month = values[0] + 1;
            final year = 2000 + values[1];
            final maxDays = DateTime(year, month + 1, 0).day;
            return current >= maxDays ? maxDays - 1 : current;
          },
        );

        dependencyManager.registerDependency(0, dayDependency);

        final dayConfig = WheelConfig(
          itemCount: 31, // January
          initialIndex: 30, // 31st
          formatter: (index) => (index + 1).toString(),
        );

        // Switch to February 2024 (leap year)
        final decision = recreationLogic.shouldRecreateWheel(
          wheelIndex: 0,
          currentConfig: dayConfig,
          allSelections: [30, 1, 24], // day=31, month=Feb, year=2024
          dependencyManager: dependencyManager,
        );

        expect(decision.needsRecreation, isTrue);
        expect(decision.newConfig!.itemCount, equals(29)); // February 2024 has 29 days
        expect(decision.newConfig!.initialIndex, equals(28)); // Clamped to Feb 29th (index 28)
      });

      test('time picker hour format change logic', () {
        final hourDependency = WheelDependency(
          dependsOn: [3], // format wheel (12/24 hour)
          calculateItemCount: (values) => values[0] == 0 ? 12 : 24,
          calculateInitialIndex: (values, current) {
            if (values[0] == 0) {
              // 24 to 12 hour: convert 0-23 to 0-11
              return current >= 12 ? current - 12 : current;
            } else {
              // 12 to 24 hour: keep as is
              return current;
            }
          },
        );

        dependencyManager.registerDependency(0, hourDependency);

        final hourConfig = WheelConfig(
          itemCount: 24, // 24-hour format
          initialIndex: 15, // 3 PM
          formatter: (index) => index.toString(),
        );

        // Switch to 12-hour format
        final decision = recreationLogic.shouldRecreateWheel(
          wheelIndex: 0,
          currentConfig: hourConfig,
          allSelections: [15, 30, 0, 0], // hour=15, minute=30, second=0, format=12h
          dependencyManager: dependencyManager,
        );

        expect(decision.needsRecreation, isTrue);
        expect(decision.newConfig!.itemCount, equals(12));
        expect(decision.newConfig!.initialIndex, equals(3)); // 15 - 12 = 3 (3 PM in 12h format)
      });

      test('cascading country-state-city dependencies', () {
        final stateDependency = WheelDependency(
          dependsOn: [0], // country
          calculateItemCount: (values) => values[0] == 0 ? 50 : 10, // USA: 50 states, others: 10 regions
        );
        final cityDependency = WheelDependency(
          dependsOn: [1], // state
          calculateItemCount: (values) => values[0] * 5 + 10, // 5 cities per state + 10 base
        );

        dependencyManager.registerDependency(1, stateDependency);
        dependencyManager.registerDependency(2, cityDependency);

        final configs = [
          WheelConfig(itemCount: 5, initialIndex: 0, formatter: (i) => 'Country $i'), // country
          WheelConfig(itemCount: 50, initialIndex: 25, formatter: (i) => 'State $i'), // state
          WheelConfig(itemCount: 135, initialIndex: 67, formatter: (i) => 'City $i'), // city
        ];

        // Change country from USA (0) to Canada (1)
        final decisions = recreationLogic.getRecreationDecisionsForChange(
          changedWheelIndex: 0,
          wheelConfigs: configs,
          allSelections: [1, 25, 67], // country=Canada, state=25, city=67
          dependencyManager: dependencyManager,
        );

        expect(decisions, hasLength(1)); // Only state wheel depends on country
        expect(decisions[0].wheelIndex, equals(1));
        expect(decisions[0].needsRecreation, isTrue);
        expect(decisions[0].newConfig!.itemCount, equals(10)); // Canada has 10 regions

        // Now check city wheel after state change
        final cityDecisions = recreationLogic.getRecreationDecisionsForChange(
          changedWheelIndex: 1,
          wheelConfigs: [
            configs[0],
            decisions[0].newConfig!, // updated state config
            configs[2],
          ],
          allSelections: [1, 9, 67], // country=Canada, state=9 (clamped), city=67
          dependencyManager: dependencyManager,
        );

        expect(cityDecisions, hasLength(1));
        expect(cityDecisions[0].wheelIndex, equals(2));
        expect(cityDecisions[0].needsRecreation, isTrue);
        expect(cityDecisions[0].newConfig!.itemCount, equals(55)); // 9 * 5 + 10
      });
    });

    group('performance and edge cases', () {
      test('handles large number of wheels efficiently', () {
        final configs = List.generate(100, (i) => WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
        ));

        final selections = List.generate(100, (i) => 5);

        final stopwatch = Stopwatch()..start();
        final decisions = recreationLogic.shouldRecreateWheels(
          wheelConfigs: configs,
          allSelections: selections,
          dependencyManager: dependencyManager,
        );
        stopwatch.stop();

        expect(decisions, hasLength(100));
        expect(decisions.every((d) => !d.needsRecreation), isTrue); // No dependencies
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be fast
      });

      test('handles complex dependency chains efficiently', () {
        // Create a chain: 0->1->2->3->4
        for (int i = 0; i < 4; i++) {
          final dependency = WheelDependency(
            dependsOn: [i + 1],
            calculateItemCount: (values) => values[0] + 1,
          );
          dependencyManager.registerDependency(i, dependency);
        }

        final configs = List.generate(5, (i) => WheelConfig(
          itemCount: 10 + i,
          initialIndex: 5,
          formatter: (index) => index.toString(),
        ));

        // Change the root wheel (4)
        final stopwatch = Stopwatch()..start();
        final decisions = recreationLogic.getRecreationDecisionsForChange(
          changedWheelIndex: 4,
          wheelConfigs: configs,
          allSelections: [5, 5, 5, 5, 8], // changed wheel 4 from 5 to 8
          dependencyManager: dependencyManager,
        );
        stopwatch.stop();

        expect(decisions, hasLength(4)); // All dependent wheels
        expect(decisions.every((d) => d.needsRecreation), isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(50)); // Should be efficient
      });

      test('handles malformed selections arrays gracefully', () {
        final dependency = WheelDependency(
          dependsOn: [1, 2],
          calculateItemCount: (values) => values[0] + values[1],
        );
        final config = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
        );

        dependencyManager.registerDependency(0, dependency);

        // Too few selections
        final decision1 = recreationLogic.shouldRecreateWheel(
          wheelIndex: 0,
          currentConfig: config,
          allSelections: [5], // missing selections for indices 1, 2
          dependencyManager: dependencyManager,
        );

        expect(decision1.needsRecreation, isFalse);
        expect(decision1.reason, contains('Failed to calculate'));

        // Empty selections
        final decision2 = recreationLogic.shouldRecreateWheel(
          wheelIndex: 0,
          currentConfig: config,
          allSelections: [],
          dependencyManager: dependencyManager,
        );

        expect(decision2.needsRecreation, isFalse);
      });
    });
  });
}