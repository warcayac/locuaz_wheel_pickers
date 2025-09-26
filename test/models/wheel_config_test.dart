import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locuaz_wheel_pickers/src/models/wheel_config.dart';
import 'package:locuaz_wheel_pickers/src/models/wheel_dependency.dart';

void main() {
  group('WheelConfig', () {
    group('constructor', () {
      test('creates valid config with required parameters', () {
        final config = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
        );

        expect(config.itemCount, equals(10));
        expect(config.initialIndex, equals(5));
        expect(config.formatter(5), equals('5'));
        expect(config.width, equals(70)); // default value
        expect(config.onChanged, isNull);
        expect(config.leadingSeparator, isNull);
        expect(config.trailingSeparator, isNull);
        expect(config.wheelId, isNull);
        expect(config.dependency, isNull);
      });

      test('creates config with all optional parameters', () {
        final onChangedCallback = (int index) {};
        const leadingSeparator = Text('|');
        const trailingSeparator = Text(':');
        final dependency = WheelDependency(
          dependsOn: [0],
          calculateItemCount: (values) => values[0] + 1,
        );

        final config = WheelConfig(
          itemCount: 24,
          initialIndex: 12,
          formatter: (index) => index.toString().padLeft(2, '0'),
          width: 80,
          onChanged: onChangedCallback,
          leadingSeparator: leadingSeparator,
          trailingSeparator: trailingSeparator,
          wheelId: 'test_wheel',
          dependency: dependency,
        );

        expect(config.itemCount, equals(24));
        expect(config.initialIndex, equals(12));
        expect(config.formatter(5), equals('05'));
        expect(config.width, equals(80));
        expect(config.onChanged, equals(onChangedCallback));
        expect(config.leadingSeparator, equals(leadingSeparator));
        expect(config.trailingSeparator, equals(trailingSeparator));
        expect(config.wheelId, equals('test_wheel'));
        expect(config.dependency, equals(dependency));
      });

      test('defaults initialIndex to 0 when omitted', () {
        final config = WheelConfig(
          itemCount: 10,
          formatter: (index) => index.toString(),
        );

        expect(config.initialIndex, equals(0));
        expect(config.isValid(), isTrue);
      });
    });

    group('needsRecreation', () {
      test('returns false when configs are identical', () {
        final config1 = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
          wheelId: 'test',
        );
        final config2 = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
          wheelId: 'test',
        );

        expect(config1.needsRecreation(config2), isFalse);
      });

      test('returns true when itemCount differs', () {
        final config1 = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
        );
        final config2 = WheelConfig(
          itemCount: 11,
          initialIndex: 5,
          formatter: (index) => index.toString(),
        );

        expect(config1.needsRecreation(config2), isTrue);
      });

      test('returns true when wheelId differs', () {
        final config1 = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
          wheelId: 'wheel1',
        );
        final config2 = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
          wheelId: 'wheel2',
        );

        expect(config1.needsRecreation(config2), isTrue);
      });

      test('returns false when only non-recreation properties differ', () {
        final config1 = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
          width: 70,
        );
        final config2 = WheelConfig(
          itemCount: 10,
          initialIndex: 3, // different initialIndex
          formatter: (index) => 'Item $index', // different formatter
          width: 80, // different width
        );

        expect(config1.needsRecreation(config2), isFalse);
      });

      test('does not require recreation when comparing default vs explicit initialIndex: 0', () {
        final configDefault = WheelConfig(
          itemCount: 10,
          formatter: (index) => index.toString(),
          wheelId: 'same',
        );
        final configExplicitZero = WheelConfig(
          itemCount: 10,
          initialIndex: 0,
          formatter: (index) => index.toString(),
          wheelId: 'same',
        );

        // initialIndex intentionally excluded from recreation triggers
        expect(configDefault.needsRecreation(configExplicitZero), isFalse);
        expect(configExplicitZero.needsRecreation(configDefault), isFalse);
      });

      test('handles dependency-based recreation correctly', () {
        final dependency = WheelDependency(
          dependsOn: [0],
          calculateItemCount: (values) => values[0] + 10,
        );
        final config = WheelConfig(
          itemCount: 15,
          initialIndex: 0,
          formatter: (index) => index.toString(),
          dependency: dependency,
        );

        // Same calculated item count (5 + 10 = 15)
        expect(config.needsRecreation(config, currentDependencyValues: [5]), isFalse);

        // Different calculated item count (8 + 10 = 18)
        expect(config.needsRecreation(config, currentDependencyValues: [8]), isTrue);
      });

      test('handles compact dependency values correctly', () {
        final dependency = WheelDependency(
          dependsOn: [1, 3],
          calculateItemCount: (values) => values[0] + values[1],
        );
        final config = WheelConfig(
          itemCount: 10,
          initialIndex: 0,
          formatter: (index) => index.toString(),
          dependency: dependency,
        );

        // Compact values matching dependency length
        expect(config.needsRecreation(config, currentDependencyValues: [4, 6]), isFalse);
        expect(config.needsRecreation(config, currentDependencyValues: [5, 6]), isTrue);
      });

      test('handles full selection array correctly', () {
        final dependency = WheelDependency(
          dependsOn: [1, 3],
          calculateItemCount: (values) => values[0] + values[1],
        );
        final config = WheelConfig(
          itemCount: 10,
          initialIndex: 0,
          formatter: (index) => index.toString(),
          dependency: dependency,
        );

        // Full selection array [0, 4, 2, 6, 8]
        // Should extract indices 1 and 3: [4, 6] -> 4 + 6 = 10
        expect(config.needsRecreation(config, currentDependencyValues: [0, 4, 2, 6, 8]), isFalse);

        // Full selection array [0, 5, 2, 6, 8]
        // Should extract indices 1 and 3: [5, 6] -> 5 + 6 = 11
        expect(config.needsRecreation(config, currentDependencyValues: [0, 5, 2, 6, 8]), isTrue);
      });

      test('returns true when dependency index is out of bounds', () {
        final dependency = WheelDependency(
          dependsOn: [5], // Index 5 doesn't exist in array of length 3
          calculateItemCount: (values) => values[0],
        );
        final config = WheelConfig(
          itemCount: 10,
          initialIndex: 0,
          formatter: (index) => index.toString(),
          dependency: dependency,
        );

        expect(config.needsRecreation(config, currentDependencyValues: [0, 1, 2]), isTrue);
      });
    });

    group('isValid', () {
      test('returns true for valid basic config', () {
        final config = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
        );

        expect(config.isValid(), isTrue);
      });

      test('returns false when itemCount is zero or negative', () {
        final config1 = WheelConfig(
          itemCount: 0,
          initialIndex: 0,
          formatter: (index) => index.toString(),
        );
        final config2 = WheelConfig(
          itemCount: -1,
          initialIndex: 0,
          formatter: (index) => index.toString(),
        );

        expect(config1.isValid(), isFalse);
        expect(config2.isValid(), isFalse);
      });

      test('returns false when initialIndex is out of bounds', () {
        final config1 = WheelConfig(
          itemCount: 10,
          initialIndex: -1,
          formatter: (index) => index.toString(),
        );
        final config2 = WheelConfig(
          itemCount: 10,
          initialIndex: 10,
          formatter: (index) => index.toString(),
        );

        expect(config1.isValid(), isFalse);
        expect(config2.isValid(), isFalse);
      });

      test('returns false when width is zero or negative', () {
        final config1 = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
          width: 0,
        );
        final config2 = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
          width: -10,
        );

        expect(config1.isValid(), isFalse);
        expect(config2.isValid(), isFalse);
      });

      test('validates dependency when present', () {
        final validDependency = WheelDependency(
          dependsOn: [0, 1],
          calculateItemCount: (values) => values[0] + values[1],
        );
        final invalidDependency = WheelDependency(
          dependsOn: [], // empty dependsOn
          calculateItemCount: (values) => 10,
        );

        final validConfig = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
          dependency: validDependency,
        );
        final invalidConfig = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
          dependency: invalidDependency,
        );

        expect(validConfig.isValid(totalWheelCount: 5), isTrue);
        expect(invalidConfig.isValid(totalWheelCount: 5), isFalse);
      });

      test('detects self-dependency', () {
        final selfDependency = WheelDependency(
          dependsOn: [2], // wheel depends on itself
          calculateItemCount: (values) => values[0],
        );
        final config = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
          dependency: selfDependency,
        );

        expect(config.isValid(wheelIndex: 2), isFalse);
        expect(config.isValid(wheelIndex: 1), isTrue);
      });

      test('isValid works when initialIndex is omitted (defaults to 0)', () {
        final config = WheelConfig(
          itemCount: 3,
          formatter: (index) => index.toString(),
        );
        expect(config.isValid(), isTrue);
      });
    });

    group('createFromDependency', () {
      test('returns null when no dependency exists', () {
        final config = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
        );

        expect(config.createFromDependency([1, 2], 3), isNull);
      });

      test('creates new config with calculated values', () {
        final dependency = WheelDependency(
          dependsOn: [0, 1],
          calculateItemCount: (values) => values[0] + values[1] + 10,
          calculateInitialIndex: (values, current) => current.clamp(0, values[0] + values[1] + 9),
        );
        final config = WheelConfig(
          itemCount: 15,
          initialIndex: 5,
          formatter: (index) => index.toString(),
          dependency: dependency,
        );

        final newConfig = config.createFromDependency([3, 7], 12);

        expect(newConfig, isNotNull);
        expect(newConfig!.itemCount, equals(20)); // 3 + 7 + 10
        expect(newConfig.initialIndex, equals(12)); // within bounds
        expect(newConfig.formatter(5), equals('5'));
        expect(newConfig.dependency, equals(dependency));
      });

      test('createFromDependency works when initialIndex is omitted (defaults to 0)', () {
        final dependency = WheelDependency(
          dependsOn: [0, 1],
          calculateItemCount: (values) => values[0] + values[1] + 5,
          calculateInitialIndex: (values, current) => current.clamp(0, values[0] + values[1] + 4),
        );
        // Omit initialIndex to use default 0
        final config = WheelConfig(
          itemCount: 10,
          formatter: (index) => index.toString(),
          dependency: dependency,
        );

        // Use a current selection that is in range for the calculated item count
        final newConfig = config.createFromDependency([2, 3], 4);

        expect(newConfig, isNotNull);
        expect(newConfig!.itemCount, equals(10)); // 2 + 3 + 5
        expect(newConfig.initialIndex, equals(4)); // clamped current selection preserved
        expect(newConfig.formatter(1), equals('1'));
        expect(newConfig.dependency, equals(dependency));
      });

      test('returns null when calculation fails', () {
        final dependency = WheelDependency(
          dependsOn: [0],
          calculateItemCount: (values) => throw Exception('Calculation error'),
        );
        final config = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
          dependency: dependency,
        );

        expect(config.createFromDependency([5], 3), isNull);
      });
    });

    group('copyWith', () {
      test('creates copy with updated values', () {
        final originalConfig = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
          width: 70,
          wheelId: 'original',
        );

        final updatedConfig = originalConfig.copyWith(
          itemCount: 15,
          wheelId: 'updated',
        );

        expect(updatedConfig.itemCount, equals(15));
        expect(updatedConfig.wheelId, equals('updated'));
        expect(updatedConfig.initialIndex, equals(5)); // unchanged
        expect(updatedConfig.width, equals(70)); // unchanged
        expect(updatedConfig.formatter(5), equals('5')); // unchanged
      });

      test('preserves all values when no parameters provided', () {
        final originalConfig = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
          width: 80,
          wheelId: 'test',
        );

        final copiedConfig = originalConfig.copyWith();

        expect(copiedConfig.itemCount, equals(originalConfig.itemCount));
        expect(copiedConfig.initialIndex, equals(originalConfig.initialIndex));
        expect(copiedConfig.width, equals(originalConfig.width));
        expect(copiedConfig.wheelId, equals(originalConfig.wheelId));
      });

      test('preserves default initialIndex (0) when omitted and via copyWith', () {
        final original = WheelConfig(
          itemCount: 3,
          formatter: (i) => '$i',
        );
        // Assert default is 0
        expect(original.initialIndex, equals(0));

        // copyWith without changing initialIndex should keep default 0
        final copied = original.copyWith(width: 90);
        expect(copied.initialIndex, equals(0));
        expect(copied.width, equals(90));
      });
    });

    group('equality and hashCode', () {
      test('configs with same core properties are equal', () {
        final config1 = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
          width: 70,
          wheelId: 'test',
        );
        final config2 = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => 'different formatter', // different formatter
          width: 70,
          wheelId: 'test',
        );

        expect(config1, equals(config2));
        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('configs with different core properties are not equal', () {
        final config1 = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
          wheelId: 'test1',
        );
        final config2 = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
          wheelId: 'test2',
        );

        expect(config1, isNot(equals(config2)));
        expect(config1.hashCode, isNot(equals(config2.hashCode)));
      });

      test('identical configs are equal', () {
        final config = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
        );

        expect(config, equals(config));
        expect(config.hashCode, equals(config.hashCode));
      });

      test('configs with default initialIndex equal explicit initialIndex: 0', () {
        final a = WheelConfig(
          itemCount: 7,
          formatter: (i) => '$i',
        );
        final b = WheelConfig(
          itemCount: 7,
          initialIndex: 0,
          formatter: (i) => '$i',
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });
    });
  });
}