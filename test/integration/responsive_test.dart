import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locuaz_wheel_pickers/locuaz_wheel_pickers.dart' hide WTimeOfDay;
import 'package:locuaz_wheel_pickers/locuaz_wheel_pickers.dart' as wpickers show WTimeOfDay;

void main() {
  group('Responsive Design Tests', () {
    testWidgets('Widget renders properly on different screen sizes', (tester) async {
      // Test basic functionality without changing screen size
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SimpleWheelPickerBuilder(
                wheels: [
                  WheelConfig(
                    itemCount: 24,
                    initialIndex: 12,
                    formatter: (i) => i.toString().padLeft(2, '0'),
                    width: 60,
                  ),
                  WheelConfig(
                    itemCount: 60,
                    initialIndex: 30,
                    formatter: (i) => i.toString().padLeft(2, '0'),
                    width: 60,
                  ),
                ],
                onChanged: (indices) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify widget renders properly
      expect(find.byType(SimpleWheelPickerBuilder), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);

      // Test scrolling
      await tester.drag(find.text('12'), const Offset(0, -50));
      await tester.pumpAndSettle();
      
      // Verify scrolling works
      expect(find.text('13'), findsOneWidget);
    });

    testWidgets('Date picker responsive behavior', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: WDatePicker(
                initialDate: DateTime(2024, 6, 15),
                format: EDateFormat.dMMy,
                language: Lang.en,
                onChanged: (date) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify widget renders properly
      expect(find.byType(WDatePicker), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('Jun'), findsOneWidget);
      expect(find.text('2024'), findsOneWidget);

      // Test interaction
      await tester.drag(find.text('Jun'), const Offset(0, -50));
      await tester.pumpAndSettle();
      
      // Verify month changed
      expect(find.text('Jul'), findsOneWidget);
    });

    testWidgets('Multiple widgets layout test', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  WListPicker(
                    key: const ValueKey('list_picker'),
                    items: const ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
                    initialIndex: 0,
                    onChanged: (index) {},
                  ),
                  WTimePicker(
                    key: const ValueKey('time_picker'),
                    use24Hour: true,
                    showSeconds: true,
                    initialTime: const wpickers.WTimeOfDay(
                      hour: 12,
                      minute: 0,
                      second: 0,
                      is24Hour: true,
                    ),
                    onChanged: (time) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify widgets render properly
      expect(find.byKey(const ValueKey('list_picker')), findsOneWidget);
      expect(find.byKey(const ValueKey('time_picker')), findsOneWidget);
      expect(find.text('Option 1'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);

      // Test multiple widget interaction
      await tester.drag(find.text('Option 1'), const Offset(0, -50));
      await tester.pumpAndSettle();
      
      await tester.drag(find.text('12'), const Offset(0, -50));
      await tester.pumpAndSettle();
      
      // Verify both widgets responded
      expect(find.text('Option 2'), findsOneWidget);
      expect(find.text('13'), findsOneWidget);
    });

    testWidgets('Constrained space layout test', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  SimpleWheelPickerBuilder(
                    key: const ValueKey('month_picker'),
                    wheels: [
                      WheelConfig(
                        itemCount: 12,
                        initialIndex: 0,
                        formatter: (i) => ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][i],
                        width: 80,
                      ),
                    ],
                    onChanged: (indices) {},
                  ),
                  const SizedBox(height: 20),
                  WListPicker(
                    key: const ValueKey('letter_picker'),
                    items: const ['A', 'B', 'C', 'D', 'E'],
                    initialIndex: 0,
                    onChanged: (index) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify widgets render properly in constrained space
      expect(find.byKey(const ValueKey('month_picker')), findsOneWidget);
      expect(find.byKey(const ValueKey('letter_picker')), findsOneWidget);
      expect(find.text('Jan'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);

      // Test scrolling in constrained space
      await tester.drag(find.text('Jan'), const Offset(0, -30));
      await tester.pumpAndSettle();
      
      expect(find.text('Feb'), findsOneWidget);
    });

    testWidgets('Dynamic width adjustment test', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SimpleWheelPickerBuilder(
                wheels: [
                  WheelConfig(
                    itemCount: 10,
                    initialIndex: 0,
                    formatter: (i) => 'Very Long Item Name $i',
                    width: 150, // Wider wheel for long text
                  ),
                  WheelConfig(
                    itemCount: 10,
                    initialIndex: 0,
                    formatter: (i) => '$i',
                    width: 40, // Narrow wheel for short text
                  ),
                ],
                onChanged: (indices) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify widgets with different widths render properly
      expect(find.byType(SimpleWheelPickerBuilder), findsOneWidget);
      expect(find.text('Very Long Item Name 0'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);

      // Test scrolling with different wheel widths
      await tester.drag(find.text('Very Long Item Name 0'), const Offset(0, -50));
      await tester.pumpAndSettle();
      
      expect(find.text('Very Long Item Name 1'), findsOneWidget);
    });
  });
}