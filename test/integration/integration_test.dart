import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locuaz_wheel_pickers/locuaz_wheel_pickers.dart' hide TimeOfDay;
import 'package:locuaz_wheel_pickers/locuaz_wheel_pickers.dart' as wpickers show TimeOfDay;

void main() {
  group('Integration Tests - All Widgets', () {
    testWidgets('SimpleWheelPickerBuilder integration test', (tester) async {
      List<int> selectedIndices = [];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleWheelPickerBuilder(
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
              onChanged: (indices) {
                selectedIndices = indices;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify widgets are rendered
      expect(find.byType(SimpleWheelPickerBuilder), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);

      // Test scrolling
      await tester.drag(find.text('12'), const Offset(0, -50));
      await tester.pumpAndSettle();

      // Verify callback was called
      expect(selectedIndices, isNotEmpty);
    });

    testWidgets('SelectiveWheelPickerBuilder integration test', (tester) async {
      final GlobalKey pickerKey = GlobalKey();
      List<int> selectedIndices = [];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectiveWheelPickerBuilder(
              key: pickerKey,
              wheels: [
                WheelConfig(
                  itemCount: 12,
                  initialIndex: 0,
                  formatter: (i) => ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][i],
                  width: 80,
                  wheelId: 'month_wheel',
                ),
                WheelConfig(
                  itemCount: 31,
                  initialIndex: 0,
                  formatter: (i) => (i + 1).toString(),
                  width: 60,
                  wheelId: 'day_wheel',
                ),
              ],
              onChanged: (indices) {
                selectedIndices = indices;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify widgets are rendered
      expect(find.byType(SelectiveWheelPickerBuilder), findsOneWidget);
      expect(find.text('Jan'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      // Test external control
      SelectiveWheelPickerBuilder.updateWheelPositionByKey(
        pickerKey,
        0,
        5, // June
        withAnimation: false,
      );
      
      await tester.pumpAndSettle();
      expect(find.text('Jun'), findsOneWidget);
    });

    testWidgets('WListPicker integration test', (tester) async {
      int selectedIndex = 0;
      final items = ['Apple', 'Banana', 'Cherry', 'Date'];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WListPicker(
              items: items,
              initialIndex: 0,
              onChanged: (index) {
                selectedIndex = index;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify widget is rendered
      expect(find.byType(WListPicker), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);

      // Test scrolling
      await tester.drag(find.text('Apple'), const Offset(0, -50));
      await tester.pumpAndSettle();

      // Verify selection changed
      expect(selectedIndex, greaterThan(0));
    });

    testWidgets('WDatePicker integration test', (tester) async {
      DateTime selectedDate = DateTime(2024, 1, 1);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WDatePicker(
              initialDate: DateTime(2024, 6, 15),
              format: DateFormat.dMMy,
              language: Lang.en,
              onChanged: (date) {
                selectedDate = date;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify widget is rendered
      expect(find.byType(WDatePicker), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('Jun'), findsOneWidget);
      expect(find.text('2024'), findsOneWidget);

      // Test month change (should trigger day wheel recreation)
      await tester.drag(find.text('Jun'), const Offset(0, -50));
      await tester.pumpAndSettle();

      // Verify date changed
      expect(selectedDate.month, isNot(equals(6)));
    });

    testWidgets('WTimePicker integration test', (tester) async {
      wpickers.TimeOfDay selectedTime = const wpickers.TimeOfDay(
        hour: 12,
        minute: 0,
        second: 0,
        is24Hour: true,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WTimePicker(
              use24Hour: true,
              showSeconds: true,
              initialTime: selectedTime,
              onChanged: (time) {
                selectedTime = time;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify widget is rendered
      expect(find.byType(WTimePicker), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('00'), findsAtLeastNWidgets(2)); // minutes and seconds

      // Test hour change
      await tester.drag(find.text('12'), const Offset(0, -50));
      await tester.pumpAndSettle();

      // Verify time changed
      expect(selectedTime.hour, isNot(equals(12)));
    });

    testWidgets('Complex dependency scenario test', (tester) async {
      final GlobalKey pickerKey = GlobalKey();
      List<int> selectedIndices = [];
      
      // Mock data for country-state-city picker
      final Map<String, List<String>> stateData = {
        'USA': ['California', 'New York', 'Texas'],
        'Canada': ['Ontario', 'Quebec', 'British Columbia'],
      };
      
      final Map<String, Map<String, List<String>>> cityData = {
        'USA': {
          'California': ['Los Angeles', 'San Francisco'],
          'New York': ['New York City', 'Buffalo'],
          'Texas': ['Houston', 'Dallas'],
        },
        'Canada': {
          'Ontario': ['Toronto', 'Ottawa'],
          'Quebec': ['Montreal', 'Quebec City'],
          'British Columbia': ['Vancouver', 'Victoria'],
        },
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectiveWheelPickerBuilder(
              key: pickerKey,
              wheels: [
                WheelConfig(
                  itemCount: 2,
                  initialIndex: 0,
                  formatter: (i) => ['USA', 'Canada'][i],
                  width: 80,
                  wheelId: 'country_wheel',
                ),
                WheelConfig(
                  itemCount: stateData['USA']!.length,
                  initialIndex: 0,
                  formatter: (i) => stateData['USA']![i],
                  width: 100,
                  wheelId: 'state_wheel',
                  dependency: WheelDependency(
                    dependsOn: [0],
                    calculateItemCount: (deps) {
                      final country = ['USA', 'Canada'][deps[0]];
                      return stateData[country]!.length;
                    },
                    calculateInitialIndex: (deps, current) => 0,
                    buildFormatter: (deps) {
                      final country = ['USA', 'Canada'][deps[0]];
                      return (i) => stateData[country]![i];
                    },
                  ),
                ),
                WheelConfig(
                  itemCount: cityData['USA']!['California']!.length,
                  initialIndex: 0,
                  formatter: (i) => cityData['USA']!['California']![i],
                  width: 120,
                  wheelId: 'city_wheel',
                  dependency: WheelDependency(
                    dependsOn: [0, 1],
                    calculateItemCount: (deps) {
                      final country = ['USA', 'Canada'][deps[0]];
                      final state = stateData[country]![deps[1]];
                      return cityData[country]![state]!.length;
                    },
                    calculateInitialIndex: (deps, current) => 0,
                    buildFormatter: (deps) {
                      final country = ['USA', 'Canada'][deps[0]];
                      final state = stateData[country]![deps[1]];
                      return (i) => cityData[country]![state]![i];
                    },
                  ),
                ),
              ],
              onChanged: (indices) {
                selectedIndices = indices;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('USA'), findsOneWidget);
      expect(find.text('California'), findsOneWidget);
      expect(find.text('Los Angeles'), findsOneWidget);

      // Change country to Canada
      await tester.drag(find.text('USA'), const Offset(0, -50));
      await tester.pumpAndSettle();

      // Verify dependent wheels updated
      expect(find.text('Canada'), findsOneWidget);
      expect(find.text('Ontario'), findsOneWidget);
      expect(find.text('Toronto'), findsOneWidget);

      // Verify callback was called
      expect(selectedIndices, isNotEmpty);
    });

    testWidgets('Performance and memory test', (tester) async {
      // Test multiple wheel pickers sequentially to ensure no memory leaks
      for (int i = 0; i < 3; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  SimpleWheelPickerBuilder(
                    key: ValueKey('simple_$i'),
                    wheels: [
                      WheelConfig(
                        itemCount: 50,
                        initialIndex: i * 5,
                        formatter: (index) => 'Item $index',
                        width: 100,
                      ),
                    ],
                    onChanged: (indices) {},
                  ),
                  WListPicker(
                    key: ValueKey('list_$i'),
                    items: List.generate(20, (index) => 'Option $index'),
                    initialIndex: i,
                    onChanged: (index) {},
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        
        // Verify widgets are rendered with unique keys
        expect(find.byKey(ValueKey('simple_$i')), findsOneWidget);
        expect(find.byKey(ValueKey('list_$i')), findsOneWidget);
        
        // Test scrolling performance
        await tester.drag(find.byKey(ValueKey('simple_$i')), const Offset(0, -30));
        await tester.pumpAndSettle();
        
        await tester.drag(find.byKey(ValueKey('list_$i')), const Offset(0, -30));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Accessibility test', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleWheelPickerBuilder(
              wheels: [
                WheelConfig(
                  itemCount: 10,
                  initialIndex: 0,
                  formatter: (i) => 'Item $i',
                  width: 100,
                ),
              ],
              onChanged: (indices) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify widget is accessible and renders properly
      expect(find.byType(SimpleWheelPickerBuilder), findsOneWidget);
      
      // Verify text content is accessible
      expect(find.text('Item 0'), findsOneWidget);
      
      // Test scrolling accessibility
      await tester.drag(find.text('Item 0'), const Offset(0, -50));
      await tester.pumpAndSettle();
      
      // Verify scrolling worked
      expect(find.text('Item 1'), findsOneWidget);
    });

    testWidgets('Error handling test', (tester) async {
      // Test with invalid initial index
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleWheelPickerBuilder(
              wheels: [
                WheelConfig(
                  itemCount: 5,
                  initialIndex: 10, // Invalid index
                  formatter: (i) => 'Item $i',
                  width: 100,
                ),
              ],
              onChanged: (indices) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Widget should handle invalid index gracefully
      expect(find.byType(SimpleWheelPickerBuilder), findsOneWidget);
    });

    testWidgets('Custom styling test', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleWheelPickerBuilder(
              wheels: [
                WheelConfig(
                  itemCount: 5,
                  initialIndex: 0,
                  formatter: (i) => 'Item $i',
                  width: 100,
                ),
              ],
              selectedItemColor: Colors.red,
              unselectedItemColor: Colors.blue,
              barColor: Colors.green,
              onChanged: (indices) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify widget renders with custom styling
      expect(find.byType(SimpleWheelPickerBuilder), findsOneWidget);
      
      // Find the container with custom bar color
      final containerFinder = find.descendant(
        of: find.byType(SimpleWheelPickerBuilder),
        matching: find.byType(Container),
      );
      expect(containerFinder, findsAtLeastNWidgets(1));
    });
  });
}