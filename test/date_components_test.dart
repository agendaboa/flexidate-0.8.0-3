import 'dart:ui';

import 'package:flexidate/flexi_date_parser.dart';
import 'package:flexidate/flexidate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/locale.dart';

void main() {
  group("Date Components Test", () {
    test("Standard iso date", () {
      final parsed = FlexiDate.parse("2012-10-03");
      expect(parsed.year, 2012);
      expect(parsed.month, 10);
      expect(parsed.day, 3);
    });

    test("Month and year (4 digits)", () {
      final parsed = FlexiDate.parse("12-2000");
      expect(parsed.year, 2000);
      expect(parsed.month, 12);
      expect(parsed.day, isNull);
    });

    test("Month and day", () {
      final parsed = FlexiDate.parse("12-28");
      expect(parsed.year, null);
      expect(parsed.month, 12);
      expect(parsed.day, 28);
    });

    test("Month and year (short month digits)", () {
      final parsed = FlexiDate.parse("Jan 12");
      expect(parsed.year, null);
      expect(parsed.month, 1);
      expect(parsed.day, 12);
    });

    test("January 12", () {
      final parsed = FlexiDate.parse("January 12");
      expect(parsed.year, isNull);
      expect(parsed.month, 1);
      expect(parsed.day, 12);
    });

    test("1/12", () {
      final parsed = FlexiDate.parse("1/12");
      expect(parsed.year, isNull);
      expect(parsed.month, 1);
      expect(parsed.day, 12);
    });

    test("12/2012", () {
      final parsed = FlexiDate.parse("12/2012");
      expect(parsed.year, 2012);
      expect(parsed.month, 12);
      expect(parsed.day, isNull);
    });

    test("25-12", () {
      final parsed = FlexiDate.parse("25-12");
      expect(parsed.year, isNull);
      expect(parsed.month, 12);
      expect(parsed.day, 25);
    });

    test("January 12, 1977", () {
      final parsed = FlexiDate.parse("January 12, 1977");
      expect(parsed.year, 1977);
      expect(parsed.month, 1);
      expect(parsed.day, 12);
    });

    test("breakfast sausage", () {
      var parsed = FlexiDate.parse("breakfast sausage");
      expect(parsed.isValid, isFalse);
      expect(parsed.source, equals("breakfast sausage"));
    });

    test("31-5521-43", () {
      var parsed = FlexiDate.parse("31-5521-43");
      expect(parsed.isValid, isFalse);
      expect(parsed.source, equals("31-5521-43"));
      expect(parsed.error, contains("Invalid tokens found within date: [43]"));
    });

    test("12 июль 1983", () async {
      await initializeDateFormatting("ru");
      DefaultFlexiDateParser.locale = Locale.parse("ru");
      final parsed = FlexiDate.parse("12 июль 1983");
      expect(parsed.isValid, isTrue);

      expect(parsed.year, equals(1983));
      expect(parsed.month, equals(7));
      expect(parsed.day, equals(12));
    });

    test("6 июля 1983", () async {
      await initializeDateFormatting("ru");
      DefaultFlexiDateParser.locale = Locale.parse("ru");
      final parsed = FlexiDate.parse("6 июля 1983");
      expect(parsed.isValid, isFalse);
      expect(
          parsed.error,
          equals(
              "Error FormatException: Trying to read LLLL from июля at position 0"));
      expect(parsed.source, equals("6 июля 1983"));
    });

    test("equality, mmyy", () {
      final a = FlexiDateData(year: 2000, month: 12);
      final b = FlexiDateData(year: 2000, month: 12);
      expect(a, b);
    });

    test("not equal, mmyy", () {
      final a = FlexiDateData(year: 2000, month: 13);
      final b = FlexiDateData(year: 2000, month: 12);
      expect(a, isNot(b));
    });

    test("not equal, yyyymmdd", () {
      final a = FlexiDateData(year: 2000, month: 13, day: 28);
      final b = FlexiDateData(year: 2000, month: 12, day: 28);
      expect(a, isNot(b));
    });

    test("is equal, yyyymmdd", () {
      final a = FlexiDateData(year: 2000, month: 12, day: 28);
      final b = FlexiDateData(year: 2000, month: 12, day: 28);
      expect(a, b);
    });

    test("set hash", () {
      final a = FlexiDateData(year: 2000, month: 12, day: 28);
      final b = FlexiDateData(year: 2000, month: 12, day: 28);
      final dates = {a, b};
      expect(dates.length, 1);
    });
  });
}
