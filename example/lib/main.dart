import 'package:flutter/material.dart';
import 'package:locuaz_wheel_pickers/locuaz_wheel_pickers.dart' hide TimeOfDay;
import 'package:locuaz_wheel_pickers/locuaz_wheel_pickers.dart' as wpickers show TimeOfDay;

/// Example app demonstrating Locuaz Wheel Pickers usage
void main() {
  runApp(const MyApp());
}

/// Main application widget
class MyApp extends StatelessWidget {
  /// Creates the main application widget
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Locuaz Wheel Pickers Example',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    ),
    home: const ExampleHomePage(),
  );
}

/// Home page widget with navigation to different examples
class ExampleHomePage extends StatelessWidget {
  /// Creates the home page widget
  const ExampleHomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: const Text('Locuaz Wheel Pickers Demo'),
      centerTitle: true,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Locuaz Wheel Pickers',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'iOS-style wheel picker widgets for Flutter',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          const Text(
            'Basic Examples',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            title: 'Simple Wheel Picker',
            description: 'Basic static wheel picker implementation',
            icon: Icons.view_carousel,
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const SimpleWheelExamplePage(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Selective Wheel Picker',
            description: 'Dynamic wheel picker with selective recreation',
            icon: Icons.dynamic_form,
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const SelectiveWheelExamplePage(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'List Wheel Picker',
            description: 'Simple list selection wheel picker',
            icon: Icons.list,
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const ListWheelExamplePage(),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Advanced Examples',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            title: 'Date Picker',
            description: 'Date picker with month-day dependencies',
            icon: Icons.calendar_today,
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const DatePickerExamplePage(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Time Picker',
            description: 'Time picker with hour-minute-second wheels',
            icon: Icons.access_time,
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const TimePickerExamplePage(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Complex Dependencies',
            description: 'Country-State-City picker with dependencies',
            icon: Icons.location_on,
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const ComplexDependencyExamplePage(),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildExampleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      Card(
        elevation: 2,
        child: ListTile(
          leading: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            description,
            style: const TextStyle(fontSize: 14),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
      );
}

// Placeholder pages for examples (will be implemented in subsequent tasks)

/// Simple wheel picker example page
class SimpleWheelExamplePage extends StatefulWidget {
  /// Creates the simple wheel example page
  const SimpleWheelExamplePage({super.key});

  @override
  State<SimpleWheelExamplePage> createState() => _SimpleWheelExamplePageState();
}

class _SimpleWheelExamplePageState extends State<SimpleWheelExamplePage> {
  String _selectedTime = '00:00';
  String _selectedDate = 'January 1';
  List<int> _customSelection = [0, 0, 0];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Simple Wheel Picker'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildExampleCard(
            title: 'Time Picker',
            description: 'Simple hour:minute picker using static wheels',
            selectedValue: _selectedTime,
            child: SimpleWheelPickerBuilder(
              wheels: [
                WheelConfig(
                  itemCount: 24,
                  initialIndex: 0,
                  formatter: (i) => i.toString().padLeft(2, '0'),
                  width: 60,
                  trailingSeparator: const Text(
                    ':',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                WheelConfig(
                  itemCount: 60,
                  initialIndex: 0,
                  formatter: (i) => i.toString().padLeft(2, '0'),
                  width: 60,
                ),
              ],
              onChanged: (indices) {
                setState(() {
                  _selectedTime = 
                      '${indices[0].toString().padLeft(2, '0')}:'
                      '${indices[1].toString().padLeft(2, '0')}';
                });
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildExampleCard(
            title: 'Month-Day Picker',
            description: 'Static month and day selection',
            selectedValue: _selectedDate,
            child: SimpleWheelPickerBuilder(
              wheels: [
                WheelConfig(
                  itemCount: 12,
                  initialIndex: 0,
                  formatter: (i) => [
                    'January', 'February', 'March', 'April',
                    'May', 'June', 'July', 'August',
                    'September', 'October', 'November', 'December'
                  ][i],
                  width: 120,
                ),
                WheelConfig(
                  itemCount: 31,
                  initialIndex: 0,
                  formatter: (i) => (i + 1).toString(),
                  width: 60,
                ),
              ],
              onChanged: (indices) {
                final months = [
                  'January', 'February', 'March', 'April',
                  'May', 'June', 'July', 'August',
                  'September', 'October', 'November', 'December'
                ];
                setState(() {
                  _selectedDate = '${months[indices[0]]} ${indices[1] + 1}';
                });
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildExampleCard(
            title: 'Custom Multi-Wheel',
            description: 'Three custom wheels with different configurations',
            selectedValue: 'Selection: ${_customSelection.join(', ')}',
            child: SimpleWheelPickerBuilder(
              wheels: [
                WheelConfig(
                  itemCount: 5,
                  initialIndex: 0,
                  formatter: (i) => 'A${i + 1}',
                  width: 50,
                ),
                WheelConfig(
                  itemCount: 10,
                  initialIndex: 0,
                  formatter: (i) => 'B${i + 1}',
                  width: 50,
                ),
                WheelConfig(
                  itemCount: 3,
                  initialIndex: 0,
                  formatter: (i) => 'C${i + 1}',
                  width: 50,
                ),
              ],
              selectedItemColor: Colors.blue,
              barColor: Colors.blue.withValues(alpha: 0.1),
              onChanged: (indices) {
                setState(() {
                  _customSelection = indices;
                });
              },
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildExampleCard({
    required String title,
    required String description,
    required String selectedValue,
    required Widget child,
  }) =>
      Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selected: $selectedValue',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              Center(child: child),
            ],
          ),
        ),
      );
}

/// Selective wheel picker example page
class SelectiveWheelExamplePage extends StatefulWidget {
  /// Creates the selective wheel example page
  const SelectiveWheelExamplePage({super.key});

  @override
  State<SelectiveWheelExamplePage> createState() => _SelectiveWheelExamplePageState();
}

class _SelectiveWheelExamplePageState extends State<SelectiveWheelExamplePage> {
  final GlobalKey _pickerKey = GlobalKey();
  String _selectedDate = 'January 1, 2024';
  String _selectedTime = '12:00:00';
  int _currentYear = 2024;
  int _currentMonth = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Selective Wheel Picker'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildExampleCard(
                title: 'Dynamic Date Picker',
                description: 'Day wheel updates based on month/year selection',
                selectedValue: _selectedDate,
                child: SelectiveWheelPickerBuilder(
                  key: _pickerKey,
                  wheels: [
                    WheelConfig(
                      itemCount: _getDaysInMonth(_currentYear, _currentMonth),
                      initialIndex: 0,
                      formatter: (i) => (i + 1).toString(),
                      width: 60,
                      wheelId: 'day_wheel',
                    ),
                    WheelConfig(
                      itemCount: 12,
                      initialIndex: 0,
                      formatter: (i) => [
                        'Jan', 'Feb', 'Mar', 'Apr',
                        'May', 'Jun', 'Jul', 'Aug',
                        'Sep', 'Oct', 'Nov', 'Dec'
                      ][i],
                      width: 60,
                      wheelId: 'month_wheel',
                    ),
                    WheelConfig(
                      itemCount: 50,
                      initialIndex: 24, // 2024
                      formatter: (i) => (2000 + i).toString(),
                      width: 80,
                      wheelId: 'year_wheel',
                    ),
                  ],
                  onChanged: (indices) {
                    final day = indices[0] + 1;
                    final month = indices[1];
                    final year = 2000 + indices[2];
                    
                    // Update day wheel if month or year changed
                    if (month != _currentMonth || year != _currentYear) {
                      _currentMonth = month;
                      _currentYear = year;
                      
                      final daysInMonth = _getDaysInMonth(year, month);
                      final newDayIndex = (day - 1).clamp(0, daysInMonth - 1);
                      
                      SelectiveWheelPickerBuilder.recreateWheelByKey(
                        _pickerKey,
                        0,
                        WheelConfig(
                          itemCount: daysInMonth,
                          initialIndex: newDayIndex,
                          formatter: (i) => (i + 1).toString(),
                          width: 60,
                          wheelId: 'day_wheel_${month}_$year',
                        ),
                      );
                    }
                    
                    final months = [
                      'January', 'February', 'March', 'April',
                      'May', 'June', 'July', 'August',
                      'September', 'October', 'November', 'December'
                    ];
                    
                    setState(() {
                      _selectedDate = '${months[month]} $day, $year';
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              _buildExampleCard(
                title: 'Time Picker with Seconds',
                description: 'Independent wheels with selective updates',
                selectedValue: _selectedTime,
                child: SelectiveWheelPickerBuilder(
                  wheels: [
                    WheelConfig(
                      itemCount: 24,
                      initialIndex: 12,
                      formatter: (i) => i.toString().padLeft(2, '0'),
                      width: 60,
                      wheelId: 'hour_wheel',
                      trailingSeparator: const Text(
                        ':',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    WheelConfig(
                      itemCount: 60,
                      initialIndex: 0,
                      formatter: (i) => i.toString().padLeft(2, '0'),
                      width: 60,
                      wheelId: 'minute_wheel',
                      trailingSeparator: const Text(
                        ':',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    WheelConfig(
                      itemCount: 60,
                      initialIndex: 0,
                      formatter: (i) => i.toString().padLeft(2, '0'),
                      width: 60,
                      wheelId: 'second_wheel',
                    ),
                  ],
                  selectedItemColor: Colors.green,
                  barColor: Colors.green.withValues(alpha: 0.1),
                  onChanged: (indices) {
                    setState(() {
                      _selectedTime = '${indices[0].toString().padLeft(2, '0')}:'
                          '${indices[1].toString().padLeft(2, '0')}:'
                          '${indices[2].toString().padLeft(2, '0')}';
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              _buildControlButtons(),
            ],
          ),
        ),
      );

  Widget _buildExampleCard({
    required String title,
    required String description,
    required String selectedValue,
    required Widget child,
  }) =>
      Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selected: $selectedValue',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              Center(child: child),
            ],
          ),
        ),
      );

  Widget _buildControlButtons() => Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'External Control Demo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'These buttons demonstrate external control of the date picker',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: () => _setToToday(),
                    child: const Text('Set to Today'),
                  ),
                  ElevatedButton(
                    onPressed: () => _setToNewYear(),
                    child: const Text('Set to New Year'),
                  ),
                  ElevatedButton(
                    onPressed: () => _setToRandomDate(),
                    child: const Text('Random Date'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  void _setToToday() {
    final now = DateTime.now();
    SelectiveWheelPickerBuilder.updateMultipleWheelPositionsByKey(
      _pickerKey,
      {
        0: now.day - 1,
        1: now.month - 1,
        2: now.year - 2000,
      },
      withAnimation: true,
    );
  }

  void _setToNewYear() {
    SelectiveWheelPickerBuilder.updateMultipleWheelPositionsByKey(
      _pickerKey,
      {
        0: 0, // January 1st
        1: 0,
        2: 25, // 2025
      },
      withAnimation: true,
    );
  }

  void _setToRandomDate() {
    final random = DateTime.now().millisecondsSinceEpoch % 1000;
    SelectiveWheelPickerBuilder.updateMultipleWheelPositionsByKey(
      _pickerKey,
      {
        0: random % 28, // Safe day range
        1: random % 12,
        2: 20 + (random % 30), // 2020-2049
      },
      withAnimation: true,
    );
  }

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}

/// List wheel picker example page
class ListWheelExamplePage extends StatefulWidget {
  /// Creates the list wheel example page
  const ListWheelExamplePage({super.key});

  @override
  State<ListWheelExamplePage> createState() => _ListWheelExamplePageState();
}

class _ListWheelExamplePageState extends State<ListWheelExamplePage> {
  String _selectedCountry = 'United States';
  String _selectedFruit = 'Apple';
  String _selectedColor = 'Red';

  final List<String> _countries = [
    'United States', 'Canada', 'Mexico', 'Brazil', 'Argentina',
    'United Kingdom', 'France', 'Germany', 'Spain', 'Italy',
    'China', 'Japan', 'South Korea', 'India', 'Australia',
    'Russia', 'South Africa', 'Egypt', 'Nigeria', 'Kenya',
  ];

  final List<String> _fruits = [
    'Apple', 'Banana', 'Cherry', 'Date', 'Elderberry',
    'Fig', 'Grape', 'Honeydew', 'Kiwi', 'Lemon',
    'Mango', 'Orange', 'Papaya', 'Quince', 'Raspberry',
    'Strawberry', 'Tangerine', 'Watermelon',
  ];

  final List<String> _colors = [
    'Red', 'Blue', 'Green', 'Yellow', 'Orange',
    'Purple', 'Pink', 'Brown', 'Black', 'White',
    'Gray', 'Cyan', 'Magenta', 'Lime', 'Indigo',
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('List Wheel Picker'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildExampleCard(
                title: 'Country Selector',
                description: 'Choose from a list of countries',
                selectedValue: _selectedCountry,
                child: WListPicker(
                  items: _countries,
                  initialIndex: 0,
                  onChanged: (index) {
                    setState(() {
                      _selectedCountry = _countries[index];
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              _buildExampleCard(
                title: 'Fruit Picker',
                description: 'Select your favorite fruit',
                selectedValue: _selectedFruit,
                child: WListPicker(
                  items: _fruits,
                  initialIndex: 0,
                  selectedItemColor: Colors.orange,
                  barColor: Colors.orange.withValues(alpha: 0.1),
                  onChanged: (index) {
                    setState(() {
                      _selectedFruit = _fruits[index];
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              _buildExampleCard(
                title: 'Color Selector',
                description: 'Pick a color with custom styling',
                selectedValue: _selectedColor,
                child: WListPicker(
                  items: _colors,
                  initialIndex: 0,
                  selectedItemColor: Colors.purple,
                  unselectedItemColor: Colors.grey,
                  barColor: Colors.purple.withValues(alpha: 0.15),
                  onChanged: (index) {
                    setState(() {
                      _selectedColor = _colors[index];
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              _buildUsageExample(),
            ],
          ),
        ),
      );

  Widget _buildExampleCard({
    required String title,
    required String description,
    required String selectedValue,
    required Widget child,
  }) =>
      Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selected: $selectedValue',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              Center(child: child),
            ],
          ),
        ),
      );

  Widget _buildUsageExample() => Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Usage Example',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'WListPicker is the simplest way to create a wheel picker:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  r'''WListPicker(
  items: ['Option 1', 'Option 2', 'Option 3'],
  onChanged: (index) {
    print('Selected: ${items[index]}');
  },
)''',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Current selections: $_selectedCountry, '
                '$_selectedFruit, $_selectedColor',
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
}

/// Date picker example page
class DatePickerExamplePage extends StatefulWidget {
  /// Creates the date picker example page
  const DatePickerExamplePage({super.key});

  @override
  State<DatePickerExamplePage> createState() => _DatePickerExamplePageState();
}

class _DatePickerExamplePageState extends State<DatePickerExamplePage> {
  DateTime _selectedDate1 = DateTime.now();
  DateTime _selectedDate2 = DateTime(2024, 1, 1);
  DateTime _selectedDate3 = DateTime(2025, 6, 15);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Date Picker'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildExampleCard(
                title: 'Default Date Picker',
                description: 'Day-Month-Year with abbreviated month names',
                selectedValue: _formatDate(_selectedDate1),
                child: WDatePicker(
                  initialDate: _selectedDate1,
                  format: DateFormat.dMMy,
                  language: Lang.en,
                  showSeparator: true,
                  onChanged: (date) {
                    setState(() {
                      _selectedDate1 = date;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              _buildExampleCard(
                title: 'Full Month Names',
                description: 'Date picker with full month names in Spanish',
                selectedValue: _formatDate(_selectedDate2),
                child: WDatePicker(
                  initialDate: _selectedDate2,
                  format: DateFormat.dMMMy,
                  language: Lang.es,
                  showSeparator: false,
                  selectedItemColor: Colors.green,
                  barColor: Colors.green.withValues(alpha: 0.1),
                  onChanged: (date) {
                    setState(() {
                      _selectedDate2 = date;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              _buildExampleCard(
                title: 'Month-Year Only',
                description: 'Date picker without day wheel',
                selectedValue: _formatMonthYear(_selectedDate3),
                child: WDatePicker(
                  initialDate: _selectedDate3,
                  format: DateFormat.xMMMy,
                  language: Lang.en,
                  startYear: 2020,
                  endYear: 2030,
                  selectedItemColor: Colors.purple,
                  barColor: Colors.purple.withValues(alpha: 0.1),
                  onChanged: (date) {
                    setState(() {
                      _selectedDate3 = date;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              _buildFeatureCard(),
            ],
          ),
        ),
      );

  Widget _buildExampleCard({
    required String title,
    required String description,
    required String selectedValue,
    required Widget child,
  }) =>
      Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selected: $selectedValue',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              Center(child: child),
            ],
          ),
        ),
      );

  Widget _buildFeatureCard() => Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Smart Date Handling',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The date picker automatically handles:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              _buildFeatureItem('• Different month lengths (28-31 days)'),
              _buildFeatureItem('• Leap year calculations'),
              _buildFeatureItem('• Invalid date adjustments (Feb 31 → Feb 28)'),
              _buildFeatureItem('• Smooth day wheel recreation'),
              _buildFeatureItem('• Multiple language support'),
              const SizedBox(height: 12),
              const Text(
                'Try changing months to see the day wheel update automatically!',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildFeatureItem(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          text,
          style: const TextStyle(fontSize: 14),
        ),
      );

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatMonthYear(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

/// Time picker example page
class TimePickerExamplePage extends StatefulWidget {
  /// Creates the time picker example page
  const TimePickerExamplePage({super.key});

  @override
  State<TimePickerExamplePage> createState() => _TimePickerExamplePageState();
}

class _TimePickerExamplePageState extends State<TimePickerExamplePage> {
  wpickers.TimeOfDay _selectedTime1 = wpickers.TimeOfDay(
    hour: DateTime.now().hour,
    minute: DateTime.now().minute,
    second: DateTime.now().second,
    is24Hour: true,
  );
  
  wpickers.TimeOfDay _selectedTime2 = const wpickers.TimeOfDay(
    hour: 14,
    minute: 30,
    second: 0,
    is24Hour: false,
  );
  
  wpickers.TimeOfDay _selectedTime3 = const wpickers.TimeOfDay(
    hour: 9,
    minute: 15,
    second: 45,
    is24Hour: true,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Time Picker'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildExampleCard(
                title: '24-Hour Format',
                description: 'Hour:Minute:Second in 24-hour format',
                selectedValue: _selectedTime1.toString(),
                child: WTimePicker(
                  use24Hour: true,
                  showSeconds: true,
                  showSeparator: true,
                  initialTime: _selectedTime1,
                  onChanged: (time) {
                    setState(() {
                      _selectedTime1 = time;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              _buildExampleCard(
                title: '12-Hour Format with AM/PM',
                description: 'Hour:Minute with AM/PM selector',
                selectedValue: _selectedTime2.toString(),
                child: WTimePicker(
                  use24Hour: false,
                  showSeconds: false,
                  showSeparator: true,
                  initialTime: _selectedTime2,
                  selectedItemColor: Colors.orange,
                  barColor: Colors.orange.withValues(alpha: 0.1),
                  onChanged: (time) {
                    setState(() {
                      _selectedTime2 = time;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              _buildExampleCard(
                title: 'Precise Time Selection',
                description: '24-hour format with seconds, no separators',
                selectedValue: _selectedTime3.toString(),
                child: WTimePicker(
                  use24Hour: true,
                  showSeconds: true,
                  showSeparator: false,
                  initialTime: _selectedTime3,
                  selectedItemColor: Colors.teal,
                  unselectedItemColor: Colors.grey,
                  barColor: Colors.teal.withValues(alpha: 0.15),
                  onChanged: (time) {
                    setState(() {
                      _selectedTime3 = time;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              _buildComparisonCard(),
            ],
          ),
        ),
      );

  Widget _buildExampleCard({
    required String title,
    required String description,
    required String selectedValue,
    required Widget child,
  }) =>
      Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selected: $selectedValue',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              Center(child: child),
            ],
          ),
        ),
      );

  Widget _buildComparisonCard() => Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Format Comparison',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildComparisonRow('24-Hour Format:', _selectedTime1.toString()),
              _buildComparisonRow('12-Hour Format:', _selectedTime2.toString()),
              _buildComparisonRow('With Seconds:', _selectedTime3.toString()),
              const SizedBox(height: 12),
              const Text(
                'Features:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildFeatureItem('• Automatic AM/PM handling for 12-hour format'),
              _buildFeatureItem('• Optional seconds wheel'),
              _buildFeatureItem('• Customizable separators'),
              _buildFeatureItem('• Smooth scrolling performance'),
              _buildFeatureItem('• Consistent TimeOfDay interface'),
            ],
          ),
        ),
      );

  Widget _buildComparisonRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildFeatureItem(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          text,
          style: const TextStyle(fontSize: 14),
        ),
      );
}

/// Complex dependency example page
class ComplexDependencyExamplePage extends StatefulWidget {
  /// Creates the complex dependency example page
  const ComplexDependencyExamplePage({super.key});

  @override
  State<ComplexDependencyExamplePage> createState() => 
      _ComplexDependencyExamplePageState();
}

class _ComplexDependencyExamplePageState 
    extends State<ComplexDependencyExamplePage> {
  final GlobalKey _locationPickerKey = GlobalKey();
  final GlobalKey _performancePickerKey = GlobalKey();
  
  String _selectedLocation = 'United States - California - Los Angeles';
  String _selectedSpecs = 'Gaming - High - RTX 4080';
  
  // Sample data for location picker
  final Map<String, Map<String, List<String>>> _locationData = {
    'United States': {
      'California': ['Los Angeles', 'San Francisco', 'San Diego', 'Sacramento'],
      'New York': ['New York City', 'Buffalo', 'Rochester', 'Syracuse'],
      'Texas': ['Houston', 'Dallas', 'Austin', 'San Antonio'],
      'Florida': ['Miami', 'Orlando', 'Tampa', 'Jacksonville'],
    },
    'Canada': {
      'Ontario': ['Toronto', 'Ottawa', 'Hamilton', 'London'],
      'Quebec': ['Montreal', 'Quebec City', 'Laval', 'Gatineau'],
      'British Columbia': ['Vancouver', 'Victoria', 'Burnaby', 'Richmond'],
    },
    'United Kingdom': {
      'England': ['London', 'Manchester', 'Birmingham', 'Liverpool'],
      'Scotland': ['Edinburgh', 'Glasgow', 'Aberdeen', 'Dundee'],
      'Wales': ['Cardiff', 'Swansea', 'Newport', 'Wrexham'],
    },
  };
  
  // Sample data for performance picker
  final Map<String, Map<String, List<String>>> _performanceData = {
    'Gaming': {
      'Entry': ['GTX 1650', 'GTX 1660', 'RX 5500 XT'],
      'Mid': ['RTX 3060', 'RTX 3070', 'RX 6600 XT'],
      'High': ['RTX 4070', 'RTX 4080', 'RX 7800 XT'],
      'Ultra': ['RTX 4090', 'RTX 4080 Super', 'RX 7900 XTX'],
    },
    'Workstation': {
      'Basic': ['Quadro T400', 'Quadro T600', 'FirePro W2100'],
      'Professional': ['RTX A2000', 'RTX A4000', 'FirePro W7100'],
      'Enterprise': ['RTX A5000', 'RTX A6000', 'FirePro W9100'],
    },
    'Budget': {
      'Office': ['Integrated Graphics', 'GT 1030', 'RX 550'],
      'Light Gaming': ['GTX 1050', 'GTX 1050 Ti', 'RX 560'],
      'Multimedia': ['GTX 1060', 'RX 570', 'RX 580'],
    },
  };

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Complex Dependencies'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildLocationPicker(),
              const SizedBox(height: 24),
              _buildPerformancePicker(),
              const SizedBox(height: 24),
              _buildControlPanel(),
              const SizedBox(height: 24),
              _buildPerformanceDemo(),
            ],
          ),
        ),
      );

  Widget _buildLocationPicker() => Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Location Picker (Country → State → City)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'State wheel updates when country changes, '
                'city wheel updates when state changes',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Selected: $_selectedLocation',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: SelectiveWheelPickerBuilder(
                  key: _locationPickerKey,
                  wheels: _buildLocationWheels(),
                  selectedItemColor: Colors.green,
                  barColor: Colors.green.withValues(alpha: 0.1),
                  onChanged: _handleLocationChange,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildPerformancePicker() => Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PC Specs Picker (Category → Tier → GPU)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tier wheel updates when category changes, '
                'GPU wheel updates when tier changes',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Selected: $_selectedSpecs',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: SelectiveWheelPickerBuilder(
                  key: _performancePickerKey,
                  wheels: _buildPerformanceWheels(),
                  selectedItemColor: Colors.purple,
                  barColor: Colors.purple.withValues(alpha: 0.1),
                  onChanged: _handlePerformanceChange,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildControlPanel() => Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'External Control Demo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'These buttons demonstrate external control of complex pickers',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _setToUSA,
                    child: const Text('Set to USA'),
                  ),
                  ElevatedButton(
                    onPressed: _setToCanada,
                    child: const Text('Set to Canada'),
                  ),
                  ElevatedButton(
                    onPressed: _setToGaming,
                    child: const Text('Gaming Setup'),
                  ),
                  ElevatedButton(
                    onPressed: _setToBudget,
                    child: const Text('Budget Build'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildPerformanceDemo() => Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Performance Benefits',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildFeatureItem('• Only dependent wheels recreate'),
              _buildFeatureItem('• Independent wheels maintain smooth scrolling'),
              _buildFeatureItem('• Intelligent dependency resolution'),
              _buildFeatureItem('• Automatic state validation'),
              _buildFeatureItem('• Memory-efficient controller reuse'),
              const SizedBox(height: 12),
              const Text(
                'Try changing the first wheel in each picker to see how '
                'only the dependent wheels update!',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildFeatureItem(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          text,
          style: const TextStyle(fontSize: 14),
        ),
      );

  List<WheelConfig> _buildLocationWheels() {
    final countries = _locationData.keys.toList();
    final currentCountry = countries[0];
    final states = _locationData[currentCountry]!.keys.toList();
    final currentState = states[0];
    final cities = _locationData[currentCountry]![currentState]!;

    return [
      WheelConfig(
        itemCount: countries.length,
        initialIndex: 0,
        formatter: (i) => countries[i],
        width: 120,
        wheelId: 'country_wheel',
      ),
      WheelConfig(
        itemCount: states.length,
        initialIndex: 0,
        formatter: (i) => states[i],
        width: 100,
        wheelId: 'state_wheel',
        dependency: WheelDependency(
          dependsOn: [0],
          calculateItemCount: (deps) {
            final countryIndex = deps[0];
            final country = countries[countryIndex];
            return _locationData[country]!.keys.length;
          },
          calculateInitialIndex: (deps, current) => 0,
          buildFormatter: (deps) {
            final countryIndex = deps[0];
            final country = countries[countryIndex];
            final stateList = _locationData[country]!.keys.toList();
            return (i) => stateList[i];
          },
        ),
      ),
      WheelConfig(
        itemCount: cities.length,
        initialIndex: 0,
        formatter: (i) => cities[i],
        width: 120,
        wheelId: 'city_wheel',
        dependency: WheelDependency(
          dependsOn: [0, 1],
          calculateItemCount: (deps) {
            final countryIndex = deps[0];
            final stateIndex = deps[1];
            final country = countries[countryIndex];
            final state = _locationData[country]!.keys.toList()[stateIndex];
            return _locationData[country]![state]!.length;
          },
          calculateInitialIndex: (deps, current) => 0,
          buildFormatter: (deps) {
            final countryIndex = deps[0];
            final stateIndex = deps[1];
            final country = countries[countryIndex];
            final state = _locationData[country]!.keys.toList()[stateIndex];
            final cityList = _locationData[country]![state]!;
            return (i) => cityList[i];
          },
        ),
      ),
    ];
  }

  List<WheelConfig> _buildPerformanceWheels() {
    final categories = _performanceData.keys.toList();
    final currentCategory = categories[0];
    final tiers = _performanceData[currentCategory]!.keys.toList();
    final currentTier = tiers[0];
    final gpus = _performanceData[currentCategory]![currentTier]!;

    return [
      WheelConfig(
        itemCount: categories.length,
        initialIndex: 0,
        formatter: (i) => categories[i],
        width: 100,
        wheelId: 'category_wheel',
      ),
      WheelConfig(
        itemCount: tiers.length,
        initialIndex: 0,
        formatter: (i) => tiers[i],
        width: 80,
        wheelId: 'tier_wheel',
        dependency: WheelDependency(
          dependsOn: [0],
          calculateItemCount: (deps) {
            final categoryIndex = deps[0];
            final category = categories[categoryIndex];
            return _performanceData[category]!.keys.length;
          },
          calculateInitialIndex: (deps, current) => 0,
          buildFormatter: (deps) {
            final categoryIndex = deps[0];
            final category = categories[categoryIndex];
            final tierList = _performanceData[category]!.keys.toList();
            return (i) => tierList[i];
          },
        ),
      ),
      WheelConfig(
        itemCount: gpus.length,
        initialIndex: 0,
        formatter: (i) => gpus[i],
        width: 120,
        wheelId: 'gpu_wheel',
        dependency: WheelDependency(
          dependsOn: [0, 1],
          calculateItemCount: (deps) {
            final categoryIndex = deps[0];
            final tierIndex = deps[1];
            final category = categories[categoryIndex];
            final tier = _performanceData[category]!.keys.toList()[tierIndex];
            return _performanceData[category]![tier]!.length;
          },
          calculateInitialIndex: (deps, current) => 0,
          buildFormatter: (deps) {
            final categoryIndex = deps[0];
            final tierIndex = deps[1];
            final category = categories[categoryIndex];
            final tier = _performanceData[category]!.keys.toList()[tierIndex];
            final gpuList = _performanceData[category]![tier]!;
            return (i) => gpuList[i];
          },
        ),
      ),
    ];
  }

  void _handleLocationChange(List<int> indices) {
    final countries = _locationData.keys.toList();
    final country = countries[indices[0]];
    final states = _locationData[country]!.keys.toList();
    final state = states[indices[1]];
    final cities = _locationData[country]![state]!;
    final city = cities[indices[2]];

    setState(() {
      _selectedLocation = '$country - $state - $city';
    });
  }

  void _handlePerformanceChange(List<int> indices) {
    final categories = _performanceData.keys.toList();
    final category = categories[indices[0]];
    final tiers = _performanceData[category]!.keys.toList();
    final tier = tiers[indices[1]];
    final gpus = _performanceData[category]![tier]!;
    final gpu = gpus[indices[2]];

    setState(() {
      _selectedSpecs = '$category - $tier - $gpu';
    });
  }

  void _setToUSA() {
    SelectiveWheelPickerBuilder.updateMultipleWheelPositionsByKey(
      _locationPickerKey,
      {0: 0, 1: 0, 2: 0}, // USA - California - Los Angeles
      withAnimation: true,
    );
  }

  void _setToCanada() {
    SelectiveWheelPickerBuilder.updateMultipleWheelPositionsByKey(
      _locationPickerKey,
      {0: 1, 1: 0, 2: 0}, // Canada - Ontario - Toronto
      withAnimation: true,
    );
  }

  void _setToGaming() {
    SelectiveWheelPickerBuilder.updateMultipleWheelPositionsByKey(
      _performancePickerKey,
      {0: 0, 1: 2, 2: 1}, // Gaming - High - RTX 4080
      withAnimation: true,
    );
  }

  void _setToBudget() {
    SelectiveWheelPickerBuilder.updateMultipleWheelPositionsByKey(
      _performancePickerKey,
      {0: 2, 1: 1, 2: 0}, // Budget - Light Gaming - GTX 1050
      withAnimation: true,
    );
  }
}
