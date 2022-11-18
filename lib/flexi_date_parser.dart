// import 'package:dartx/dartx.dart';
import 'package:dartxx/dartxx.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:intl/locale.dart';
import 'package:logging/logging.dart';

import 'flexible_date.dart';

final _log = Logger("flexDateParser");

abstract class FlexiDateParser {
  static FlexiDateParser instance = DefaultFlexiDateParser();

  FlexiDate parse(String input);

  static FlexiDate? tryParse(String input) {
    try {
      return instance.parse(input);
    } catch (e) {
      _log.finer("Date parse error: $e");
      return null;
    }
  }

  static FlexiDate? from(dynamic input) {
    if (input == null) return null;
    if (input is FlexiDate) return input;
    if (input is DateTime) return FlexiDate.ofDateTime(input);
    if (input is Map) return FlexiDateData.fromMap(input);
    var inputString = "$input";
    if (inputString.isEmpty) {
      return null;
    } else {
      return instance.parse(inputString);
    }
  }
}

class DefaultFlexiDateParser implements FlexiDateParser {
  static Locale locale = Locale.parse("en-US");

  @override
  FlexiDate parse(String toParse) {
    if (toParse.isEmpty) {
      throw Exception("Empty date cannot be parsed");
    }
    final parseAttempt = DateTime.tryParse(toParse.trim());
    if (parseAttempt != null) {
      return FlexiDate.ofDateTime(parseAttempt);
    }

    final input = "$toParse";
    final tokenized = tokenizeString(input, splitAll: true);

    try {
      final parts = [
        for (var token in tokenized)
          if (token.isNumeric)
            DatePart(token.toInt())
          else
            DatePart(
                DateFormat.MMMM(locale.toLanguageTag()).parseLoose(token).month,
                Period.month),
      ];

      final sortedParts = DateParts.of(parts);
      final year = sortedParts.year;
      final month = sortedParts.month;
      final day = sortedParts.day;

      if (sortedParts.invalid.isNotEmpty) {
        throw Exception(
            "Invalid tokens found within date: ${sortedParts.invalid}");
      }
      if (year != null && month != null && day != null) {
        return FlexiDate.of(
          day: day,
          month: month,
          year: year,
        );
      } else if (year != null && month != null) {
        return FlexiDate.of(
            day: sortedParts.others.firstOr(),
            month: sortedParts.month,
            year: sortedParts.year);
      } else if (year != null) {
        /// This case has ambigious month/day, like 1-2
        switch (sortedParts.others.length) {
          case 2:
            return FlexiDate.of(
                year: sortedParts.year,
                month: sortedParts.others[0],
                day: sortedParts.others[1],
                isAmbiguous: true);
          case 1:
            return FlexiDate.of(
              year: sortedParts.year,
              month: sortedParts.others.firstOr(),
            );
          case 0:
            return FlexiDate.of(year: sortedParts.year);
          default:
            throw Exception(
                "Unable to extract date parameters from '$toParse'");
        }
      } else if (month != null && day != null) {
        return FlexiDate.of(
            month: month, day: day, year: sortedParts.others.firstOr());
      } else if (month != null) {
        /// In this case, we know there is no unambiguous year or day
        switch (sortedParts.others.length) {
          case 2:
            return FlexiDate.of(
              month: month,
              day: sortedParts.others.firstOr(),
              year: sortedParts.others.lastOr(),
              isAmbiguous: true,
            );
          case 1:

            /// I don't like this case, it seems like we shouldn't guess.
            return FlexiDate.of(
                month: month,
                day: sortedParts.others.firstOr(),
                isAmbiguous: true);
          case 0:

            /// Month only.  Weird, but okay
            return FlexiDate.of(month: month);
          default:
            throw Exception(
                "Found a month ($month) but had too many other parts to create a date");
        }
      } else if (day != null) {
        switch (sortedParts.others.length) {
          case 2:
            return FlexiDate.of(
                month: sortedParts.others.lastOr(),
                day: day,
                year: sortedParts.others.firstOr(),
                isAmbiguous: true);
          case 1:
            return FlexiDate.of(month: sortedParts.others.firstOr(), day: day);
          case 0:

            /// Day only.  Weird, but okay
            return FlexiDate.of(day: day);
          default:
            throw Exception(
                "Found a month ($month) but had too many other parts to create a date");
        }
      } else {
        switch (sortedParts.others.length) {
          case 2:
            return sortedParts.others.first > 12
                ? FlexiDate.of(
                    month: sortedParts.others.lastOr(),
                    day: sortedParts.others.firstOr(),
                    isAmbiguous: true)
                : FlexiDate.of(
                    month: sortedParts.others.firstOr(),
                    day: sortedParts.others.lastOr(),
                    isAmbiguous: true);

          default:
            throw Exception(
                "Unable to extract date parameters from '$toParse'");
        }
      }
    } catch (e) {
      _log.finer("Error parsing date: $e");
      return FlexiDate.unparsed(input, "Error $e");
    }
  }
}

class DateParts {
  final int? year;
  final int? month;
  final int? day;
  final List<int> others;
  final List<int> invalid;

  DateParts(this.year, this.month, this.day, this.others, this.invalid);

  factory DateParts.of(List<DatePart> parts) {
    final copy = {...parts.asMap()};
    int? monthIndex, yearIndex, dayIndex;
    int? month, year, day;
    parts.forEachIndexed((item, index) {
      if (item.period == Period.month) {
        monthIndex = index;
        month = item.value;
      } else if (item.value > 1000) {
        yearIndex = index;
        year = item.value;
      }
    });
    copy.remove(monthIndex);
    copy.remove(yearIndex);
    yearIndex = monthIndex = null;

    /// Second pass
    copy.values.forEachIndexed((item, index) {
      if (year != null && item.value > 12 && item.value <= 31) {
        /// We already have a year, so any value larger than 12 must be the day
        day = item.value;
        dayIndex = index;
      } else if (year == null && item.value > 31) {
        /// Any value larger than 31 must be a year
        year = item.value;
        yearIndex = index;
      }
    });
    copy.remove(dayIndex);
    copy.remove(yearIndex);

    dayIndex = yearIndex = monthIndex = null;

    List<int> toRemove = [];
    List<int> invalidValues = [];

    /// Last pass
    copy.values.forEachIndexed((item, index) {
      if (year != null && day != null && month == null && item.value < 12) {
        month = item.value;
        monthIndex = index;
      } else if (month != null && day != null && year == null) {
        year = item.value;
        yearIndex = index;
      } else if (month != null && year != null && item.value <= 31) {
        day = item.value;
        dayIndex = index;
      } else if (year != null && item.value > 31) {
        toRemove.add(index);
        invalidValues.add(item.value);
      }
    });
    copy.remove(dayIndex);
    copy.remove(yearIndex);
    copy.remove(monthIndex);
    toRemove.forEach(copy.remove);

    return DateParts(
      year,
      month,
      day,
      copy.values.map((v) => v.value).toList(),
      invalidValues,
    );
  }
}

enum Period { day, month, year }

class DatePart extends Equatable {
  final Period? period;
  final int value;

  const DatePart(
    this.value, [
    this.period,
  ]);

  DatePart withPeriod(Period period) {
    return DatePart(value, period);
  }

  @override
  List<Object?> get props {
    return [period, value];
  }
}
