# TableCalendar

Highly customizable, feature-packed calendar widget for Flutter.

## Features

- Extensive, yet easy to use API
- Preconfigured UI with customizable styling
- Custom selective builders for unlimited UI design
- Locale support
- Range selection support
- Multiple selection support
- Dynamic events and holidays
- Vertical autosizing - fit the content, or fill the viewport
- Multiple calendar formats (month, two weeks, week)
- Horizontal swipe boundaries (first day, last day)

## Installation

Add the following line to pubspec.yaml:

```yaml
dependencies:
  table_calendar: ^3.2.0
```

## Basic Setup

TableCalendar requires you to provide `firstDay`, `lastDay` and `focusedDay`:

- `firstDay` is the first available day for the calendar. Users will not be able to access days before it.
- `lastDay` is the last available day for the calendar. Users will not be able to access days after it.
- `focusedDay` is the currently targeted day. Use this property to determine which month should be currently visible.

```dart
TableCalendar(
  firstDay: DateTime.utc(2010, 10, 16),
  lastDay: DateTime.utc(2030, 3, 14),
  focusedDay: DateTime.now(),
);
```

## Adding Interactivity

Adding the following code to the calendar widget will allow it to respond to user's taps, marking the tapped day as selected:

```dart
selectedDayPredicate: (day) {
  return isSameDay(_selectedDay, day);
},
onDaySelected: (selectedDay, focusedDay) {
  setState(() {
    _selectedDay = selectedDay;
    _focusedDay = focusedDay; // update `_focusedDay` here as well
  });
},
```

To dynamically update visible calendar format:

```dart
calendarFormat: _calendarFormat,
onFormatChanged: (format) {
  setState(() {
    _calendarFormat = format;
  });
},
```

## Updating focusedDay

To prevent the calendar from "resetting" when it rebuilds, store and update `focusedDay`:

```dart
onPageChanged: (focusedDay) {
  _focusedDay = focusedDay;
},
```

## Events

You can supply custom events to TableCalendar widget using the `eventLoader` property:

```dart
eventLoader: (day) {
  return _getEventsForDay(day);
},
```

Example implementation with a Map:

```dart
List<Event> _getEventsForDay(DateTime day) {
  return events[day] ?? [];
}
```

For DateTime comparison, consider using a LinkedHashMap:

```dart
final events = LinkedHashMap(
  equals: isSameDay,
  hashCode: getHashCode,
)..addAll(eventSource);
```

### Cyclic Events

Add events that repeat in a pattern:

```dart
eventLoader: (day) {
  if (day.weekday == DateTime.monday) {
    return [Event('Cyclic event')];
  }
  return [];
},
```

### Events Selected on Tap

```dart
void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
  if (!isSameDay(_selectedDay, selectedDay)) {
    setState(() {
      _focusedDay = focusedDay;
      _selectedDay = selectedDay;
      _selectedEvents = _getEventsForDay(selectedDay);
    });
  }
}
```

## Custom UI with CalendarBuilders

Customize the UI with your own widgets using `CalendarBuilders`:

```dart
calendarBuilders: CalendarBuilders(
  dowBuilder: (context, day) {
    if (day.weekday == DateTime.sunday) {
      final text = DateFormat.E().format(day);
      return Center(
        child: Text(
          text,
          style: TextStyle(color: Colors.red),
        ),
      );
    }
  },
),
```

### CalendarBuilders Class Reference

The `CalendarBuilders<T>` class contains all custom builders for TableCalendar.

#### Constructor

```dart
CalendarBuilders({
  FocusedDayBuilder? prioritizedBuilder,
  FocusedDayBuilder? todayBuilder,
  FocusedDayBuilder? selectedBuilder,
  FocusedDayBuilder? rangeStartBuilder,
  FocusedDayBuilder? rangeEndBuilder,
  FocusedDayBuilder? withinRangeBuilder,
  FocusedDayBuilder? outsideBuilder,
  FocusedDayBuilder? disabledBuilder,
  FocusedDayBuilder? holidayBuilder,
  FocusedDayBuilder? defaultBuilder,
  HighlightBuilder? rangeHighlightBuilder,
  SingleMarkerBuilder<T>? singleMarkerBuilder,
  MarkerBuilder<T>? markerBuilder,
  DayBuilder? dowBuilder,
  DayBuilder? headerTitleBuilder,
  Widget? Function(BuildContext context, int weekNumber)? weekNumberBuilder,
})
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `prioritizedBuilder` | `FocusedDayBuilder?` | Custom builder for day cells, with a priority over any other builder. |
| `todayBuilder` | `FocusedDayBuilder?` | Custom builder for a day cell that matches the current day. |
| `selectedBuilder` | `FocusedDayBuilder?` | Custom builder for day cells that are currently marked as selected by selectedDayPredicate. |
| `rangeStartBuilder` | `FocusedDayBuilder?` | Custom builder for a day cell that is the start of current range selection. |
| `rangeEndBuilder` | `FocusedDayBuilder?` | Custom builder for a day cell that is the end of current range selection. |
| `withinRangeBuilder` | `FocusedDayBuilder?` | Custom builder for day cells that fall within the currently selected range. |
| `outsideBuilder` | `FocusedDayBuilder?` | Custom builder for day cells, of which the day.month is different than focusedDay.month. |
| `disabledBuilder` | `FocusedDayBuilder?` | Custom builder for day cells that have been disabled. |
| `holidayBuilder` | `FocusedDayBuilder?` | Custom builder for day cells that are marked as holidays by holidayPredicate. |
| `defaultBuilder` | `FocusedDayBuilder?` | Custom builder for day cells that do not match any other builder. |
| `rangeHighlightBuilder` | `HighlightBuilder?` | Custom builder for background highlight of range selection. |
| `singleMarkerBuilder` | `SingleMarkerBuilder<T>?` | Custom builder for a single event marker. |
| `markerBuilder` | `MarkerBuilder<T>?` | Custom builder for event markers. Overrides singleMarkerBuilder and default event markers. |
| `dowBuilder` | `DayBuilder?` | Custom builder for days of the week labels (Mon, Tue, Wed, etc.). |
| `headerTitleBuilder` | `DayBuilder?` | Use to customize header's title using different widget. |
| `weekNumberBuilder` | `Widget? Function(BuildContext context, int weekNumber)?` | Custom builder for number of the week labels. |

## Locale Support

### Initialization

Before using a locale, initialize date formatting:

```dart
import 'package:intl/date_symbol_data_local.dart';

void main() {
  initializeDateFormatting().then((_) => runApp(MyApp()));
}
```

### Specifying a Language

```dart
TableCalendar(
  locale: 'pl_PL',
)
```

To change the language of FormatButton's text, use `availableCalendarFormats` property. You can also hide the button by setting `formatButtonVisible` to false.

