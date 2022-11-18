import 'package:dartxx/dartxx.dart';
import 'package:flexidate/flexi_date_parser.dart';
import 'package:logging/logging.dart';
import 'package:timezone/timezone.dart';

final _log = Logger('flexibleDate');

abstract class FlexiDate {
  factory FlexiDate.ofDateTime(DateTime dt) {
    return FlexiDateData.fromDateTime(dt);
  }

  factory FlexiDate.unparsed(String original, [String? message]) {
    return InvalidFlexiDate(original, message);
  }

  factory FlexiDate.now() {
    return FlexiDateData.now();
  }

  factory FlexiDate.of(
      {int? day, int? month = 1, int? year, bool isAmbiguous = false}) {
    return FlexiDateData(
        day: day, month: month, year: year, isAmbiguous: isAmbiguous);
  }

  factory FlexiDate.fromJson(json) => FlexiDateParser.from(json)!;

  factory FlexiDate.parse(String input) =>
      FlexiDateParser.instance.parse(input);

  static FlexiDate? tryFrom(input) {
    try {
      if (input == null) return null;
      return from(input);
    } catch (e) {
      _log.finer("Date parse error: $e");
      return null;
    }
  }

  static FlexiDate? from(dynamic input) => FlexiDateParser.from(input);

  const FlexiDate();

  dynamic toJson();

  Object? get source;

  int? get day => null;
  set day(int? day) {}

  int? get month => null;
  set month(int? month) {}

  int? get year => null;
  set year(int? year) {}

  bool get isValid => false;

  bool get isAmbiguous => false;
}

/// Represents a date that's couldn't be parsed.
class InvalidFlexiDate extends FlexiDate {
  @override
  final String source;

  final String? message;

  const InvalidFlexiDate(this.source, [this.message]) : super();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvalidFlexiDate && source == other.source;

  @override
  int get hashCode => source.hashCode;

  @override
  dynamic toJson() {
    return source;
  }

  @override
  String toString() {
    return source;
  }
}

extension FlexiDateExt on FlexiDate {
  FlexiDate copy() {
    return FlexiDateData(
      day: day,
      month: month,
      year: year,
      source: source,
    );
  }

  int millisecondsSinceEpoch([Location? location]) {
    return toDateTime(location).millisecondsSinceEpoch;
  }

  DateTime toDateTime([Location? location]) {
    if (location != null) {
      return TZDateTime(location, year ?? 1971, month ?? 1, day ?? 1);
    } else {
      return DateTime(year ?? 1971, month ?? 1, day ?? 1);
    }
  }

  FlexiDate withoutDay() => FlexiDateData(day: null, month: month, year: year);

  FlexiDate withoutYear() => FlexiDateData(day: day, month: month, year: null);

  bool get isFullDate => year != null;

  /// Whether this date is in the future
  bool get isFuture => isFullDate && toDateTime().isFuture;

  bool get hasMonth => month != null;

  bool get hasYear => year != null;

  bool get hasDay => day != null;

  String? get error =>
      this is InvalidFlexiDate ? (this as InvalidFlexiDate).message : null;
}

/// A flexible container for date components that provides a robust parsing/building mechanism.  If the input type is known
/// to be a [String], [Map] or [DateTime], then use the corresponding constructors.
///
/// [FlexiDateParser.tryFrom] will / attempt to construct a [FlexibleDate] instance, and will return `null` if none could be constructed.
/// [FlexiDateParser.from] will / attempt to construct a [FlexibleDate] instance, and will raise an exception if unable to create a [FlexibleDate] instance
///
class FlexiDateData implements FlexiDate {
  @override
  int? day;

  @override
  int? month;

  @override
  int? year;

  @override
  Object? source;

  @override
  bool isAmbiguous;

  FlexiDateData(
      {this.day,
      this.month = 1,
      this.year,
      this.source,
      this.isAmbiguous = false});

  FlexiDateData.fromDateTime(DateTime dateTime)
      : day = dateTime.day,
        month = dateTime.month,
        year = dateTime.year,
        // ignore: prefer_initializing_formals
        source = dateTime,
        isAmbiguous = false;

  factory FlexiDateData.now() => FlexiDateData.fromDateTime(DateTime.now());

  /// from a map, assuming keys [kday], [kmonth], [kyear]
  FlexiDateData.fromMap(Map toParse)
      : day = _tryParseInt(toParse[kday]),
        month = _tryParseInt(toParse[kmonth]),
        year = _tryParseInt(toParse[kyear]),
        // ignore: prefer_initializing_formals
        source = toParse,
        isAmbiguous = false;

  @override
  dynamic toJson() {
    return "$this";
  }

  @override
  bool get isValid => true;

  Map<String, int?> toMap() {
    return {
      if (hasYear) kyear: year,
      if (hasMonth) kmonth: month,
      if (hasDay) kday: day,
    };
  }

  @override
  String toString() => [year, month, day]
      .notNull()
      .map((part) => part < 10 ? "0$part" : "$part")
      .join("-");

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlexiDate &&
          day == other.day &&
          month == other.month &&
          year == other.year;

  @override
  int get hashCode => day.hashCode ^ month.hashCode ^ year.hashCode;
}

int? _tryParseInt(dyn) {
  if (dyn == null) return null;
  return int.tryParse("$dyn");
}

const kyear = 'year';
const kmonth = 'month';
const kday = 'day';

DateTime withoutTime(DateTime time) =>
    DateTime(time.year, time.month, time.day, 0, 0, 0, 0, 0);

bool hasTime(DateTime time) =>
    time.second != 0 ||
    time.minute != 0 ||
    time.hour != 0 ||
    time.millisecond != 0;

bool isFuture(DateTime? time) => time?.isAfter(DateTime.now()) == true;

bool isPast(DateTime? time) => time?.isBefore(DateTime.now()) == true;

extension DateComponentsComparisons on FlexiDate {
  bool isSameMonth(DateTime date) {
    return this.month == date.month && this.year == date.year;
  }
}
