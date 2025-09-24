# Troubleshooting Guide

This guide helps you resolve common issues when using Locuaz Wheel Pickers.

## Table of Contents

- [Common Issues](#common-issues)
- [Performance Problems](#performance-problems)
- [Configuration Errors](#configuration-errors)
- [Dependency Issues](#dependency-issues)
- [UI and Styling Problems](#ui-and-styling-problems)
- [Frequently Asked Questions](#frequently-asked-questions)
- [Getting Help](#getting-help)

## Common Issues

### Wheels Not Updating

**Symptom:** Dependent wheels don't update when parent wheels change.

**Possible Causes:**
1. Missing or incorrect dependency configuration
2. Calculation function returning invalid values
3. Circular dependencies

**Solutions:**

```dart
// ❌ Incorrect - missing dependency
WheelConfig(
  itemCount: cities.length, // Static, won't update
  formatter: (i) => cities[i],
)

// ✅ Correct - with dependency
WheelConfig(
  itemCount: 1, // Will be calculated
  formatter: (i) => 'City $i',
  dependency: WheelDependency(
    dependsOn: [0], // Depends on country wheel
    calculateItemCount: (deps) => countries[deps[0]].cities.length,
    buildFormatter: (deps) => (i) => countries[deps[0]].cities[i],
  ),
)
```

### Index Out of Bounds Errors

**Symptom:** `RangeError: Index out of range` exceptions.

**Possible Causes:**
1. Dependency calculation returning invalid item count
2. Initial index exceeding item count
3. Formatter accessing invalid indices

**Solutions:**

```dart
// ❌ Incorrect - no bounds checking
WheelDependency(
  dependsOn: [0],
  calculateItemCount: (deps) => data[deps[0]].length, // May be 0
  buildFormatter: (deps) => (i) => data[deps[0]][i], // May crash
)

// ✅ Correct - with bounds checking
WheelDependency(
  dependsOn: [0],
  calculateItemCount: (deps) {
    final items = data[deps[0]];
    return items.isEmpty ? 1 : items.length; // Ensure at least 1
  },
  buildFormatter: (deps) => (i) {
    final items = data[deps[0]];
    return items.isEmpty ? 'No items' : items[i];
  },
)
```

### Scroll Controllers Not Disposing

**Symptom:** Memory leaks or warnings about undisposed controllers.

**Solution:** This is handled automatically by the package. If you're using external `WheelManager`, ensure proper disposal:

```dart
class _MyWidgetState extends State<MyWidget> {
  late WheelManager wheelManager;

  @override
  void initState() {
    super.initState();
    wheelManager = WheelManager();
  }

  @override
  void dispose() {
    wheelManager.dispose(); // Important!
    super.dispose();
  }
}
```

## Performance Problems

### Slow Scrolling

**Symptom:** Jerky or slow wheel scrolling.

**Possible Causes:**
1. Using `SelectiveWheelPickerBuilder` for independent wheels
2. Heavy computation in formatter functions
3. Too many wheels with complex dependencies

**Solutions:**

```dart
// ❌ Incorrect - heavy computation in formatter
WheelConfig(
  itemCount: 1000,
  formatter: (i) => expensiveCalculation(i), // Computed every frame
)

// ✅ Correct - pre-computed values
final precomputedValues = List.generate(1000, (i) => expensiveCalculation(i));

WheelConfig(
  itemCount: 1000,
  formatter: (i) => precomputedValues[i], // Fast lookup
)
```

### Excessive Recreations

**Symptom:** Wheels recreating too frequently.

**Possible Causes:**
1. Unstable dependency calculations
2. Formatter functions changing on every build
3. Unnecessary state updates

**Solutions:**

```dart
// ❌ Incorrect - function created on every build
Widget build(BuildContext context) {
  return WheelConfig(
    itemCount: 10,
    formatter: (i) => 'Item $i', // New function every build
  );
}

// ✅ Correct - stable function reference
String _formatter(int index) => 'Item $index';

Widget build(BuildContext context) {
  return WheelConfig(
    itemCount: 10,
    formatter: _formatter, // Stable reference
  );
}
```

### Memory Usage

**Symptom:** High memory consumption.

**Solutions:**
1. Use `SimpleWheelPickerBuilder` when possible
2. Avoid storing large objects in state
3. Implement proper disposal patterns

## Configuration Errors

### Invalid Wheel Configuration

**Symptom:** `ArgumentError` or validation failures.

**Common Validation Errors:**

```dart
// ❌ Invalid configurations
WheelConfig(
  itemCount: 0,        // Must be > 0
  initialIndex: -1,    // Must be >= 0
  width: -10,          // Must be > 0
  formatter: null,     // Must not be null
)

// ✅ Valid configuration
WheelConfig(
  itemCount: 10,
  initialIndex: 0,
  width: 60,
  formatter: (i) => 'Item $i',
)
```

### Dependency Validation Errors

**Symptom:** Dependency validation failures.

**Common Issues:**

```dart
// ❌ Invalid dependencies
WheelDependency(
  dependsOn: [],              // Empty - invalid
  dependsOn: [-1, 2],         // Negative index - invalid
  dependsOn: [0, 0],          // Duplicate - invalid
  dependsOn: [5],             // Out of bounds - invalid (if only 3 wheels)
  calculateItemCount: null,   // Null - invalid
)

// ✅ Valid dependency
WheelDependency(
  dependsOn: [0, 1],          // Valid indices
  calculateItemCount: (deps) => deps[0] + deps[1] + 1,
)
```

## Dependency Issues

### Circular Dependencies

**Symptom:** `CircularDependencyException` or infinite loops.

**Example Problem:**
```dart
// Wheel 0 depends on Wheel 1
// Wheel 1 depends on Wheel 0
// This creates a cycle!
```

**Solution:** Redesign dependencies to be acyclic:

```dart
// ✅ Correct - hierarchical dependencies
SelectiveWheelPickerBuilder(
  configs: [
    WheelConfig(wheelId: 'level1'), // Independent
    WheelConfig(
      wheelId: 'level2',
      dependency: WheelDependency(dependsOn: [0]), // Depends on level1
    ),
    WheelConfig(
      wheelId: 'level3',
      dependency: WheelDependency(dependsOn: [1]), // Depends on level2
    ),
  ],
)
```

### Dependency Calculation Failures

**Symptom:** Wheels showing incorrect data or crashing.

**Common Issues:**
1. Null pointer exceptions in calculations
2. Division by zero
3. Array index out of bounds

**Solutions:**

```dart
// ❌ Unsafe calculation
WheelDependency(
  dependsOn: [0],
  calculateItemCount: (deps) => 100 / deps[0], // Division by zero if deps[0] == 0
)

// ✅ Safe calculation
WheelDependency(
  dependsOn: [0],
  calculateItemCount: (deps) {
    final divisor = deps[0];
    return divisor == 0 ? 1 : (100 / divisor).round();
  },
)
```

## UI and Styling Problems

### Separators Not Showing

**Symptom:** Separators between wheels not visible.

**Solutions:**

```dart
// ❌ Incorrect - separator not configured
WheelConfig(
  itemCount: 24,
  formatter: (i) => i.toString(),
  // Missing separator
)

// ✅ Correct - with separator
WheelConfig(
  itemCount: 24,
  formatter: (i) => i.toString(),
  trailingSeparator: WheelSeparators().colon(),
)
```

### Text Overflow

**Symptom:** Text getting cut off in wheels.

**Solutions:**

```dart
// ❌ Incorrect - fixed narrow width
WheelConfig(
  itemCount: 12,
  formatter: (i) => 'Very Long Month Name ${i + 1}',
  width: 50, // Too narrow
)

// ✅ Correct - appropriate width
WheelConfig(
  itemCount: 12,
  formatter: (i) => 'Very Long Month Name ${i + 1}',
  width: 150, // Sufficient width
)
```

### Theme Issues

**Symptom:** Wheels not respecting app theme.

**Solution:** Ensure proper theme context:

```dart
// Wrap in Theme if needed
Theme(
  data: Theme.of(context),
  child: WDatePicker(
    onChanged: (date) => handleDate(date),
  ),
)
```

## Frequently Asked Questions

### Q: Can I use this package with other state management solutions?

**A:** Yes! While the package uses GetX internally for optimization, it works with any state management solution. Just use the `onChanged` callbacks to update your state.

```dart
// Works with Provider
Consumer<MyModel>(
  builder: (context, model, child) {
    return WDatePicker(
      initialDate: model.selectedDate,
      onChanged: (date) => model.updateDate(date),
    );
  },
)

// Works with Bloc
BlocBuilder<DateBloc, DateState>(
  builder: (context, state) {
    return WDatePicker(
      initialDate: state.selectedDate,
      onChanged: (date) => context.read<DateBloc>().add(DateChanged(date)),
    );
  },
)
```

### Q: How do I customize the appearance?

**A:** Use the styling parameters available on each widget:

```dart
WListPicker(
  items: items,
  selectedItemColor: Colors.blue,
  unselectedItemColor: Colors.grey,
  backgroundColor: Colors.white,
  itemExtent: 50,
)
```

### Q: Can I add custom animations?

**A:** The package uses optimized default animations. Custom animations will be supported in future versions.

### Q: How do I handle validation?

**A:** Use the `onChanged` callbacks to implement validation:

```dart
WDatePicker(
  onChanged: (date) {
    if (date.isBefore(DateTime.now())) {
      // Show error
      showError('Date cannot be in the past');
      return;
    }
    // Valid date
    updateSelectedDate(date);
  },
)
```

### Q: Can I use this in a form?

**A:** Yes! Integrate with Flutter's form system:

```dart
FormField<DateTime>(
  initialValue: DateTime.now(),
  validator: (date) {
    if (date == null) return 'Date is required';
    if (date.isBefore(DateTime.now())) return 'Date cannot be in the past';
    return null;
  },
  builder: (FormFieldState<DateTime> state) {
    return Column(
      children: [
        WDatePicker(
          initialDate: state.value ?? DateTime.now(),
          onChanged: (date) => state.didChange(date),
        ),
        if (state.hasError)
          Text(state.errorText!, style: TextStyle(color: Colors.red)),
      ],
    );
  },
)
```

### Q: How do I implement custom business logic?

**A:** Use dependency calculations for complex logic:

```dart
WheelDependency(
  dependsOn: [0, 1], // month, year
  calculateItemCount: (deps) {
    final month = deps[0] + 1;
    final year = 2000 + deps[1];
    
    // Custom business logic
    if (isLeapYear(year) && month == 2) {
      return 29; // February in leap year
    } else if (month == 2) {
      return 28; // February in regular year
    } else if ([4, 6, 9, 11].contains(month)) {
      return 30; // April, June, September, November
    } else {
      return 31; // All other months
    }
  },
)
```

### Q: How do I debug performance issues?

**A:** Enable debug logging and use performance metrics:

```dart
// Enable debug logging
import 'package:flutter/foundation.dart';

// In debug mode, the package will log performance metrics
if (kDebugMode) {
  // Performance metrics will be logged to console
}
```

### Q: Can I contribute to the package?

**A:** Yes! See the [Contributing Guidelines](CONTRIBUTING.md) for details on how to contribute.

## Getting Help

If you can't find a solution here:

1. **Check the Documentation**: Review the [API Documentation](https://pub.dev/documentation/locuaz_wheel_pickers/latest/)

2. **Example App**: Look at the [example app](example/) for working implementations

3. **Search Issues**: Check [existing GitHub issues](https://github.com/warcayac/locuaz_wheel_pickers/issues)

4. **Create an Issue**: If you find a bug or need help, create a new issue with:
   - Minimal reproduction code
   - Expected vs actual behavior
   - Flutter/Dart version information
   - Device/platform information

5. **Discussions**: Use [GitHub Discussions](https://github.com/warcayac/locuaz_wheel_pickers/discussions) for questions and community help

### Issue Template

When creating an issue, please include:

```markdown
## Bug Report / Question

**Description:**
Brief description of the issue

**Code to Reproduce:**
```dart
// Minimal code that reproduces the issue
```

**Expected Behavior:**
What you expected to happen

**Actual Behavior:**
What actually happened

**Environment:**
- Flutter version: 
- Dart version: 
- Package version: 
- Platform: (iOS/Android/Web/Desktop)
- Device: 

**Additional Context:**
Any other relevant information
```

This helps us provide faster and more accurate assistance.