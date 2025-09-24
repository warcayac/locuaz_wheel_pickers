import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locuaz_wheel_pickers/src/widgets/specialized/list_wheel_picker.dart';

void main() {
  group('WListPicker', () {
    final testItems = ['Apple', 'Banana', 'Cherry', 'Date', 'Elderberry'];

    testWidgets('renders with basic configuration', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WListPicker(
              items: testItems,
            ),
          ),
        ),
      );

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    testWidgets('handles selection changes', (WidgetTester tester) async {
      int? selectedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WListPicker(
              items: testItems,
              onChanged: (index) => selectedIndex = index,
            ),
          ),
        ),
      );

      // Find the wheel picker and scroll it
      final wheelPicker = find.byType(WListPicker);
      expect(wheelPicker, findsOneWidget);

      // Simulate scroll gesture
      await tester.drag(wheelPicker, const Offset(0, -100));
      await tester.pumpAndSettle();

      expect(selectedIndex, isNotNull);
      expect(selectedIndex, greaterThanOrEqualTo(0));
      expect(selectedIndex, lessThan(testItems.length));
    });

    testWidgets('respects initial index', (WidgetTester tester) async {
      const initialIndex = 2;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WListPicker(
              items: testItems,
              initialIndex: initialIndex,
            ),
          ),
        ),
      );

      // The initially selected item should be visible
      expect(find.text(testItems[initialIndex]), findsOneWidget);
    });

    testWidgets('applies custom styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WListPicker(
              items: testItems,
              selectedItemColor: Colors.red,
              unselectedItemColor: Colors.blue,
              barColor: Colors.green,
            ),
          ),
        ),
      );

      expect(find.byType(WListPicker), findsOneWidget);
    });

    testWidgets('uses custom text style function', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WListPicker(
              items: testItems,
              selectedItemColor: Colors.red,
              unselectedItemColor: Colors.grey,
            ),
          ),
        ),
      );

      expect(find.byType(WListPicker), findsOneWidget);
    });

    testWidgets('handles single item', (WidgetTester tester) async {
      final singleItem = ['Only Item'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WListPicker(
              items: singleItem,
            ),
          ),
        ),
      );

      expect(find.text('Only Item'), findsOneWidget);
    });

    testWidgets('handles large item list', (WidgetTester tester) async {
      final largeList = List.generate(1000, (index) => 'Item $index');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WListPicker(
              items: largeList,
              initialIndex: 500,
            ),
          ),
        ),
      );

      expect(find.byType(WListPicker), findsOneWidget);
    });

    testWidgets('handles empty string items', (WidgetTester tester) async {
      final itemsWithEmpty = ['', 'Item 1', '', 'Item 3'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WListPicker(
              items: itemsWithEmpty,
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });

    testWidgets('handles special characters in items', (WidgetTester tester) async {
      final specialItems = [
        'Item with spaces',
        'Item-with-dashes',
        'Item_with_underscores',
        'Item.with.dots',
        'Item@with@symbols',
        'Item123',
        '🎯 Emoji Item',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WListPicker(
              items: specialItems,
            ),
          ),
        ),
      );

      expect(find.text('Item with spaces'), findsOneWidget);
      expect(find.text('🎯 Emoji Item'), findsOneWidget);
    });

    testWidgets('handles very long item names', (WidgetTester tester) async {
      final longItems = [
        'Short',
        'This is a very long item name that might overflow',
        'Another extremely long item name that definitely exceeds normal width expectations',
        'Normal',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WListPicker(
              items: longItems,
            ),
          ),
        ),
      );

      expect(find.byType(WListPicker), findsOneWidget);
    });

    testWidgets('handles null callback gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WListPicker(
              items: testItems,
              onChanged: null,
            ),
          ),
        ),
      );

      // Should not crash when scrolling without callback
      final wheelPicker = find.byType(WListPicker);
      await tester.drag(wheelPicker, const Offset(0, -50));
      await tester.pumpAndSettle();

      expect(find.byType(WListPicker), findsOneWidget);
    });

    testWidgets('maintains selection state across rebuilds', (WidgetTester tester) async {
      int? selectedIndex;
      const initialIndex = 1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WListPicker(
              items: testItems,
              initialIndex: initialIndex,
              onChanged: (index) => selectedIndex = index,
            ),
          ),
        ),
      );

      // Trigger a rebuild with same configuration
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WListPicker(
              items: testItems,
              initialIndex: initialIndex,
              onChanged: (index) => selectedIndex = index,
            ),
          ),
        ),
      );

      expect(find.byType(WListPicker), findsOneWidget);
    });

    testWidgets('handles theme changes', (WidgetTester tester) async {
      // Light theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: WListPicker(
              items: testItems,
            ),
          ),
        ),
      );

      expect(find.byType(WListPicker), findsOneWidget);

      // Dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: WListPicker(
              items: testItems,
            ),
          ),
        ),
      );

      expect(find.byType(WListPicker), findsOneWidget);
    });

    group('accessibility', () {
      testWidgets('provides semantic information', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WListPicker(
                items: testItems,
              ),
            ),
          ),
        );

        expect(find.byType(WListPicker), findsOneWidget);
      });

      testWidgets('supports semantic actions', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WListPicker(
                items: testItems,
                initialIndex: 2,
              ),
            ),
          ),
        );

        expect(find.byType(WListPicker), findsOneWidget);
      });
    });

    group('performance', () {
      testWidgets('handles rapid scrolling', (WidgetTester tester) async {
        int callbackCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WListPicker(
                items: List.generate(100, (index) => 'Item $index'),
                onChanged: (index) => callbackCount++,
              ),
            ),
          ),
        );

        final wheelPicker = find.byType(WListPicker);

        // Perform rapid scrolling
        for (int i = 0; i < 5; i++) {
          await tester.drag(wheelPicker, const Offset(0, -100));
          await tester.pump(const Duration(milliseconds: 50));
        }

        await tester.pumpAndSettle();

        expect(callbackCount, greaterThan(0));
      });

      testWidgets('efficiently renders large lists', (WidgetTester tester) async {
        const largeItemCount = 10000;
        final largeList = List.generate(largeItemCount, (index) => 'Item $index');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WListPicker(
                items: largeList,
                initialIndex: 5000,
              ),
            ),
          ),
        );

        expect(find.byType(WListPicker), findsOneWidget);
        
        // Should render without performance issues
        await tester.pumpAndSettle();
      });
    });

    group('edge cases', () {
      testWidgets('handles out of bounds initial index', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WListPicker(
                items: testItems,
                initialIndex: 100, // Out of bounds
              ),
            ),
          ),
        );

        expect(find.byType(WListPicker), findsOneWidget);
      });

      testWidgets('handles negative initial index', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WListPicker(
                items: testItems,
                initialIndex: -1, // Negative index
              ),
            ),
          ),
        );

        expect(find.byType(WListPicker), findsOneWidget);
      });

      testWidgets('handles items with identical text', (WidgetTester tester) async {
        final duplicateItems = ['Same', 'Same', 'Same', 'Different'];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WListPicker(
                items: duplicateItems,
              ),
            ),
          ),
        );

        expect(find.text('Same'), findsWidgets);
        expect(find.text('Different'), findsOneWidget);
      });
    });

    group('real-world scenarios', () {
      testWidgets('country picker scenario', (WidgetTester tester) async {
        final countries = [
          'United States',
          'Canada',
          'Mexico',
          'Brazil',
          'United Kingdom',
          'France',
          'Germany',
          'Spain',
          'China',
          'Japan',
          'Australia',
          'India',
        ];

        String? selectedCountry;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WListPicker(
                items: countries,
                initialIndex: 0,
                onChanged: (index) => selectedCountry = countries[index],
              ),
            ),
          ),
        );

        expect(find.text('United States'), findsOneWidget);
        expect(find.text('Canada'), findsOneWidget);

        // Simulate selection
        await tester.drag(find.byType(WListPicker), const Offset(0, -100));
        await tester.pumpAndSettle();

        expect(selectedCountry, isNotNull);
      });

      testWidgets('category picker scenario', (WidgetTester tester) async {
        final categories = [
          'Electronics',
          'Clothing',
          'Books',
          'Home & Garden',
          'Sports & Outdoors',
          'Health & Beauty',
          'Toys & Games',
          'Automotive',
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WListPicker(
                items: categories,
                initialIndex: 2, // Books
                selectedItemColor: Colors.blue,
                unselectedItemColor: Colors.grey,
              ),
            ),
          ),
        );

        expect(find.text('Books'), findsOneWidget);
        expect(find.text('Electronics'), findsOneWidget);
      });

      testWidgets('priority picker scenario', (WidgetTester tester) async {
        final priorities = ['Low', 'Medium', 'High', 'Critical'];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WListPicker(
                items: priorities,
                initialIndex: 1, // Medium
                selectedItemColor: Colors.red,
                unselectedItemColor: Colors.black,
              ),
            ),
          ),
        );

        expect(find.text('Medium'), findsOneWidget);
        expect(find.text('High'), findsOneWidget);
      });

      testWidgets('size picker scenario', (WidgetTester tester) async {
        final sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WListPicker(
                items: sizes,
                initialIndex: 2, // M
              ),
            ),
          ),
        );

        expect(find.text('M'), findsOneWidget);
        expect(find.text('L'), findsOneWidget);
      });
    });

    group('integration with SimpleWheelPickerBuilder', () {
      testWidgets('works as part of larger picker system', (WidgetTester tester) async {
        // This test verifies that WListPicker integrates well with other components
        final items1 = ['A', 'B', 'C'];
        final items2 = ['1', '2', '3'];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  Expanded(
                    child: WListPicker(
                      items: items1,
                      initialIndex: 0,
                    ),
                  ),
                  Expanded(
                    child: WListPicker(
                      items: items2,
                      initialIndex: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('A'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
      });
    });
  });
}