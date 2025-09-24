import 'package:flutter_test/flutter_test.dart';
import 'package:locuaz_wheel_pickers/src/controllers/recreation_decision.dart';
import 'package:locuaz_wheel_pickers/src/models/wheel_config.dart';

void main() {
  group('RecreationDecision', () {
    late WheelConfig testConfig;

    setUp(() {
      testConfig = WheelConfig(
        itemCount: 10,
        initialIndex: 5,
        formatter: (index) => index.toString(),
        wheelId: 'test_wheel',
      );
    });

    group('constructor', () {
      test('creates decision with all required parameters', () {
        final decision = RecreationDecision(
          wheelIndex: 2,
          needsRecreation: true,
          newConfig: testConfig,
          reason: 'Item count changed',
        );

        expect(decision.wheelIndex, equals(2));
        expect(decision.needsRecreation, isTrue);
        expect(decision.newConfig, equals(testConfig));
        expect(decision.reason, equals('Item count changed'));
      });

      test('creates decision with null config when recreation not needed', () {
        final decision = RecreationDecision(
          wheelIndex: 1,
          needsRecreation: false,
          newConfig: null,
          reason: 'No dependencies',
        );

        expect(decision.wheelIndex, equals(1));
        expect(decision.needsRecreation, isFalse);
        expect(decision.newConfig, isNull);
        expect(decision.reason, equals('No dependencies'));
      });

      test('accepts various wheel indices', () {
        final decision1 = RecreationDecision(
          wheelIndex: 0,
          needsRecreation: false,
          newConfig: null,
          reason: 'Test',
        );
        final decision2 = RecreationDecision(
          wheelIndex: 999,
          needsRecreation: true,
          newConfig: testConfig,
          reason: 'Test',
        );

        expect(decision1.wheelIndex, equals(0));
        expect(decision2.wheelIndex, equals(999));
      });

      test('accepts various reason strings', () {
        final reasons = [
          'Item count changed: 10 -> 15',
          'No dependencies - position-only updates',
          'Configuration unchanged - no recreation needed',
          'Failed to calculate new configuration',
          'Error during recreation check: Exception',
        ];

        for (final reason in reasons) {
          final decision = RecreationDecision(
            wheelIndex: 0,
            needsRecreation: false,
            newConfig: null,
            reason: reason,
          );

          expect(decision.reason, equals(reason));
        }
      });
    });

    group('toString', () {
      test('provides meaningful string representation', () {
        final decision = RecreationDecision(
          wheelIndex: 3,
          needsRecreation: true,
          newConfig: testConfig,
          reason: 'Item count changed from 10 to 15',
        );

        final stringRep = decision.toString();

        expect(stringRep, contains('RecreationDecision'));
        expect(stringRep, contains('wheelIndex: 3'));
        expect(stringRep, contains('needsRecreation: true'));
        expect(stringRep, contains('reason: Item count changed from 10 to 15'));
      });

      test('handles false needsRecreation correctly', () {
        final decision = RecreationDecision(
          wheelIndex: 1,
          needsRecreation: false,
          newConfig: null,
          reason: 'No recreation needed',
        );

        final stringRep = decision.toString();

        expect(stringRep, contains('needsRecreation: false'));
        expect(stringRep, contains('reason: No recreation needed'));
      });

      test('handles long reason strings', () {
        final longReason = 'This is a very long reason string that describes in detail why the wheel needs recreation including specific item count changes and dependency calculations';
        final decision = RecreationDecision(
          wheelIndex: 0,
          needsRecreation: true,
          newConfig: testConfig,
          reason: longReason,
        );

        final stringRep = decision.toString();

        expect(stringRep, contains(longReason));
      });
    });

    group('equality and hashCode', () {
      test('decisions with same properties are equal', () {
        final decision1 = RecreationDecision(
          wheelIndex: 2,
          needsRecreation: true,
          newConfig: testConfig,
          reason: 'Item count changed',
        );
        final decision2 = RecreationDecision(
          wheelIndex: 2,
          needsRecreation: true,
          newConfig: testConfig,
          reason: 'Item count changed',
        );

        expect(decision1, equals(decision2));
        expect(decision1.hashCode, equals(decision2.hashCode));
      });

      test('decisions with different wheelIndex are not equal', () {
        final decision1 = RecreationDecision(
          wheelIndex: 1,
          needsRecreation: true,
          newConfig: testConfig,
          reason: 'Test',
        );
        final decision2 = RecreationDecision(
          wheelIndex: 2,
          needsRecreation: true,
          newConfig: testConfig,
          reason: 'Test',
        );

        expect(decision1, isNot(equals(decision2)));
        expect(decision1.hashCode, isNot(equals(decision2.hashCode)));
      });

      test('decisions with different needsRecreation are not equal', () {
        final decision1 = RecreationDecision(
          wheelIndex: 1,
          needsRecreation: true,
          newConfig: testConfig,
          reason: 'Test',
        );
        final decision2 = RecreationDecision(
          wheelIndex: 1,
          needsRecreation: false,
          newConfig: null,
          reason: 'Test',
        );

        expect(decision1, isNot(equals(decision2)));
        expect(decision1.hashCode, isNot(equals(decision2.hashCode)));
      });

      test('decisions with different newConfig are not equal', () {
        final config1 = WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => index.toString(),
        );
        final config2 = WheelConfig(
          itemCount: 15,
          initialIndex: 5,
          formatter: (index) => index.toString(),
        );

        final decision1 = RecreationDecision(
          wheelIndex: 1,
          needsRecreation: true,
          newConfig: config1,
          reason: 'Test',
        );
        final decision2 = RecreationDecision(
          wheelIndex: 1,
          needsRecreation: true,
          newConfig: config2,
          reason: 'Test',
        );

        expect(decision1, isNot(equals(decision2)));
        expect(decision1.hashCode, isNot(equals(decision2.hashCode)));
      });

      test('decisions with different reason are not equal', () {
        final decision1 = RecreationDecision(
          wheelIndex: 1,
          needsRecreation: true,
          newConfig: testConfig,
          reason: 'Reason 1',
        );
        final decision2 = RecreationDecision(
          wheelIndex: 1,
          needsRecreation: true,
          newConfig: testConfig,
          reason: 'Reason 2',
        );

        expect(decision1, isNot(equals(decision2)));
        expect(decision1.hashCode, isNot(equals(decision2.hashCode)));
      });

      test('decisions with null vs non-null config are not equal', () {
        final decision1 = RecreationDecision(
          wheelIndex: 1,
          needsRecreation: false,
          newConfig: null,
          reason: 'Test',
        );
        final decision2 = RecreationDecision(
          wheelIndex: 1,
          needsRecreation: false,
          newConfig: testConfig,
          reason: 'Test',
        );

        expect(decision1, isNot(equals(decision2)));
        expect(decision1.hashCode, isNot(equals(decision2.hashCode)));
      });

      test('identical decisions are equal', () {
        final decision = RecreationDecision(
          wheelIndex: 1,
          needsRecreation: true,
          newConfig: testConfig,
          reason: 'Test',
        );

        expect(decision, equals(decision));
        expect(decision.hashCode, equals(decision.hashCode));
      });
    });

    group('immutability', () {
      test('properties are final and cannot be changed', () {
        final decision = RecreationDecision(
          wheelIndex: 2,
          needsRecreation: true,
          newConfig: testConfig,
          reason: 'Item count changed',
        );

        // Verify properties are accessible and maintain their values
        expect(decision.wheelIndex, equals(2));
        expect(decision.needsRecreation, isTrue);
        expect(decision.newConfig, equals(testConfig));
        expect(decision.reason, equals('Item count changed'));

        // Properties should be final (compile-time check)
        // This test verifies the properties exist and are accessible
      });
    });

    group('real-world usage scenarios', () {
      test('represents day wheel recreation decision', () {
        final dayConfig = WheelConfig(
          itemCount: 29, // February in leap year
          initialIndex: 15,
          formatter: (index) => (index + 1).toString(),
          wheelId: 'day_wheel',
        );

        final decision = RecreationDecision(
          wheelIndex: 0,
          needsRecreation: true,
          newConfig: dayConfig,
          reason: 'Item count changed: 31 -> 29 (February leap year)',
        );

        expect(decision.wheelIndex, equals(0));
        expect(decision.needsRecreation, isTrue);
        expect(decision.newConfig!.itemCount, equals(29));
        expect(decision.newConfig!.wheelId, equals('day_wheel'));
        expect(decision.reason, contains('February leap year'));
      });

      test('represents hour wheel format change decision', () {
        final hourConfig = WheelConfig(
          itemCount: 12, // 12-hour format
          initialIndex: 3, // 3 PM -> 3 PM in 12h format
          formatter: (index) => (index + 1).toString(),
          wheelId: 'hour_wheel',
        );

        final decision = RecreationDecision(
          wheelIndex: 1,
          needsRecreation: true,
          newConfig: hourConfig,
          reason: 'Item count changed: 24 -> 12 (switched to 12-hour format)',
        );

        expect(decision.wheelIndex, equals(1));
        expect(decision.needsRecreation, isTrue);
        expect(decision.newConfig!.itemCount, equals(12));
        expect(decision.reason, contains('12-hour format'));
      });

      test('represents no recreation needed decision', () {
        final decision = RecreationDecision(
          wheelIndex: 2,
          needsRecreation: false,
          newConfig: null,
          reason: 'Wheel has no dependencies - position-only updates',
        );

        expect(decision.wheelIndex, equals(2));
        expect(decision.needsRecreation, isFalse);
        expect(decision.newConfig, isNull);
        expect(decision.reason, contains('no dependencies'));
      });

      test('represents calculation failure decision', () {
        final decision = RecreationDecision(
          wheelIndex: 3,
          needsRecreation: false,
          newConfig: null,
          reason: 'Failed to calculate new configuration: dependency index out of bounds',
        );

        expect(decision.wheelIndex, equals(3));
        expect(decision.needsRecreation, isFalse);
        expect(decision.newConfig, isNull);
        expect(decision.reason, contains('Failed to calculate'));
        expect(decision.reason, contains('out of bounds'));
      });

      test('represents error handling decision', () {
        final decision = RecreationDecision(
          wheelIndex: 4,
          needsRecreation: false,
          newConfig: null,
          reason: 'Error during recreation check: RangeError: Index out of range',
        );

        expect(decision.wheelIndex, equals(4));
        expect(decision.needsRecreation, isFalse);
        expect(decision.newConfig, isNull);
        expect(decision.reason, contains('Error during recreation check'));
        expect(decision.reason, contains('RangeError'));
      });
    });

    group('edge cases', () {
      test('handles zero wheel index', () {
        final decision = RecreationDecision(
          wheelIndex: 0,
          needsRecreation: true,
          newConfig: testConfig,
          reason: 'First wheel recreation',
        );

        expect(decision.wheelIndex, equals(0));
      });

      test('handles large wheel index', () {
        final decision = RecreationDecision(
          wheelIndex: 999999,
          needsRecreation: false,
          newConfig: null,
          reason: 'Large index test',
        );

        expect(decision.wheelIndex, equals(999999));
      });

      test('handles empty reason string', () {
        final decision = RecreationDecision(
          wheelIndex: 1,
          needsRecreation: false,
          newConfig: null,
          reason: '',
        );

        expect(decision.reason, equals(''));
        expect(decision.toString(), contains('reason: '));
      });

      test('handles very long reason string', () {
        final longReason = 'A' * 1000; // 1000 character string
        final decision = RecreationDecision(
          wheelIndex: 1,
          needsRecreation: false,
          newConfig: null,
          reason: longReason,
        );

        expect(decision.reason, equals(longReason));
        expect(decision.reason.length, equals(1000));
      });

      test('handles special characters in reason', () {
        final specialReason = 'Reason with special chars: !@#\$%^&*()_+-=[]{}|;:,.<>?';
        final decision = RecreationDecision(
          wheelIndex: 1,
          needsRecreation: false,
          newConfig: null,
          reason: specialReason,
        );

        expect(decision.reason, equals(specialReason));
        expect(decision.toString(), contains(specialReason));
      });

      test('handles unicode characters in reason', () {
        final unicodeReason = 'Unicode test: 🎯 ✅ ❌ 🔄 📊';
        final decision = RecreationDecision(
          wheelIndex: 1,
          needsRecreation: false,
          newConfig: null,
          reason: unicodeReason,
        );

        expect(decision.reason, equals(unicodeReason));
        expect(decision.toString(), contains(unicodeReason));
      });
    });

    group('type safety', () {
      test('ensures wheelIndex is int', () {
        final decision = RecreationDecision(
          wheelIndex: 42,
          needsRecreation: false,
          newConfig: null,
          reason: 'Test',
        );

        expect(decision.wheelIndex, isA<int>());
        expect(decision.wheelIndex, equals(42));
      });

      test('ensures needsRecreation is bool', () {
        final decision1 = RecreationDecision(
          wheelIndex: 1,
          needsRecreation: true,
          newConfig: testConfig,
          reason: 'Test',
        );
        final decision2 = RecreationDecision(
          wheelIndex: 1,
          needsRecreation: false,
          newConfig: null,
          reason: 'Test',
        );

        expect(decision1.needsRecreation, isA<bool>());
        expect(decision1.needsRecreation, isTrue);
        expect(decision2.needsRecreation, isA<bool>());
        expect(decision2.needsRecreation, isFalse);
      });

      test('ensures newConfig is WheelConfig or null', () {
        final decision1 = RecreationDecision(
          wheelIndex: 1,
          needsRecreation: true,
          newConfig: testConfig,
          reason: 'Test',
        );
        final decision2 = RecreationDecision(
          wheelIndex: 1,
          needsRecreation: false,
          newConfig: null,
          reason: 'Test',
        );

        expect(decision1.newConfig, isA<WheelConfig>());
        expect(decision1.newConfig, equals(testConfig));
        expect(decision2.newConfig, isNull);
      });

      test('ensures reason is String', () {
        final decision = RecreationDecision(
          wheelIndex: 1,
          needsRecreation: false,
          newConfig: null,
          reason: 'Test reason',
        );

        expect(decision.reason, isA<String>());
        expect(decision.reason, equals('Test reason'));
      });
    });

    group('consistency checks', () {
      test('recreation needed should have newConfig', () {
        // This is a logical consistency check, not enforced by the class
        final decision = RecreationDecision(
          wheelIndex: 1,
          needsRecreation: true,
          newConfig: testConfig, // Should have config when recreation needed
          reason: 'Recreation needed',
        );

        expect(decision.needsRecreation, isTrue);
        expect(decision.newConfig, isNotNull);
      });

      test('no recreation should typically have null newConfig', () {
        // This is a logical consistency check, not enforced by the class
        final decision = RecreationDecision(
          wheelIndex: 1,
          needsRecreation: false,
          newConfig: null, // Typically null when no recreation needed
          reason: 'No recreation needed',
        );

        expect(decision.needsRecreation, isFalse);
        expect(decision.newConfig, isNull);
      });

      test('allows inconsistent states for error cases', () {
        // The class allows inconsistent states for error handling
        final decision = RecreationDecision(
          wheelIndex: 1,
          needsRecreation: true,
          newConfig: null, // Inconsistent but allowed for error cases
          reason: 'Recreation needed but config calculation failed',
        );

        expect(decision.needsRecreation, isTrue);
        expect(decision.newConfig, isNull);
        expect(decision.reason, contains('failed'));
      });
    });
  });
}