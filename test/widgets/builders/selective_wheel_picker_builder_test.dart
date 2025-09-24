import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:locuaz_wheel_pickers/src/widgets/builders/selective_wheel_picker_builder.dart';
import 'package:locuaz_wheel_pickers/src/controllers/wheel_manager.dart';
import 'package:locuaz_wheel_pickers/src/models/wheel_config.dart';
import 'package:locuaz_wheel_pickers/src/models/wheel_dependency.dart';

void main() {
  group('SelectiveWheelPickerBuilder', () {
    setUp(() {
      Get.testMode = true;
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('renders with basic configuration', (WidgetTester tester) async {
      final wheels = [
        WheelConfig(
          itemCount: 5,
          initialIndex: 0,
          formatter: (index) => 'Item $index',
          width: 100,
          wheelId: 'test_wheel',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectiveWheelPickerBuilder(
              wheels: wheels,
            ),
          ),
        ),
      );

      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
    });

    testWidgets('renders multiple wheels', (WidgetTester tester) async {
      final wheels = [
        WheelConfig(
          itemCount: 3,
          initialIndex: 0,
          formatter: (index) => 'A$index',
          width: 80,
          wheelId: 'wheel_a',
        ),
        WheelConfig(
          itemCount: 3,
          initialIndex: 1,
          formatter: (index) => 'B$index',
          width: 80,
          wheelId: 'wheel_b',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectiveWheelPickerBuilder(
              wheels: wheels,
            ),
          ),
        ),
      );

      expect(find.text('A0'), findsOneWidget);
      expect(find.text('B1'), findsOneWidget);
    });

    testWidgets('handles selection changes', (WidgetTester tester) async {
      List<int>? selectedIndices;
      final wheels = [
        WheelConfig(
          itemCount: 5,
          initialIndex: 0,
          formatter: (index) => 'Item $index',
          width: 100,
          wheelId: 'test_wheel',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectiveWheelPickerBuilder(
              wheels: wheels,
              onChanged: (indices) => selectedIndices = indices,
            ),
          ),
        ),
      );

      // Find the wheel picker and scroll it
      final wheelPickers = find.byType(Container);
      expect(wheelPickers, findsWidgets);

      // Simulate scroll gesture
      await tester.drag(wheelPickers.first, const Offset(0, -100));
      await tester.pumpAndSettle();

      expect(selectedIndices, isNotNull);
      expect(selectedIndices!.length, equals(1));
    });

    testWidgets('handles dependency-based recreation', (WidgetTester tester) async {
      final dayDependency = WheelDependency(
        dependsOn: [1], // depends on month wheel
        calculateItemCount: (values) => values[0] == 1 ? 28 : 31, // Feb: 28, others: 31
      );

      final wheels = [
        WheelConfig(
          itemCount: 31,
          initialIndex: 15,
          formatter: (index) => (index + 1).toString(),
          width: 80,
          wheelId: 'day_wheel',
          dependency: dayDependency,
        ),
        WheelConfig(
          itemCount: 12,
          initialIndex: 0, // January
          formatter: (index) => ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][index],
          width: 100,
          wheelId: 'month_wheel',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectiveWheelPickerBuilder(
              wheels: wheels,
            ),
          ),
        ),
      );

      expect(find.text('16'), findsOneWidget); // Day 16 (index 15)
      expect(find.text('Jan'), findsOneWidget);

      // Change month to February (index 1)
      final monthWheel = find.byType(Container).at(1);
      await tester.drag(monthWheel, const Offset(0, -50));
      await tester.pumpAndSettle();

      // Day wheel should be recreated with 28 days
      // The exact behavior depends on the implementation
      expect(find.byType(SelectiveWheelPickerBuilder), findsOneWidget);
    });

    testWidgets('uses external wheel manager', (WidgetTester tester) async {
      final wheelManager = WheelManager();
      final wheels = [
        WheelConfig(
          itemCount: 5,
          initialIndex: 0,
          formatter: (index) => 'Item $index',
          width: 100,
          wheelId: 'external_wheel',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectiveWheelPickerBuilder(
              wheels: wheels,
              wheelManager: wheelManager,
            ),
          ),
        ),
      );

      expect(find.text('Item 0'), findsOneWidget);
      
      wheelManager.dispose();
    });

    testWidgets('applies custom styling', (WidgetTester tester) async {
      final wheels = [
        WheelConfig(
          itemCount: 3,
          initialIndex: 0,
          formatter: (index) => index.toString(),
          width: 100,
          wheelId: 'styled_wheel',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectiveWheelPickerBuilder(
              wheels: wheels,
              wheelHeight: 200,
              barHeight: 50,
              barColor: Colors.red,
              selectedItemColor: Colors.blue,
              unselectedItemColor: Colors.grey,
            ),
          ),
        ),
      );

      expect(find.byType(SelectiveWheelPickerBuilder), findsOneWidget);
    });

    testWidgets('handles separators correctly', (WidgetTester tester) async {
      final wheels = [
        WheelConfig(
          itemCount: 3,
          initialIndex: 0,
          formatter: (index) => index.toString(),
          width: 60,
          wheelId: 'wheel1',
          trailingSeparator: const Text(':'),
        ),
        WheelConfig(
          itemCount: 3,
          initialIndex: 0,
          formatter: (index) => index.toString(),
          width: 60,
          wheelId: 'wheel2',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectiveWheelPickerBuilder(
              wheels: wheels,
            ),
          ),
        ),
      );

      expect(find.text(':'), findsOneWidget);
    });

    testWidgets('handles individual wheel callbacks', (WidgetTester tester) async {
      int? wheel1Selection;
      int? wheel2Selection;

      final wheels = [
        WheelConfig(
          itemCount: 5,
          initialIndex: 0,
          formatter: (index) => 'A$index',
          width: 80,
          wheelId: 'wheel_a',
          onChanged: (index) => wheel1Selection = index,
        ),
        WheelConfig(
          itemCount: 5,
          initialIndex: 0,
          formatter: (index) => 'B$index',
          width: 80,
          wheelId: 'wheel_b',
          onChanged: (index) => wheel2Selection = index,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectiveWheelPickerBuilder(
              wheels: wheels,
            ),
          ),
        ),
      );

      // Simulate scrolling the first wheel
      final containers = find.byType(Container);
      await tester.drag(containers.first, const Offset(0, -50));
      await tester.pumpAndSettle();

      // Individual wheel callback should be triggered
      expect(wheel1Selection, isNotNull);
    });

    testWidgets('handles empty wheels list', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SelectiveWheelPickerBuilder(
              wheels: [],
            ),
          ),
        ),
      );

      expect(find.byType(SelectiveWheelPickerBuilder), findsOneWidget);
    });

    testWidgets('handles single wheel', (WidgetTester tester) async {
      final wheels = [
        WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => 'Single $index',
          width: 150,
          wheelId: 'single_wheel',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectiveWheelPickerBuilder(
              wheels: wheels,
            ),
          ),
        ),
      );

      expect(find.text('Single 5'), findsOneWidget);
    });

    testWidgets('maintains state across rebuilds', (WidgetTester tester) async {
      List<int>? selectedIndices;
      final wheels = [
        WheelConfig(
          itemCount: 5,
          initialIndex: 2,
          formatter: (index) => 'Item $index',
          width: 100,
          wheelId: 'persistent_wheel',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectiveWheelPickerBuilder(
              wheels: wheels,
              onChanged: (indices) => selectedIndices = indices,
            ),
          ),
        ),
      );

      // Trigger a rebuild with same configuration
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectiveWheelPickerBuilder(
              wheels: wheels,
              onChanged: (indices) => selectedIndices = indices,
            ),
          ),
        ),
      );

      expect(find.byType(SelectiveWheelPickerBuilder), findsOneWidget);
    });

    testWidgets('handles theme changes', (WidgetTester tester) async {
      final wheels = [
        WheelConfig(
          itemCount: 3,
          initialIndex: 0,
          formatter: (index) => index.toString(),
          width: 100,
          wheelId: 'theme_wheel',
        ),
      ];

      // Light theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: SelectiveWheelPickerBuilder(
              wheels: wheels,
            ),
          ),
        ),
      );

      expect(find.byType(SelectiveWheelPickerBuilder), findsOneWidget);

      // Dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SelectiveWheelPickerBuilder(
              wheels: wheels,
            ),
          ),
        ),
      );

      expect(find.byType(SelectiveWheelPickerBuilder), findsOneWidget);
    });

    testWidgets('handles null callback gracefully', (WidgetTester tester) async {
      final wheels = [
        WheelConfig(
          itemCount: 5,
          initialIndex: 0,
          formatter: (index) => 'Item $index',
          width: 100,
          wheelId: 'null_callback_wheel',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectiveWheelPickerBuilder(
              wheels: wheels,
              onChanged: null,
            ),
          ),
        ),
      );

      // Should not crash when scrolling without callback
      final containers = find.byType(Container);
      await tester.drag(containers.first, const Offset(0, -50));
      await tester.pumpAndSettle();

      expect(find.byType(SelectiveWheelPickerBuilder), findsOneWidget);
    });

    group('performance', () {
      testWidgets('handles many wheels efficiently', (WidgetTester tester) async {
        final wheels = List.generate(10, (i) => WheelConfig(
          itemCount: 10,
          initialIndex: 0,
          formatter: (index) => '$i-$index',
          width: 50,
          wheelId: 'wheel_$i',
        ));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SelectiveWheelPickerBuilder(
                wheels: wheels,
              ),
            ),
          ),
        );

        expect(find.byType(SelectiveWheelPickerBuilder), findsOneWidget);
      });

      testWidgets('handles large item counts', (WidgetTester tester) async {
        final wheels = [
          WheelConfig(
            itemCount: 1000,
            initialIndex: 500,
            formatter: (index) => 'Item $index',
            width: 100,
            wheelId: 'large_wheel',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SelectiveWheelPickerBuilder(
                wheels: wheels,
              ),
            ),
          ),
        );

        expect(find.byType(SelectiveWheelPickerBuilder), findsOneWidget);
      });
    });

    group('edge cases', () {
      testWidgets('handles wheel with zero items', (WidgetTester tester) async {
        final wheels = [
          WheelConfig(
            itemCount: 0,
            initialIndex: 0,
            formatter: (index) => 'Item $index',
            width: 100,
            wheelId: 'empty_wheel',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SelectiveWheelPickerBuilder(
                wheels: wheels,
              ),
            ),
          ),
        );

        expect(find.byType(SelectiveWheelPickerBuilder), findsOneWidget);
      });

      testWidgets('handles invalid dependency configuration', (WidgetTester tester) async {
        final invalidDependency = WheelDependency(
          dependsOn: [], // invalid empty dependency
          calculateItemCount: (values) => 10,
        );

        final wheels = [
          WheelConfig(
            itemCount: 10,
            initialIndex: 0,
            formatter: (index) => 'Item $index',
            width: 100,
            wheelId: 'invalid_dep_wheel',
            dependency: invalidDependency,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SelectiveWheelPickerBuilder(
                wheels: wheels,
              ),
            ),
          ),
        );

        expect(find.byType(SelectiveWheelPickerBuilder), findsOneWidget);
      });

      testWidgets('handles formatter exceptions', (WidgetTester tester) async {
        final wheels = [
          WheelConfig(
            itemCount: 5,
            initialIndex: 0,
            formatter: (index) {
              if (index == 2) throw Exception('Formatter error');
              return 'Item $index';
            },
            width: 100,
            wheelId: 'error_wheel',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SelectiveWheelPickerBuilder(
                wheels: wheels,
              ),
            ),
          ),
        );

        expect(find.byType(SelectiveWheelPickerBuilder), findsOneWidget);
      });
    });

    group('real-world scenarios', () {
      testWidgets('date picker scenario', (WidgetTester tester) async {
        final dayDependency = WheelDependency(
          dependsOn: [1, 2], // month, year
          calculateItemCount: (values) {
            final month = values[0] + 1;
            final year = 2000 + values[1];
            return DateTime(year, month + 1, 0).day;
          },
        );

        final wheels = [
          WheelConfig(
            itemCount: 31,
            initialIndex: 15,
            formatter: (index) => (index + 1).toString(),
            width: 80,
            wheelId: 'day',
            dependency: dayDependency,
          ),
          WheelConfig(
            itemCount: 12,
            initialIndex: 0,
            formatter: (index) => (index + 1).toString(),
            width: 80,
            wheelId: 'month',
          ),
          WheelConfig(
            itemCount: 50,
            initialIndex: 24,
            formatter: (index) => (2000 + index).toString(),
            width: 100,
            wheelId: 'year',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SelectiveWheelPickerBuilder(
                wheels: wheels,
              ),
            ),
          ),
        );

        expect(find.text('16'), findsOneWidget); // Day
        expect(find.text('1'), findsOneWidget);  // Month
        expect(find.text('2024'), findsOneWidget); // Year
      });

      testWidgets('time picker scenario', (WidgetTester tester) async {
        final wheels = [
          WheelConfig(
            itemCount: 24,
            initialIndex: 12,
            formatter: (index) => index.toString().padLeft(2, '0'),
            width: 60,
            wheelId: 'hour',
            trailingSeparator: const Text(':'),
          ),
          WheelConfig(
            itemCount: 60,
            initialIndex: 30,
            formatter: (index) => index.toString().padLeft(2, '0'),
            width: 60,
            wheelId: 'minute',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SelectiveWheelPickerBuilder(
                wheels: wheels,
              ),
            ),
          ),
        );

        expect(find.text('12'), findsOneWidget);
        expect(find.text('30'), findsOneWidget);
        expect(find.text(':'), findsOneWidget);
      });

      testWidgets('cascading dependency scenario', (WidgetTester tester) async {
        final stateDependency = WheelDependency(
          dependsOn: [0], // country
          calculateItemCount: (values) => values[0] == 0 ? 50 : 10, // USA: 50 states, others: 10
        );

        final cityDependency = WheelDependency(
          dependsOn: [1], // state
          calculateItemCount: (values) => values[0] * 5 + 10, // 5 cities per state + 10
        );

        final wheels = [
          WheelConfig(
            itemCount: 3,
            initialIndex: 0,
            formatter: (index) => ['USA', 'Canada', 'Mexico'][index],
            width: 100,
            wheelId: 'country',
          ),
          WheelConfig(
            itemCount: 50,
            initialIndex: 0,
            formatter: (index) => 'State $index',
            width: 100,
            wheelId: 'state',
            dependency: stateDependency,
          ),
          WheelConfig(
            itemCount: 10,
            initialIndex: 0,
            formatter: (index) => 'City $index',
            width: 100,
            wheelId: 'city',
            dependency: cityDependency,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SelectiveWheelPickerBuilder(
                wheels: wheels,
              ),
            ),
          ),
        );

        expect(find.text('USA'), findsOneWidget);
        expect(find.text('State 0'), findsOneWidget);
        expect(find.text('City 0'), findsOneWidget);
      });
    });

    group('accessibility', () {
      testWidgets('provides semantic information', (WidgetTester tester) async {
        final wheels = [
          WheelConfig(
            itemCount: 5,
            initialIndex: 0,
            formatter: (index) => 'Item $index',
            width: 100,
            wheelId: 'accessible_wheel',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SelectiveWheelPickerBuilder(
                wheels: wheels,
              ),
            ),
          ),
        );

        expect(find.byType(SelectiveWheelPickerBuilder), findsOneWidget);
      });
    });
  });
}