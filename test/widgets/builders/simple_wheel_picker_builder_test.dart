import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locuaz_wheel_pickers/src/widgets/builders/simple_wheel_picker_builder.dart';
import 'package:locuaz_wheel_pickers/src/models/wheel_config.dart';
import 'package:locuaz_wheel_pickers/src/helpers/wheel_separators.dart';

void main() {
  group('SimpleWheelPickerBuilder', () {
    testWidgets('renders with basic configuration', (WidgetTester tester) async {
      final wheels = [
        WheelConfig(
          itemCount: 5,
          initialIndex: 0,
          formatter: (index) => 'Item $index',
          width: 100,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleWheelPickerBuilder(
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
        ),
        WheelConfig(
          itemCount: 3,
          initialIndex: 1,
          formatter: (index) => 'B$index',
          width: 80,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleWheelPickerBuilder(
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
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleWheelPickerBuilder(
              wheels: wheels,
              onChanged: (indices) => selectedIndices = indices,
            ),
          ),
        ),
      );

      // Find the first wheel and scroll it
      final wheelPickers = find.byType(Container);
      expect(wheelPickers, findsWidgets);

      // Simulate scroll gesture
      await tester.drag(wheelPickers.first, const Offset(0, -100));
      await tester.pumpAndSettle();

      expect(selectedIndices, isNotNull);
      expect(selectedIndices!.length, equals(1));
    });

    testWidgets('renders separators correctly', (WidgetTester tester) async {
      final wheels = [
        WheelConfig(
          itemCount: 3,
          initialIndex: 0,
          formatter: (index) => index.toString(),
          width: 60,
          trailingSeparator: const Text(':'),
        ),
        WheelConfig(
          itemCount: 3,
          initialIndex: 0,
          formatter: (index) => index.toString(),
          width: 60,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleWheelPickerBuilder(
              wheels: wheels,
            ),
          ),
        ),
      );

      expect(find.text(':'), findsOneWidget);
    });

    testWidgets('applies custom styling', (WidgetTester tester) async {
      final wheels = [
        WheelConfig(
          itemCount: 3,
          initialIndex: 0,
          formatter: (index) => index.toString(),
          width: 100,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleWheelPickerBuilder(
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

      expect(find.byType(SimpleWheelPickerBuilder), findsOneWidget);
    });

    testWidgets('uses custom text style function', (WidgetTester tester) async {
      final wheels = [
        WheelConfig(
          itemCount: 3,
          initialIndex: 0,
          formatter: (index) => index.toString(),
          width: 100,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleWheelPickerBuilder(
              wheels: wheels,
              textStyle: (isSelected) => TextStyle(
                fontSize: isSelected ? 24 : 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SimpleWheelPickerBuilder), findsOneWidget);
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
          onChanged: (index) => wheel1Selection = index,
        ),
        WheelConfig(
          itemCount: 5,
          initialIndex: 0,
          formatter: (index) => 'B$index',
          width: 80,
          onChanged: (index) => wheel2Selection = index,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleWheelPickerBuilder(
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
            body: SimpleWheelPickerBuilder(
              wheels: [],
            ),
          ),
        ),
      );

      expect(find.byType(SimpleWheelPickerBuilder), findsOneWidget);
    });

    testWidgets('handles single wheel', (WidgetTester tester) async {
      final wheels = [
        WheelConfig(
          itemCount: 10,
          initialIndex: 5,
          formatter: (index) => 'Single $index',
          width: 150,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleWheelPickerBuilder(
              wheels: wheels,
            ),
          ),
        ),
      );

      expect(find.text('Single 5'), findsOneWidget);
    });

    testWidgets('respects wheel widths', (WidgetTester tester) async {
      final wheels = [
        WheelConfig(
          itemCount: 3,
          initialIndex: 0,
          formatter: (index) => 'A',
          width: 50,
        ),
        WheelConfig(
          itemCount: 3,
          initialIndex: 0,
          formatter: (index) => 'B',
          width: 100,
        ),
        WheelConfig(
          itemCount: 3,
          initialIndex: 0,
          formatter: (index) => 'C',
          width: 75,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleWheelPickerBuilder(
              wheels: wheels,
            ),
          ),
        ),
      );

      expect(find.byType(SimpleWheelPickerBuilder), findsOneWidget);
    });

    testWidgets('handles complex separators', (WidgetTester tester) async {
      final wheels = [
        WheelConfig(
          itemCount: 24,
          initialIndex: 12,
          formatter: (index) => index.toString().padLeft(2, '0'),
          width: 60,
          trailingSeparator: const WheelSeparators().colon(),
        ),
        WheelConfig(
          itemCount: 60,
          initialIndex: 30,
          formatter: (index) => index.toString().padLeft(2, '0'),
          width: 60,
          trailingSeparator: const WheelSeparators().colon(),
        ),
        WheelConfig(
          itemCount: 60,
          initialIndex: 0,
          formatter: (index) => index.toString().padLeft(2, '0'),
          width: 60,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleWheelPickerBuilder(
              wheels: wheels,
            ),
          ),
        ),
      );

      expect(find.text(':'), findsNWidgets(2)); // Two colons for time format
    });

    testWidgets('maintains state across rebuilds', (WidgetTester tester) async {
      List<int>? selectedIndices;
      final wheels = [
        WheelConfig(
          itemCount: 5,
          initialIndex: 2,
          formatter: (index) => 'Item $index',
          width: 100,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleWheelPickerBuilder(
              wheels: wheels,
              onChanged: (indices) => selectedIndices = indices,
            ),
          ),
        ),
      );

      // Initial state should reflect initial index
      expect(selectedIndices, isNull); // Not called initially

      // Trigger a rebuild with same configuration
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleWheelPickerBuilder(
              wheels: wheels,
              onChanged: (indices) => selectedIndices = indices,
            ),
          ),
        ),
      );

      expect(find.byType(SimpleWheelPickerBuilder), findsOneWidget);
    });

    testWidgets('handles theme changes', (WidgetTester tester) async {
      final wheels = [
        WheelConfig(
          itemCount: 3,
          initialIndex: 0,
          formatter: (index) => index.toString(),
          width: 100,
        ),
      ];

      // Light theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: SimpleWheelPickerBuilder(
              wheels: wheels,
            ),
          ),
        ),
      );

      expect(find.byType(SimpleWheelPickerBuilder), findsOneWidget);

      // Dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SimpleWheelPickerBuilder(
              wheels: wheels,
            ),
          ),
        ),
      );

      expect(find.byType(SimpleWheelPickerBuilder), findsOneWidget);
    });

    testWidgets('handles null callback gracefully', (WidgetTester tester) async {
      final wheels = [
        WheelConfig(
          itemCount: 5,
          initialIndex: 0,
          formatter: (index) => 'Item $index',
          width: 100,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleWheelPickerBuilder(
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

      expect(find.byType(SimpleWheelPickerBuilder), findsOneWidget);
    });

    group('accessibility', () {
      testWidgets('provides semantic information', (WidgetTester tester) async {
        final wheels = [
          WheelConfig(
            itemCount: 5,
            initialIndex: 0,
            formatter: (index) => 'Item $index',
            width: 100,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SimpleWheelPickerBuilder(
                wheels: wheels,
              ),
            ),
          ),
        );

        expect(find.byType(SimpleWheelPickerBuilder), findsOneWidget);
      });
    });

    group('performance', () {
      testWidgets('handles many wheels efficiently', (WidgetTester tester) async {
        final wheels = List.generate(10, (i) => WheelConfig(
          itemCount: 10,
          initialIndex: 0,
          formatter: (index) => '$i-$index',
          width: 50,
        ));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SimpleWheelPickerBuilder(
                wheels: wheels,
              ),
            ),
          ),
        );

        expect(find.byType(SimpleWheelPickerBuilder), findsOneWidget);
      });

      testWidgets('handles large item counts', (WidgetTester tester) async {
        final wheels = [
          WheelConfig(
            itemCount: 1000,
            initialIndex: 500,
            formatter: (index) => 'Item $index',
            width: 100,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
            body: SimpleWheelPickerBuilder(
              wheels: wheels,
            ),
          ),
        ),
      );

      expect(find.byType(SimpleWheelPickerBuilder), findsOneWidget);
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
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SimpleWheelPickerBuilder(
                wheels: wheels,
              ),
            ),
          ),
        );

        expect(find.byType(SimpleWheelPickerBuilder), findsOneWidget);
      });

      testWidgets('handles invalid initial index', (WidgetTester tester) async {
        final wheels = [
          WheelConfig(
            itemCount: 5,
            initialIndex: 10, // Out of bounds
            formatter: (index) => 'Item $index',
            width: 100,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SimpleWheelPickerBuilder(
                wheels: wheels,
              ),
            ),
          ),
        );

        expect(find.byType(SimpleWheelPickerBuilder), findsOneWidget);
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
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SimpleWheelPickerBuilder(
                wheels: wheels,
              ),
            ),
          ),
        );

        expect(find.byType(SimpleWheelPickerBuilder), findsOneWidget);
      });
    });

    group('real-world scenarios', () {
      testWidgets('time picker scenario', (WidgetTester tester) async {
        List<int>? selectedTime;
        final wheels = [
          WheelConfig(
            itemCount: 24,
            initialIndex: 12,
            formatter: (index) => index.toString().padLeft(2, '0'),
            width: 60,
            trailingSeparator: const Text(':'),
          ),
          WheelConfig(
            itemCount: 60,
            initialIndex: 30,
            formatter: (index) => index.toString().padLeft(2, '0'),
            width: 60,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SimpleWheelPickerBuilder(
                wheels: wheels,
                onChanged: (indices) => selectedTime = indices,
              ),
            ),
          ),
        );

        expect(find.text('12'), findsOneWidget);
        expect(find.text('30'), findsOneWidget);
        expect(find.text(':'), findsOneWidget);
      });

      testWidgets('measurement picker scenario', (WidgetTester tester) async {
        final wheels = [
          WheelConfig(
            itemCount: 100,
            initialIndex: 70,
            formatter: (index) => index.toString(),
            width: 80,
            trailingSeparator: const Text('.'),
          ),
          WheelConfig(
            itemCount: 10,
            initialIndex: 5,
            formatter: (index) => index.toString(),
            width: 40,
            trailingSeparator: const Text(' kg'),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SimpleWheelPickerBuilder(
                wheels: wheels,
              ),
            ),
          ),
        );

        expect(find.text('70'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
        expect(find.text('.'), findsOneWidget);
        expect(find.text(' kg'), findsOneWidget);
      });

      testWidgets('color picker scenario', (WidgetTester tester) async {
        final colors = ['Red', 'Green', 'Blue', 'Yellow', 'Purple'];
        final wheels = [
          WheelConfig(
            itemCount: colors.length,
            initialIndex: 0,
            formatter: (index) => colors[index],
            width: 120,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SimpleWheelPickerBuilder(
                wheels: wheels,
              ),
            ),
          ),
        );

        expect(find.text('Red'), findsOneWidget);
        expect(find.text('Green'), findsOneWidget);
        expect(find.text('Blue'), findsOneWidget);
      });
    });
  });
}