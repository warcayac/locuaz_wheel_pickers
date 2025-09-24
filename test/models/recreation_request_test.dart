import 'package:flutter_test/flutter_test.dart';
import 'package:locuaz_wheel_pickers/src/models/recreation_request.dart';
import 'package:locuaz_wheel_pickers/src/models/wheel_config.dart';

void main() {
  group('RecreationRequest', () {
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
      test('creates request with required parameters', () {
        final request = RecreationRequest(
          wheelIndex: 2,
          newConfig: testConfig,
        );

        expect(request.wheelIndex, equals(2));
        expect(request.newConfig, equals(testConfig));
        expect(request.preserveSelection, isTrue); // default value
      });

      test('creates request with all parameters', () {
        final request = RecreationRequest(
          wheelIndex: 3,
          newConfig: testConfig,
          preserveSelection: false,
        );

        expect(request.wheelIndex, equals(3));
        expect(request.newConfig, equals(testConfig));
        expect(request.preserveSelection, isFalse);
      });

      test('accepts various wheel indices', () {
        final request1 = RecreationRequest(wheelIndex: 0, newConfig: testConfig);
        final request2 = RecreationRequest(wheelIndex: 100, newConfig: testConfig);
        
        expect(request1.wheelIndex, equals(0));
        expect(request2.wheelIndex, equals(100));
      });

      test('accepts different config types', () {
        final simpleConfig = WheelConfig(
          itemCount: 5,
          initialIndex: 0,
          formatter: (index) => 'Item $index',
        );
        
        final complexConfig = WheelConfig(
          itemCount: 24,
          initialIndex: 12,
          formatter: (index) => index.toString().padLeft(2, '0'),
          width: 80,
          wheelId: 'hour_wheel',
        );

        final request1 = RecreationRequest(wheelIndex: 1, newConfig: simpleConfig);
        final request2 = RecreationRequest(wheelIndex: 2, newConfig: complexConfig);

        expect(request1.newConfig, equals(simpleConfig));
        expect(request2.newConfig, equals(complexConfig));
      });
    });

    group('preserveSelection parameter', () {
      test('defaults to true when not specified', () {
        final request = RecreationRequest(
          wheelIndex: 1,
          newConfig: testConfig,
        );

        expect(request.preserveSelection, isTrue);
      });

      test('can be explicitly set to true', () {
        final request = RecreationRequest(
          wheelIndex: 1,
          newConfig: testConfig,
          preserveSelection: true,
        );

        expect(request.preserveSelection, isTrue);
      });

      test('can be explicitly set to false', () {
        final request = RecreationRequest(
          wheelIndex: 1,
          newConfig: testConfig,
          preserveSelection: false,
        );

        expect(request.preserveSelection, isFalse);
      });
    });

    group('immutability', () {
      test('properties are final and cannot be changed', () {
        final request = RecreationRequest(
          wheelIndex: 1,
          newConfig: testConfig,
          preserveSelection: false,
        );

        // Verify properties are accessible
        expect(request.wheelIndex, equals(1));
        expect(request.newConfig, equals(testConfig));
        expect(request.preserveSelection, isFalse);

        // Properties should be final (compile-time check)
        // This test verifies the properties exist and are accessible
      });
    });

    group('real-world usage scenarios', () {
      test('creates request for date picker day wheel recreation', () {
        final dayConfig = WheelConfig(
          itemCount: 29, // February in leap year
          initialIndex: 15,
          formatter: (index) => (index + 1).toString(),
          wheelId: 'day_wheel',
        );

        final request = RecreationRequest(
          wheelIndex: 0, // day wheel is first
          newConfig: dayConfig,
          preserveSelection: true, // try to keep current day selected
        );

        expect(request.wheelIndex, equals(0));
        expect(request.newConfig.itemCount, equals(29));
        expect(request.newConfig.wheelId, equals('day_wheel'));
        expect(request.preserveSelection, isTrue);
      });

      test('creates request for time picker hour wheel recreation', () {
        final hourConfig = WheelConfig(
          itemCount: 12, // 12-hour format
          initialIndex: 0,
          formatter: (index) => (index + 1).toString(),
          wheelId: 'hour_wheel',
        );

        final request = RecreationRequest(
          wheelIndex: 1, // hour wheel is second
          newConfig: hourConfig,
          preserveSelection: false, // reset to default hour
        );

        expect(request.wheelIndex, equals(1));
        expect(request.newConfig.itemCount, equals(12));
        expect(request.newConfig.wheelId, equals('hour_wheel'));
        expect(request.preserveSelection, isFalse);
      });

      test('creates request for cascading dependency recreation', () {
        final stateConfig = WheelConfig(
          itemCount: 50, // 50 states for USA
          initialIndex: 0,
          formatter: (index) => 'State $index',
          wheelId: 'state_wheel',
        );

        final request = RecreationRequest(
          wheelIndex: 2, // state wheel depends on country wheel
          newConfig: stateConfig,
          preserveSelection: true, // try to preserve state selection
        );

        expect(request.wheelIndex, equals(2));
        expect(request.newConfig.itemCount, equals(50));
        expect(request.preserveSelection, isTrue);
      });

      test('creates request for performance optimization scenario', () {
        final optimizedConfig = WheelConfig(
          itemCount: 100,
          initialIndex: 50,
          formatter: (index) => 'Optimized Item $index',
          wheelId: 'optimized_wheel',
        );

        final request = RecreationRequest(
          wheelIndex: 5,
          newConfig: optimizedConfig,
          preserveSelection: false, // reset for optimization
        );

        expect(request.wheelIndex, equals(5));
        expect(request.newConfig.wheelId, equals('optimized_wheel'));
        expect(request.preserveSelection, isFalse);
      });
    });

    group('edge cases', () {
      test('handles zero wheel index', () {
        final request = RecreationRequest(
          wheelIndex: 0,
          newConfig: testConfig,
        );

        expect(request.wheelIndex, equals(0));
      });

      test('handles large wheel index', () {
        final request = RecreationRequest(
          wheelIndex: 999999,
          newConfig: testConfig,
        );

        expect(request.wheelIndex, equals(999999));
      });

      test('handles config with minimal properties', () {
        final minimalConfig = WheelConfig(
          itemCount: 1,
          initialIndex: 0,
          formatter: (index) => '',
        );

        final request = RecreationRequest(
          wheelIndex: 1,
          newConfig: minimalConfig,
        );

        expect(request.newConfig.itemCount, equals(1));
        expect(request.newConfig.initialIndex, equals(0));
        expect(request.newConfig.formatter(0), equals(''));
      });

      test('handles config with all optional properties', () {
        final fullConfig = WheelConfig(
          itemCount: 24,
          initialIndex: 12,
          formatter: (index) => index.toString().padLeft(2, '0'),
          width: 100,
          onChanged: (index) {},
          wheelId: 'full_wheel',
        );

        final request = RecreationRequest(
          wheelIndex: 3,
          newConfig: fullConfig,
          preserveSelection: false,
        );

        expect(request.newConfig.itemCount, equals(24));
        expect(request.newConfig.width, equals(100));
        expect(request.newConfig.wheelId, equals('full_wheel'));
        expect(request.newConfig.onChanged, isNotNull);
      });
    });

    group('type safety', () {
      test('ensures wheelIndex is int', () {
        final request = RecreationRequest(
          wheelIndex: 42,
          newConfig: testConfig,
        );

        expect(request.wheelIndex, isA<int>());
        expect(request.wheelIndex, equals(42));
      });

      test('ensures newConfig is WheelConfig', () {
        final request = RecreationRequest(
          wheelIndex: 1,
          newConfig: testConfig,
        );

        expect(request.newConfig, isA<WheelConfig>());
        expect(request.newConfig, equals(testConfig));
      });

      test('ensures preserveSelection is bool', () {
        final request1 = RecreationRequest(
          wheelIndex: 1,
          newConfig: testConfig,
          preserveSelection: true,
        );
        
        final request2 = RecreationRequest(
          wheelIndex: 1,
          newConfig: testConfig,
          preserveSelection: false,
        );

        expect(request1.preserveSelection, isA<bool>());
        expect(request1.preserveSelection, isTrue);
        expect(request2.preserveSelection, isA<bool>());
        expect(request2.preserveSelection, isFalse);
      });
    });
  });
}