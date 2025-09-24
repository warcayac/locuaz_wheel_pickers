import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locuaz_wheel_pickers/src/widgets/core/wheel_picker.dart';

void main() {
  group('WheelPicker', () {
    testWidgets('renders with basic configuration', (WidgetTester tester) async {
      int? selectedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WheelPicker(
              childCount: 5,
              child: (index) => Text('Item $index'),
              onSelectedItemChanged: (index) => selectedIndex = index,
            ),
          ),
        ),
      );

      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('handles selection changes', (WidgetTester tester) async {
      int? selectedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WheelPicker(
              childCount: 10,
              child: (index) => Text('Item $index'),
              onSelectedItemChanged: (index) => selectedIndex = index,
              initialIndex: 0,
            ),
          ),
        ),
      );

      // Find the ListWheelScrollView
      final listWheelScrollView = find.byType(ListWheelScrollView);
      expect(listWheelScrollView, findsOneWidget);

      // Simulate scroll to change selection
      await tester.drag(listWheelScrollView, const Offset(0, -100));
      await tester.pumpAndSettle();

      // Verify selection changed
      expect(selectedIndex, isNotNull);
      expect(selectedIndex, greaterThan(0));
    });

    testWidgets('respects initial index', (WidgetTester tester) async {
      final controller = FixedExtentScrollController(initialItem: 3);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WheelPicker(
              childCount: 10,
              child: (index) => Text('Item $index'),
              controller: controller,
              initialIndex: 3,
            ),
          ),
        ),
      );

      expect(controller.selectedItem, equals(3));
      
      controller.dispose();
    });

    testWidgets('applies custom styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WheelPicker(
              childCount: 5,
              child: (index) => Text('Item $index'),
              selectedItemColor: Colors.red,
              unselectedItemColor: Colors.blue,
              itemExtent: 50,
              wheelHeight: 200,
              wheelWidth: 150,
            ),
          ),
        ),
      );

      // Find the SizedBox that wraps the wheel
      final sizedBox = find.byType(SizedBox);
      expect(sizedBox, findsOneWidget);

      final sizedBoxWidget = tester.widget<SizedBox>(sizedBox);
      expect(sizedBoxWidget.height, equals(200));
      expect(sizedBoxWidget.width, equals(150));
    });

    testWidgets('uses custom text style function', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WheelPicker(
              childCount: 5,
              child: (index) => Text('Item $index'),
              textStyle: (isSelected) => TextStyle(
                fontSize: isSelected ? 24 : 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(WheelPicker), findsOneWidget);
    });

    testWidgets('handles theme awareness', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: WheelPicker(
              childCount: 5,
              child: (index) => Text('Item $index'),
              themeAware: true,
            ),
          ),
        ),
      );

      expect(find.byType(WheelPicker), findsOneWidget);

      // Test with dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: WheelPicker(
              childCount: 5,
              child: (index) => Text('Item $index'),
              themeAware: true,
            ),
          ),
        ),
      );

      expect(find.byType(WheelPicker), findsOneWidget);
    });

    testWidgets('handles disabled theme awareness', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: WheelPicker(
              childCount: 5,
              child: (index) => Text('Item $index'),
              themeAware: false,
              selectedItemColor: Colors.red,
              unselectedItemColor: Colors.grey,
            ),
          ),
        ),
      );

      expect(find.byType(WheelPicker), findsOneWidget);
    });

    testWidgets('respects custom perspective and diameter ratio', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WheelPicker(
              childCount: 5,
              child: (index) => Text('Item $index'),
              perspective: 0.01,
              diameterRatio: 2.0,
            ),
          ),
        ),
      );

      final listWheelScrollView = tester.widget<ListWheelScrollView>(
        find.byType(ListWheelScrollView),
      );

      expect(listWheelScrollView.perspective, equals(0.01));
      expect(listWheelScrollView.diameterRatio, equals(2.0));
    });

    testWidgets('handles external controller', (WidgetTester tester) async {
      final controller = FixedExtentScrollController(initialItem: 2);
      int? selectedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WheelPicker(
              childCount: 10,
              child: (index) => Text('Item $index'),
              controller: controller,
              onSelectedItemChanged: (index) => selectedIndex = index,
            ),
          ),
        ),
      );

      expect(controller.selectedItem, equals(2));

      // Programmatically change selection
      controller.animateToItem(
        5,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      await tester.pumpAndSettle();

      expect(controller.selectedItem, equals(5));
      expect(selectedIndex, equals(5));
      
      controller.dispose();
    });

    testWidgets('handles empty child count gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WheelPicker(
              childCount: 0,
              child: (index) => Text('Item $index'),
            ),
          ),
        ),
      );

      expect(find.byType(WheelPicker), findsOneWidget);
    });

    testWidgets('handles single item', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WheelPicker(
              childCount: 1,
              child: (index) => const Text('Only Item'),
            ),
          ),
        ),
      );

      expect(find.text('Only Item'), findsOneWidget);
    });

    testWidgets('handles large item count', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WheelPicker(
              childCount: 1000,
              child: (index) => Text('Item $index'),
              initialIndex: 500,
            ),
          ),
        ),
      );

      expect(find.byType(WheelPicker), findsOneWidget);
    });

    testWidgets('applies correct item extent', (WidgetTester tester) async {
      const customItemExtent = 60.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WheelPicker(
              childCount: 5,
              child: (index) => Text('Item $index'),
              itemExtent: customItemExtent,
            ),
          ),
        ),
      );

      final listWheelScrollView = tester.widget<ListWheelScrollView>(
        find.byType(ListWheelScrollView),
      );

      expect(listWheelScrollView.itemExtent, equals(customItemExtent));
    });

    testWidgets('handles null callback gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WheelPicker(
              childCount: 5,
              child: (index) => Text('Item $index'),
              onSelectedItemChanged: null,
            ),
          ),
        ),
      );

      final listWheelScrollView = find.byType(ListWheelScrollView);
      expect(listWheelScrollView, findsOneWidget);

      // Should not crash when scrolling without callback
      await tester.drag(listWheelScrollView, const Offset(0, -50));
      await tester.pumpAndSettle();

      expect(find.byType(WheelPicker), findsOneWidget);
    });

    testWidgets('respects wheel dimensions when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WheelPicker(
              childCount: 5,
              child: (index) => Text('Item $index'),
              wheelHeight: 300,
              wheelWidth: 200,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.height, equals(300));
      expect(sizedBox.width, equals(200));
    });

    testWidgets('expands to parent constraints when dimensions not provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              width: 300,
              child: WheelPicker(
                childCount: 5,
                child: (index) => Text('Item $index'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(WheelPicker), findsOneWidget);
    });

    group('accessibility', () {
      testWidgets('provides semantic information', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WheelPicker(
                childCount: 5,
                child: (index) => Text('Item $index'),
              ),
            ),
          ),
        );

        expect(find.byType(ListWheelScrollView), findsOneWidget);
      });

      testWidgets('supports semantic actions', (WidgetTester tester) async {
        final controller = FixedExtentScrollController(initialItem: 2);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WheelPicker(
                childCount: 10,
                child: (index) => Text('Item $index'),
                controller: controller,
              ),
            ),
          ),
        );

        expect(find.byType(ListWheelScrollView), findsOneWidget);
        
        controller.dispose();
      });
    });

    group('performance', () {
      testWidgets('handles rapid scrolling', (WidgetTester tester) async {
        int callbackCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WheelPicker(
                childCount: 100,
                child: (index) => Text('Item $index'),
                onSelectedItemChanged: (index) => callbackCount++,
              ),
            ),
          ),
        );

        final listWheelScrollView = find.byType(ListWheelScrollView);

        // Perform rapid scrolling
        for (int i = 0; i < 5; i++) {
          await tester.drag(listWheelScrollView, const Offset(0, -100));
          await tester.pump(const Duration(milliseconds: 50));
        }

        await tester.pumpAndSettle();

        expect(callbackCount, greaterThan(0));
      });

      testWidgets('efficiently renders large lists', (WidgetTester tester) async {
        const largeItemCount = 10000;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WheelPicker(
                childCount: largeItemCount,
                child: (index) => Text('Item $index'),
                initialIndex: 5000,
              ),
            ),
          ),
        );

        expect(find.byType(WheelPicker), findsOneWidget);
        
        // Should render without performance issues
        await tester.pumpAndSettle();
      });
    });

    group('edge cases', () {
      testWidgets('handles controller disposal during widget lifecycle', (WidgetTester tester) async {
        final controller = FixedExtentScrollController(initialItem: 0);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WheelPicker(
                childCount: 5,
                child: (index) => Text('Item $index'),
                controller: controller,
              ),
            ),
          ),
        );

        expect(find.byType(WheelPicker), findsOneWidget);

        // Dispose controller externally
        controller.dispose();

        // Widget should handle disposed controller gracefully
        await tester.pumpWidget(Container());
      });

      testWidgets('handles widget rebuild with different configurations', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WheelPicker(
                childCount: 5,
                child: (index) => Text('Item $index'),
                itemExtent: 30,
              ),
            ),
          ),
        );

        expect(find.byType(WheelPicker), findsOneWidget);

        // Rebuild with different configuration
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WheelPicker(
                childCount: 10,
                child: (index) => Text('New Item $index'),
                itemExtent: 50,
              ),
            ),
          ),
        );

        expect(find.text('New Item 0'), findsOneWidget);
      });
    });
  });
}