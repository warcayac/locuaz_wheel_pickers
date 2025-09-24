import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locuaz_wheel_pickers/src/models/wheel_state.dart';
import 'package:locuaz_wheel_pickers/src/models/wheel_config.dart';
import 'package:locuaz_wheel_pickers/src/models/wheel_dependency.dart';

void main() {
  group('WheelState', () {
    late WheelConfig testConfig;
    late FixedExtentScrollController testController;

    setUp(() {
      testConfig = WheelConfig(
        itemCount: 10,
        initialIndex: 5,
        formatter: (index) => index.toString(),
        wheelId: 'test_wheel',
      );
      testController = FixedExtentScrollController(initialItem: 5);
    });

    tearDown(() {
      testController.dispose();
    });

    group('constructor', () {
      test('creates state with all required parameters', () {
        final state = WheelState(
          wheelId: 'wheel_1',
          selectedIndex: 3,
          controller: testController,
          config: testConfig,
        );

        expect(state.wheelId, equals('wheel_1'));
        expect(state.selectedIndex, equals(3));
        expect(state.controller, equals(testController));
        expect(state.config, equals(testConfig));
        expect(state.needsRecreation, isFalse); // default value
      });

      test('creates state with needsRecreation flag', () {
        final state = WheelState(
          wheelId: 'wheel_1',
          selectedIndex: 3,
          controller: testController,
          config: testConfig,
          needsRecreation: true,
        );

        expect(state.needsRecreation, isTrue);
      });
    });

    group('fromConfig factory', () {
      test('creates state from config with defaults', () {
        final state = WheelState.fromConfig(testConfig);

        expect(state.wheelId, equals('test_wheel')); // from config
        expect(state.selectedIndex, equals(5)); // from config.initialIndex
        expect(state.controller, isNotNull);
        expect(state.controller.initialItem, equals(5));
        expect(state.config, equals(testConfig));
        expect(state.needsRecreation, isFalse);
      });

      test('creates state with custom wheelId', () {
        final state = WheelState.fromConfig(testConfig, wheelId: 'custom_wheel');

        expect(state.wheelId, equals('custom_wheel'));
        expect(state.selectedIndex, equals(5));
        expect(state.config, equals(testConfig));
      });

      test('creates state with custom selectedIndex', () {
        final state = WheelState.fromConfig(testConfig, selectedIndex: 8);

        expect(state.wheelId, equals('test_wheel'));
        expect(state.selectedIndex, equals(8));
        expect(state.controller.initialItem, equals(8));
      });

      test('creates state with custom controller', () {
        final customController = FixedExtentScrollController(initialItem: 3);
        final state = WheelState.fromConfig(testConfig, controller: customController);

        expect(state.controller, equals(customController));
        expect(state.selectedIndex, equals(5)); // still from config
        
        customController.dispose();
      });

      test('generates unique wheelId when config has no wheelId', () {
        final configWithoutId = WheelConfig(
          itemCount: 5,
          initialIndex: 2,
          formatter: (index) => index.toString(),
        );

        final state1 = WheelState.fromConfig(configWithoutId);
        final state2 = WheelState.fromConfig(configWithoutId);

        expect(state1.wheelId, isNotEmpty);
        expect(state2.wheelId, isNotEmpty);
        expect(state1.wheelId, isNot(equals(state2.wheelId)));
        expect(state1.wheelId, startsWith('wheel_'));
        expect(state2.wheelId, startsWith('wheel_'));
      });
    });

    group('withNewConfig factory', () {
      late WheelState currentState;

      setUp(() {
        currentState = WheelState(
          wheelId: 'existing_wheel',
          selectedIndex: 7,
          controller: testController,
          config: testConfig,
        );
      });

      test('creates new state without recreation when configs are compatible', () {
        final newConfig = testConfig.copyWith(
          formatter: (index) => 'Item $index', // non-recreation change
        );

        final newState = WheelState.withNewConfig(currentState, newConfig);

        expect(newState.wheelId, equals('existing_wheel'));
        expect(newState.selectedIndex, equals(7)); // preserved
        expect(newState.controller, equals(testController)); // same controller
        expect(newState.config, equals(newConfig));
        expect(newState.needsRecreation, isFalse);
      });

      test('creates new state with recreation when configs require it', () {
        final newConfig = testConfig.copyWith(
          itemCount: 15, // recreation-triggering change
        );

        final newState = WheelState.withNewConfig(currentState, newConfig);

        expect(newState.wheelId, equals('existing_wheel'));
        expect(newState.selectedIndex, equals(7)); // preserved and within bounds
        expect(newState.controller, isNot(equals(testController))); // new controller
        expect(newState.controller.initialItem, equals(7));
        expect(newState.config, equals(newConfig));
        expect(newState.needsRecreation, isTrue);
      });

      test('clamps selection when preserving and new itemCount is smaller', () {
        final newConfig = testConfig.copyWith(
          itemCount: 5, // smaller than current selection (7)
        );

        final newState = WheelState.withNewConfig(currentState, newConfig);

        expect(newState.selectedIndex, equals(4)); // clamped to itemCount - 1
        expect(newState.controller.initialItem, equals(4));
        expect(newState.needsRecreation, isTrue);
      });

      test('uses new config initialIndex when not preserving selection', () {
        final newConfig = testConfig.copyWith(
          itemCount: 15,
          initialIndex: 2,
        );

        final newState = WheelState.withNewConfig(
          currentState, 
          newConfig, 
          preserveSelection: false,
        );

        expect(newState.selectedIndex, equals(2)); // from newConfig.initialIndex
        expect(newState.controller.initialItem, equals(2));
        expect(newState.needsRecreation, isTrue);
      });

      test('preserves selection when no recreation needed', () {
        final newConfig = testConfig.copyWith(
          width: 100, // non-recreation change
        );

        final newState = WheelState.withNewConfig(
          currentState, 
          newConfig, 
          preserveSelection: false, // should be ignored
        );

        expect(newState.selectedIndex, equals(7)); // preserved despite flag
        expect(newState.needsRecreation, isFalse);
      });
    });

    group('isValid', () {
      test('returns true for valid state', () {
        final state = WheelState(
          wheelId: 'valid_wheel',
          selectedIndex: 5,
          controller: testController,
          config: testConfig,
        );

        expect(state.isValid(), isTrue);
      });

      test('returns false when config is invalid', () {
        final invalidConfig = WheelConfig(
          itemCount: 0, // invalid
          initialIndex: 0,
          formatter: (index) => index.toString(),
        );
        final state = WheelState(
          wheelId: 'wheel',
          selectedIndex: 0,
          controller: testController,
          config: invalidConfig,
        );

        expect(state.isValid(), isFalse);
      });

      test('returns false when selectedIndex is negative', () {
        final state = WheelState(
          wheelId: 'wheel',
          selectedIndex: -1,
          controller: testController,
          config: testConfig,
        );

        expect(state.isValid(), isFalse);
      });

      test('returns false when selectedIndex is out of bounds', () {
        final state = WheelState(
          wheelId: 'wheel',
          selectedIndex: 10, // itemCount is 10, so max valid index is 9
          controller: testController,
          config: testConfig,
        );

        expect(state.isValid(), isFalse);
      });

      test('returns false when wheelId is empty', () {
        final state = WheelState(
          wheelId: '',
          selectedIndex: 5,
          controller: testController,
          config: testConfig,
        );

        expect(state.isValid(), isFalse);
      });
    });

    group('isConsistentWith', () {
      late WheelState baseState;

      setUp(() {
        baseState = WheelState(
          wheelId: 'consistent_wheel',
          selectedIndex: 3,
          controller: testController,
          config: testConfig,
        );
      });

      test('returns true for identical states', () {
        final otherState = WheelState(
          wheelId: 'consistent_wheel',
          selectedIndex: 3,
          controller: FixedExtentScrollController(initialItem: 0), // different controller
          config: testConfig,
        );

        expect(baseState.isConsistentWith(otherState), isTrue);
        
        otherState.controller.dispose();
      });

      test('returns false when wheelId differs', () {
        final otherState = WheelState(
          wheelId: 'different_wheel',
          selectedIndex: 3,
          controller: testController,
          config: testConfig,
        );

        expect(baseState.isConsistentWith(otherState), isFalse);
      });

      test('returns false when selectedIndex differs', () {
        final otherState = WheelState(
          wheelId: 'consistent_wheel',
          selectedIndex: 7,
          controller: testController,
          config: testConfig,
        );

        expect(baseState.isConsistentWith(otherState), isFalse);
      });

      test('returns false when itemCount differs', () {
        final differentConfig = testConfig.copyWith(itemCount: 15);
        final otherState = WheelState(
          wheelId: 'consistent_wheel',
          selectedIndex: 3,
          controller: testController,
          config: differentConfig,
        );

        expect(baseState.isConsistentWith(otherState), isFalse);
      });
    });

    group('copyWith', () {
      late WheelState originalState;

      setUp(() {
        originalState = WheelState(
          wheelId: 'original_wheel',
          selectedIndex: 4,
          controller: testController,
          config: testConfig,
          needsRecreation: false,
        );
      });

      test('creates copy with updated wheelId', () {
        final newState = originalState.copyWith(wheelId: 'new_wheel');

        expect(newState.wheelId, equals('new_wheel'));
        expect(newState.selectedIndex, equals(4));
        expect(newState.controller, equals(testController));
        expect(newState.config, equals(testConfig));
        expect(newState.needsRecreation, isFalse);
      });

      test('creates copy with updated selectedIndex', () {
        final newState = originalState.copyWith(selectedIndex: 8);

        expect(newState.wheelId, equals('original_wheel'));
        expect(newState.selectedIndex, equals(8));
        expect(newState.controller, equals(testController));
        expect(newState.config, equals(testConfig));
        expect(newState.needsRecreation, isFalse);
      });

      test('creates copy with updated controller', () {
        final newController = FixedExtentScrollController(initialItem: 2);
        final newState = originalState.copyWith(controller: newController);

        expect(newState.wheelId, equals('original_wheel'));
        expect(newState.selectedIndex, equals(4));
        expect(newState.controller, equals(newController));
        expect(newState.config, equals(testConfig));
        expect(newState.needsRecreation, isFalse);
        
        newController.dispose();
      });

      test('creates copy with updated config', () {
        final newConfig = testConfig.copyWith(itemCount: 20);
        final newState = originalState.copyWith(config: newConfig);

        expect(newState.wheelId, equals('original_wheel'));
        expect(newState.selectedIndex, equals(4));
        expect(newState.controller, equals(testController));
        expect(newState.config, equals(newConfig));
        expect(newState.needsRecreation, isFalse);
      });

      test('creates copy with updated needsRecreation', () {
        final newState = originalState.copyWith(needsRecreation: true);

        expect(newState.wheelId, equals('original_wheel'));
        expect(newState.selectedIndex, equals(4));
        expect(newState.controller, equals(testController));
        expect(newState.config, equals(testConfig));
        expect(newState.needsRecreation, isTrue);
      });

      test('creates copy with multiple updated properties', () {
        final newController = FixedExtentScrollController(initialItem: 1);
        final newConfig = testConfig.copyWith(itemCount: 25);
        
        final newState = originalState.copyWith(
          wheelId: 'multi_update_wheel',
          selectedIndex: 12,
          controller: newController,
          config: newConfig,
          needsRecreation: true,
        );

        expect(newState.wheelId, equals('multi_update_wheel'));
        expect(newState.selectedIndex, equals(12));
        expect(newState.controller, equals(newController));
        expect(newState.config, equals(newConfig));
        expect(newState.needsRecreation, isTrue);
        
        newController.dispose();
      });

      test('preserves all properties when no parameters provided', () {
        final newState = originalState.copyWith();

        expect(newState.wheelId, equals(originalState.wheelId));
        expect(newState.selectedIndex, equals(originalState.selectedIndex));
        expect(newState.controller, equals(originalState.controller));
        expect(newState.config, equals(originalState.config));
        expect(newState.needsRecreation, equals(originalState.needsRecreation));
      });
    });

    group('disposeIfNeeded', () {
      test('disposes controller when needsRecreation is true', () {
        final controller = FixedExtentScrollController(initialItem: 0);
        final state = WheelState(
          wheelId: 'dispose_wheel',
          selectedIndex: 0,
          controller: controller,
          config: testConfig,
          needsRecreation: true,
        );

        // Controller should be usable before disposal
        expect(() => controller.initialItem, returnsNormally);

        state.disposeIfNeeded();

        // Controller should be disposed after calling disposeIfNeeded
        expect(() => controller.initialItem, throwsA(isA<AssertionError>()));
      });

      test('does not dispose controller when needsRecreation is false', () {
        final controller = FixedExtentScrollController(initialItem: 0);
        final state = WheelState(
          wheelId: 'no_dispose_wheel',
          selectedIndex: 0,
          controller: controller,
          config: testConfig,
          needsRecreation: false,
        );

        state.disposeIfNeeded();

        // Controller should still be usable
        expect(() => controller.initialItem, returnsNormally);
        expect(controller.initialItem, equals(0));
        
        controller.dispose();
      });
    });

    group('equality and hashCode', () {
      test('states with same properties are equal', () {
        final state1 = WheelState(
          wheelId: 'equal_wheel',
          selectedIndex: 5,
          controller: testController,
          config: testConfig,
          needsRecreation: false,
        );
        
        final state2 = WheelState(
          wheelId: 'equal_wheel',
          selectedIndex: 5,
          controller: FixedExtentScrollController(initialItem: 0), // different controller
          config: testConfig,
          needsRecreation: false,
        );

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
        
        state2.controller.dispose();
      });

      test('states with different properties are not equal', () {
        final state1 = WheelState(
          wheelId: 'wheel1',
          selectedIndex: 5,
          controller: testController,
          config: testConfig,
        );
        
        final state2 = WheelState(
          wheelId: 'wheel2',
          selectedIndex: 5,
          controller: testController,
          config: testConfig,
        );

        expect(state1, isNot(equals(state2)));
        expect(state1.hashCode, isNot(equals(state2.hashCode)));
      });

      test('identical states are equal', () {
        final state = WheelState(
          wheelId: 'identical_wheel',
          selectedIndex: 5,
          controller: testController,
          config: testConfig,
        );

        expect(state, equals(state));
        expect(state.hashCode, equals(state.hashCode));
      });
    });

    group('toString', () {
      test('provides meaningful string representation', () {
        final state = WheelState(
          wheelId: 'string_wheel',
          selectedIndex: 7,
          controller: testController,
          config: testConfig,
          needsRecreation: true,
        );

        final stringRep = state.toString();

        expect(stringRep, contains('string_wheel'));
        expect(stringRep, contains('7'));
        expect(stringRep, contains('true'));
        expect(stringRep, startsWith('WheelState('));
        expect(stringRep, endsWith(')'));
      });
    });

    group('real-world scenarios', () {
      test('handles date picker day wheel state correctly', () {
        final dayConfig = WheelConfig(
          itemCount: 31,
          initialIndex: 14, // 15th day
          formatter: (index) => (index + 1).toString(),
          wheelId: 'day_wheel',
        );

        final dayState = WheelState.fromConfig(dayConfig);

        expect(dayState.wheelId, equals('day_wheel'));
        expect(dayState.selectedIndex, equals(14));
        expect(dayState.config.itemCount, equals(31));
        expect(dayState.isValid(), isTrue);

        // Simulate month change to February (28 days)
        final febConfig = dayConfig.copyWith(itemCount: 28);
        final newDayState = WheelState.withNewConfig(dayState, febConfig);

        expect(newDayState.selectedIndex, equals(14)); // still valid
        expect(newDayState.needsRecreation, isTrue);
        expect(newDayState.isValid(), isTrue);
      });

      test('handles time picker hour wheel state correctly', () {
        final hour12Config = WheelConfig(
          itemCount: 12,
          initialIndex: 9, // 10 AM
          formatter: (index) => (index + 1).toString(),
          wheelId: 'hour_wheel',
        );

        final hourState = WheelState.fromConfig(hour12Config);

        // Switch to 24-hour format
        final hour24Config = hour12Config.copyWith(itemCount: 24);
        final newHourState = WheelState.withNewConfig(hourState, hour24Config);

        expect(newHourState.selectedIndex, equals(9)); // preserved
        expect(newHourState.needsRecreation, isTrue);
        expect(newHourState.config.itemCount, equals(24));
      });

      test('handles cascading dependency state updates', () {
        final dependency = WheelDependency(
          dependsOn: [0], // depends on country wheel
          calculateItemCount: (values) => values[0] == 0 ? 50 : 10, // USA: 50 states, others: 10 regions
        );

        final stateConfig = WheelConfig(
          itemCount: 50, // initially USA
          initialIndex: 25, // California
          formatter: (index) => 'State $index',
          wheelId: 'state_wheel',
          dependency: dependency,
        );

        final stateState = WheelState.fromConfig(stateConfig);

        // Switch country (triggers dependency recalculation)
        final newStateConfig = stateConfig.copyWith(itemCount: 10); // other country
        final newStateState = WheelState.withNewConfig(stateState, newStateConfig);

        expect(newStateState.selectedIndex, equals(9)); // clamped to new max
        expect(newStateState.needsRecreation, isTrue);
        expect(newStateState.config.itemCount, equals(10));
      });
    });

    group('edge cases', () {
      test('handles minimum valid configuration', () {
        final minConfig = WheelConfig(
          itemCount: 1,
          initialIndex: 0,
          formatter: (index) => '',
        );

        final state = WheelState.fromConfig(minConfig);

        expect(state.isValid(), isTrue);
        expect(state.selectedIndex, equals(0));
        expect(state.config.itemCount, equals(1));
      });

      test('handles large item counts', () {
        final largeConfig = WheelConfig(
          itemCount: 10000,
          initialIndex: 5000,
          formatter: (index) => index.toString(),
        );

        final state = WheelState.fromConfig(largeConfig);

        expect(state.isValid(), isTrue);
        expect(state.selectedIndex, equals(5000));
        expect(state.config.itemCount, equals(10000));
      });

      test('handles state with complex dependency', () {
        final complexDependency = WheelDependency(
          dependsOn: [0, 1, 2],
          calculateItemCount: (values) => values[0] * values[1] + values[2],
          calculateInitialIndex: (values, current) => (values[0] + values[1] + values[2]) % current,
        );

        final complexConfig = WheelConfig(
          itemCount: 100,
          initialIndex: 50,
          formatter: (index) => 'Complex $index',
          dependency: complexDependency,
        );

        final state = WheelState.fromConfig(complexConfig);

        expect(state.isValid(), isTrue);
        expect(state.config.dependency, equals(complexDependency));
      });
    });
  });
}