import 'flexible_date.dart';
import 'time_span.dart';

extension FlexiDateTimeExt on DateTime {
  DateTime plusTimeSpan(TimeSpan span) {
    final duration = span.toDuration(this);
    return this.add(duration);
  }

  bool isSameDay(final other) {
    if (other is DateTime) {
      return this.year == other.year &&
          this.month == other.month &&
          this.day == other.day;
    } else if (other is FlexiDate) {
      return (other.year == null || this.year == other.year) &&
          this.month == other.month &&
          this.day == other.day;
    }
    assert(false, 'Shouldnt get here');
    return false;
  }

  DateTime minusTimeSpan(TimeSpan span) {
    final duration = span.toDuration(this);
    return this.add(-duration);
  }
}
